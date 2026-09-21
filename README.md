# Portfolio — Erhan Dumlu

Portfolio professionnel · BTS SIO option SISR · Lycée Guy-Mollet, Arras.

Site statique « fait main » (HTML / CSS / JS, sans framework), destiné à être
servi par Nginx sur un VPS auto-hébergé.

## Arborescence

```
site/                     ← racine à servir par le serveur web (docroot)
├── index.html            page unique, 7 sections ancrées
├── contact.php           traitement du formulaire de contact (PHP 8.1+)
├── robots.txt
├── sitemap.xml
└── assets/
    ├── css/style.css     feuille de style unique
    ├── js/main.js        menu mobile, section active, envoi du formulaire
    └── img/favicon.svg

brasserie.html            projet WordPress Brasserie T&S (à migrer, sous-domaine dédié)
```

## Infrastructure cible

Domaine : **dumlu.top**

| Service   | Sous-domaine          | Technologie          | État        |
| --------- | --------------------- | -------------------- | ----------- |
| Vitrine   | `dumlu.top`           | HTML/CSS/JS + Nginx  | à déployer  |
| Blog      | `blog.dumlu.top`      | Dotclear             | à installer |
| Brasserie | `brasserie.dumlu.top` | WordPress            | à migrer    |

Sur le VPS : durcissement SSH, Apache, Fail2Ban et IPset sont en place.
Restent à mettre en œuvre les conteneurs LXC et le reverse proxy Nginx.

## Développement local

```bash
php -S localhost:8000 -t site
# puis ouvrir http://localhost:8000
```

`contact.php` a besoin de PHP 8.1 ou plus (il utilise `str_contains` et le type
de retour `never`) et d'un agent de courrier capable de délivrer le message.

### Délivrabilité du formulaire de contact

`contact.php` envoie depuis `contact@dumlu.top` (constante `MAIL_FROM`) avec le
visiteur en `Reply-To`. Pour que le message arrive réellement, il faut publier
les enregistrements DNS **SPF**, **DKIM** et **DMARC** du domaine. Sans eux,
un envoi depuis l'IP neuve d'un VPS est rejeté ou classé en indésirable par la
plupart des messageries.

## Changer de domaine

```bash
grep -rl 'dumlu\.top' site README.md | xargs sed -i 's/dumlu\.top/NOUVEAU-DOMAINE/g'
```

Fichiers concernés : `site/index.html` (liens du blog, `canonical`, Open Graph),
`site/robots.txt`, `site/sitemap.xml` et `site/contact.php` (`MAIL_FROM`).
