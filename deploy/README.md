# Déploiement — dumlu.top

Infrastructure du portfolio, du blog et du site Brasserie T&S sur le VPS.

## Architecture

```
                        Internet
                           │  :80  :443
                           ▼
 ┌─────────────────────────────────────────────────────────────┐
 │ VPS — hôte Debian                                           │
 │                                                             │
 │   nginx  ── reverse proxy et terminaison TLS uniquement     │
 │             ne sert aucun fichier                           │
 │   Fail2Ban · IPset · SSH durci · certbot                    │
 │                                                             │
 │   lxcbr0   10.0.3.1/24                                      │
 │    ├── ct-portfolio  10.0.3.11   Apache + PHP               │
 │    │                             → dumlu.top                │
 │    ├── ct-blog       10.0.3.12   Apache + PHP + Dotclear    │
 │    │                             → blog.dumlu.top           │
 │    ├── ct-brasserie  10.0.3.13   Apache + PHP + WordPress   │
 │    │                             → brasserie.dumlu.top      │
 │    └── ct-db         10.0.3.10   MariaDB                    │
 └─────────────────────────────────────────────────────────────┘
```

**Pourquoi des conteneurs.** WordPress est la surface d'attaque la plus
exposée des trois services. Isolé dans son propre conteneur, sa compromission
ne donne accès ni au portfolio, ni au blog, ni à l'hôte.

**Pourquoi une base de données commune.** Une instance MariaDB unique plutôt
qu'une par conteneur, pour la mémoire. Chaque application a son compte SQL,
dont les droits sont limités à sa propre base : depuis le conteneur WordPress,
les identifiants volés ne donnent pas accès aux données du blog. Si le VPS a
de la mémoire à revendre, une instance par conteneur isole davantage.

## Prérequis

- Un VPS Debian, accès root.
- Les enregistrements DNS **créés avant l'étape 4**, faute de quoi Let's
  Encrypt refuse d'émettre les certificats :

  | Nom         | Type | Valeur              |
  | ----------- | ---- | ------------------- |
  | `@`         | A    | IP publique du VPS  |
  | `www`       | A    | IP publique du VPS  |
  | `blog`      | A    | IP publique du VPS  |
  | `brasserie` | A    | IP publique du VPS  |

## Ordre des opérations

Tous les scripts se lancent en root depuis le dépôt cloné sur le VPS.
Ils sont sans effet s'ils sont rejoués sur une étape déjà faite.

### 1 — LXC

```bash
cd deploy/host
./01-lxc-setup.sh
```

Installe LXC, crée le bridge `lxcbr0` et réserve les adresses fixes.

> **Point de vigilance.** `lxc-net` pose ses propres règles de NAT. Un script
> de pare-feu maison (IPset, iptables) rejoué ensuite les efface, et les
> conteneurs perdent Internet sans message d'erreur. Le script le détecte et
> affiche les règles à réintégrer.

### 2 — Conteneurs

```bash
./02-creer-conteneur.sh ct-db
./02-creer-conteneur.sh ct-portfolio
./02-creer-conteneur.sh ct-blog
```

### 3 — nginx

```bash
./03-nginx.sh
```

Demande confirmation avant d'arrêter Apache sur l'hôte : son rôle passe
dans les conteneurs, mais rien n'est coupé sans accord.

Le script adapte les vhosts au serveur en place : `http2 on;` n'existe qu'à
partir de nginx 1.25.1, et les directives `listen [::]` sont retirées si
l'hôte n'a pas d'IPv6.

### 4 — Certificats et mise en ligne de la vitrine

```bash
./04-tls.sh dumlu.top www.dumlu.top
```

Vérifie d'abord que le DNS pointe bien ici, puis obtient le certificat par
la méthode `webroot` — nginx continue de servir pendant la validation.
Le vhost n'est activé qu'après un `nginx -t` réussi ; en cas d'échec il est
retiré et le service reste intact.

### 5 — Apache et PHP dans le conteneur du portfolio

```bash
cd /chemin/vers/cv_erhan/deploy
. host/lib.sh && . vars.sh
executer_dans_ct ct-portfolio containers/web-base.sh dumlu.top /var/www/portfolio
./publier-portfolio.sh
```

`publier-portfolio.sh` montre les différences avant d'écrire et demande
confirmation, car il aligne la cible sur la source (`rsync --delete`).

À ce stade **https://dumlu.top est en ligne**.

### 6 — Base de données

```bash
executer_dans_ct ct-db containers/db-base.sh dotclear dotclear '10.0.3.%'
```

Affiche un mot de passe aléatoire **qui n'est conservé nulle part** : le noter
immédiatement, il est demandé par l'assistant Dotclear.

### 7 — Dotclear

```bash
executer_dans_ct ct-blog containers/web-base.sh blog.dumlu.top /var/www/dotclear
cd host && ./04-tls.sh blog.dumlu.top && cd ..
executer_dans_ct ct-blog containers/dotclear.sh "<URL de l archive>"
```

L'URL de l'archive est à relever sur <https://dotclear.org/download>. Elle
n'est pas codée en dur parce qu'elle change à chaque version : le script
contrôle ce qu'il a réellement téléchargé (taille, format, présence de
`index.php` et `admin/`) et s'arrête si l'URL a renvoyé autre chose.

Terminer ensuite dans le navigateur, à l'adresse que le script affiche —
typiquement `https://blog.dumlu.top/admin/install/index.php` — avec
hôte `10.0.3.10`, base `dotclear`, utilisateur `dotclear`.

#### Configuration obligatoire du blog

Le sujet impose l'indexation des billets par compétences :

1. Administration → **Présentation** → **Widgets**
2. Glisser **Nuage de mots-clés** dans le **volet de navigation**
3. Enregistrer

Chaque billet doit ensuite porter les mots-clés du référentiel (`B1.1`,
`B1.2`, …), ce qui permet de retrouver en un clic tous les travaux d'un bloc.

### 8 — Fail2Ban

```bash
sudo install -m 644 deploy/fail2ban/filter.d/*.conf /etc/fail2ban/filter.d/
sudo install -m 644 deploy/fail2ban/jail.d/conteneurs-web.local /etc/fail2ban/jail.d/
sudo fail2ban-client reload
```

Fail2Ban tourne sur l'hôte et lit les journaux des conteneurs à travers leur
système de fichiers : une seule instance protège tous les services, et
l'attaquant est arrêté avant d'atteindre nginx.

Les motifs ont été validés avec `fail2ban-regex` sur des lignes de journal
représentatives : les échecs de connexion sont bien détectés, les connexions
réussies (302) et les simples affichages du formulaire (GET) ne déclenchent
rien. **Revérifier après l'installation de Dotclear**, le chemin de connexion
ayant changé selon les versions :

```bash
fail2ban-regex /var/lib/lxc/ct-blog/rootfs/var/log/apache2/blog.dumlu.top.access.log \
               /etc/fail2ban/filter.d/dotclear-auth.conf
```

## Reste à faire

- **Migration WordPress Brasserie T&S** vers `ct-brasserie` (vhost nginx déjà
  écrit, jail Fail2Ban déjà écrite mais désactivée).
- **Envoi du courrier du formulaire de contact.** `contact.php` appelle
  `mail()`, qui a besoin d'un agent de courrier dans `ct-portfolio`. Un envoi
  direct depuis l'IP d'un VPS, sur un domaine en `.top`, sera presque
  systématiquement rejeté ou classé en indésirable. Deux voies :
  publier les enregistrements SPF, DKIM et DMARC du domaine, ou faire relayer
  par un SMTP existant (msmtp vers le SMTP Yahoo avec un mot de passe
  d'application). Le second est plus fiable et plus rapide à mettre en place.
- **Sauvegardes.** Rien n'est sauvegardé pour l'instant : prévoir un dump
  `mariadb-dump` et une copie de `/var/www` de chaque conteneur.
