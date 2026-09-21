#!/usr/bin/env bash
#
# S'exécute À L'INTÉRIEUR de ct-db.
# Installe MariaDB et crée une base applicative avec son compte dédié.
#
# Usage (depuis l'hôte) :
#   executer_dans_ct ct-db deploy/containers/db-base.sh <base> <utilisateur> <réseau-autorisé>

set -euo pipefail

BASE="${1:?nom de la base attendu}"
UTILISATEUR="${2:?nom du compte SQL attendu}"
RESEAU="${3:-10.0.3.%}"

export DEBIAN_FRONTEND=noninteractive

if ! command -v mariadbd >/dev/null 2>&1 && ! command -v mysqld >/dev/null 2>&1; then
  echo "[i] Installation de MariaDB…"
  apt-get update -qq
  apt-get install -y -qq mariadb-server pwgen

  # MariaDB n'écoute que sur la boucle locale par défaut : les autres
  # conteneurs doivent pouvoir l'atteindre sur le bridge privé.
  cat > /etc/mysql/mariadb.conf.d/99-lxc.cnf <<'CONF'
[mysqld]
bind-address = 0.0.0.0
skip-name-resolve
CONF
  systemctl restart mariadb
  systemctl enable mariadb >/dev/null 2>&1 || true
fi

command -v pwgen >/dev/null 2>&1 || apt-get install -y -qq pwgen
MDP="$(pwgen -s 32 1)"

# Les droits sont limités à cette base et à ce réseau : un compte volé dans
# un conteneur web ne donne pas accès aux bases des autres services.
mariadb <<SQL
CREATE DATABASE IF NOT EXISTS \`${BASE}\`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${UTILISATEUR}'@'${RESEAU}' IDENTIFIED BY '${MDP}';
ALTER USER '${UTILISATEUR}'@'${RESEAU}' IDENTIFIED BY '${MDP}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER,
      CREATE TEMPORARY TABLES, LOCK TABLES, REFERENCES
  ON \`${BASE}\`.* TO '${UTILISATEUR}'@'${RESEAU}';
FLUSH PRIVILEGES;
SQL

echo
echo "[+] Base « ${BASE} » prête."
echo "    Hôte        : $(hostname -I | awk '{print $1}')"
echo "    Utilisateur : ${UTILISATEUR}"
echo "    Mot de passe: ${MDP}"
echo
echo "[!] Note ce mot de passe maintenant : il n'est pas conservé ailleurs."
