#!/usr/bin/env bash
#
# Étape 3 — Installe nginx sur l'hôte en reverse proxy et déploie les vhosts.
#
# nginx ne sert aucun fichier : il termine le TLS et relaie vers les
# conteneurs. Tout le contenu vit dans les conteneurs.

set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=lib.sh
. ./lib.sh
# shellcheck source=../vars.sh
. ../vars.sh

exige_root

# ── Conflit de port ──────────────────────────────────────────────────────
# Apache tournait jusqu'ici sur l'hôte. Son rôle part dans les conteneurs,
# mais on ne coupe rien sans demander : il sert peut-être encore quelque chose.
if ss -tlnp 2>/dev/null | grep -qE ':(80|443)\b.*apache2'; then
  avert "Apache occupe le port 80 et/ou 443 sur l'hôte."
  avert "nginx ne peut pas démarrer tant qu'il les détient."
  avert "Son rôle est désormais assuré par Apache DANS les conteneurs."
  if confirme "Arrêter et désactiver Apache sur l'hôte ?"; then
    systemctl disable --now apache2
    ok "Apache arrêté et désactivé sur l'hôte (les paquets restent installés)."
  else
    echec "Libère les ports 80/443 puis relance ce script."
  fi
fi

info "Installation de nginx…"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq nginx

VERSION_NGINX="$(nginx -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
info "nginx $VERSION_NGINX détecté."

mkdir -p /var/www/certbot /etc/nginx/snippets
install -m 0644 nginx/snippets/proxy-commun.conf      /etc/nginx/snippets/
install -m 0644 nginx/snippets/en-tetes-securite.conf /etc/nginx/snippets/

# ── Déploiement des vhosts ───────────────────────────────────────────────
# Seuls le bloc ACME et la vitrine sont activés maintenant. Les vhosts du
# blog et de la brasserie référencent des certificats qui n'existent pas
# encore : les activer ferait échouer `nginx -t`.
deployer_vhost() {
  local fichier="$1" cible="/etc/nginx/sites-available/$1"
  install -m 0644 "nginx/$fichier" "$cible"

  # `http2 on;` n'existe qu'à partir de nginx 1.25.1. En deçà, l'option se
  # déclare sur la ligne listen, sinon nginx refuse de démarrer.
  if [ "$(printf '%s\n1.25.1\n' "$VERSION_NGINX" | sort -V | head -1)" != "1.25.1" ]; then
    sed -i '/^\s*http2 on;$/d; s/^\(\s*listen.*\) ssl;$/\1 ssl http2;/' "$cible"
    info "$fichier : syntaxe HTTP/2 adaptée à nginx < 1.25.1."
  fi

  # Sans IPv6 sur l'hôte, `listen [::]` fait échouer le démarrage.
  if ! ip -6 addr show scope global 2>/dev/null | grep -q inet6; then
    sed -i '/listen \[::\]/d' "$cible"
    info "$fichier : pas d'IPv6 sur l'hôte, directives listen [::] retirées."
  fi
}

deployer_vhost "00-acme.conf"
deployer_vhost "${DOMAINE}.conf"
deployer_vhost "blog.${DOMAINE}.conf"
deployer_vhost "brasserie.${DOMAINE}.conf"

# Le vhost par défaut de Debian répondrait à la place des nôtres.
rm -f /etc/nginx/sites-enabled/default
ln -sf "/etc/nginx/sites-available/00-acme.conf" /etc/nginx/sites-enabled/

if ! nginx -t; then
  echec "Configuration nginx invalide, rien n'a été rechargé."
fi

systemctl enable nginx >/dev/null 2>&1 || true
systemctl restart nginx
ok "nginx démarré, seul le bloc ACME est actif pour l'instant."

info "Les vhosts HTTPS sont déposés mais non activés : ils attendent leurs"
info "certificats. Suite : ./04-tls.sh"
