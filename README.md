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
└── assets/
    ├── css/style.css     feuille de style unique
    ├── js/main.js        menu mobile, section active, envoi du formulaire
    └── img/favicon.svg

brasserie.html            projet WordPress Brasserie T&S (à migrer, sous-domaine dédié)
```

## Infrastructure cible

| Service    | Sous-domaine                | Technologie        | État          |
|------------|-----------------------------|--------------------|---------------|
| Vitrine    | `mon-domaine.fr`            | HTML/CSS/JS + Nginx| à déployer    |
| Blog       | `blog.mon-domaine.fr`       | Dotclear           | à installer   |
| Brasserie  | `brasserie.mon-domaine.fr`  | WordPress          | à migrer      |

Sur le VPS : durcissement SSH, Apache, Fail2Ban et IPset sont en place.
Restent à mettre en œuvre les conteneurs LXC et le reverse proxy Nginx.

## Renseigner le nom de domaine

Le domaine définitif n'est pas encore acheté : le dépôt utilise le marqueur
`mon-domaine.fr`. Pour le remplacer partout en une commande :

```bash
grep -rl 'mon-domaine\.fr' site README.md | xargs sed -i 's/mon-domaine\.fr/VOTRE-DOMAINE.fr/g'
```

Fichiers concernés : `site/index.html` (liens du blog, `canonical`, Open Graph),
`site/robots.txt` (sitemap) et `site/contact.php` (constante `MAIL_FROM`).

## Développement local

```bash
# aperçu statique
php -S localhost:8000 -t site

# puis ouvrir http://localhost:8000
```

`contact.php` a besoin de PHP 8.1 ou plus (il utilise `str_contains` et le type
de retour `never`) et d'un agent de courrier local (Postfix en mode
« local only » suffit) pour que `mail()` aboutisse.
