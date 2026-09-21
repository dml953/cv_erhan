#!/usr/bin/env bash
#
# S'exécute À L'INTÉRIEUR d'un conteneur web.
# Installe Apache + PHP-FPM et publie un vhost.
#
# Usage (depuis l'hôte) :
#   executer_dans_ct ct-portfolio deploy/containers/web-base.sh <nom-site> <docroot>

set -euo pipefail

SITE="${1:?nom du site attendu (ex. dumlu.top)}"
DOCROOT="${2:?racine des documents attendue (ex. /var/www/portfolio)}"
PASSERELLE="${3:-10.0.3.1}"

echo "[i] Installation d'Apache et de PHP pour $SITE…"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
  apache2 php-fpm \
  php-mysql php-mbstring php-xml php-curl php-gd php-zip php-intl \
  unzip rsync

PHP_VER="$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')"
echo "[i] PHP $PHP_VER détecté."

a2enmod proxy_fcgi setenvif rewrite remoteip headers expires >/dev/null
a2enconf "php${PHP_VER}-fpm" >/dev/null

# ── Adresse réelle du visiteur ───────────────────────────────────────────
# Sans cela, Apache journalise l'IP de nginx (la passerelle) pour toutes les
# requêtes : les journaux deviennent inexploitables et Fail2Ban bannirait
# le reverse proxy au lieu de l'attaquant.
cat > /etc/apache2/conf-available/remoteip.conf <<CONF
RemoteIPHeader X-Forwarded-For
RemoteIPTrustedProxy ${PASSERELLE}

# %a rend l'adresse rétablie par mod_remoteip, %h rendrait celle du proxy.
LogFormat "%a %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" proxy_combined
CONF
a2enconf remoteip >/dev/null

# ── Discrétion du serveur ────────────────────────────────────────────────
cat > /etc/apache2/conf-available/durcissement.conf <<'CONF'
ServerTokens Prod
ServerSignature Off
TraceEnable Off

# Interdit la lecture du contenu des répertoires sans index.
<Directory /var/www/>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

# Fichiers qui ne doivent jamais être servis.
<FilesMatch "^\.|~$|\.(bak|old|orig|save|swp|sql|log)$">
    Require all denied
</FilesMatch>
CONF
a2enconf durcissement >/dev/null

# ── Vhost ────────────────────────────────────────────────────────────────
mkdir -p "$DOCROOT"
cat > "/etc/apache2/sites-available/${SITE}.conf" <<CONF
<VirtualHost *:80>
    ServerName ${SITE}
    DocumentRoot ${DOCROOT}

    ErrorLog  \${APACHE_LOG_DIR}/${SITE}.error.log
    CustomLog \${APACHE_LOG_DIR}/${SITE}.access.log proxy_combined

    <Directory ${DOCROOT}>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
CONF

a2dissite 000-default >/dev/null 2>&1 || true
a2ensite "${SITE}" >/dev/null

chown -R www-data:www-data "$DOCROOT"

apache2ctl configtest
systemctl restart "php${PHP_VER}-fpm"
systemctl restart apache2
systemctl enable apache2 "php${PHP_VER}-fpm" >/dev/null 2>&1 || true

echo "[+] Apache + PHP $PHP_VER opérationnels pour $SITE (racine : $DOCROOT)."
