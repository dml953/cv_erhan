#!/usr/bin/env bash
#
# Étape 4 — Obtient les certificats Let's Encrypt et active un vhost HTTPS.
#
# Usage : ./04-tls.sh <domaine> [domaine-supplémentaire…]
#   ex.  ./04-tls.sh dumlu.top www.dumlu.top
#        ./04-tls.sh blog.dumlu.top

set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=lib.sh
. ./lib.sh
# shellcheck source=../vars.sh
. ../vars.sh

exige_root

[ $# -ge 1 ] || echec "Usage : $0 <domaine> [domaine-supplémentaire…]"
PRINCIPAL="$1"

command -v certbot >/dev/null 2>&1 || {
  info "Installation de certbot…"
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq certbot
}

# ── Contrôle DNS ─────────────────────────────────────────────────────────
# Let's Encrypt refuse un domaine qui ne pointe pas ici. Autant s'en
# apercevoir maintenant qu'après avoir épuisé le quota de tentatives.
IP_PUBLIQUE="$(curl -fsS --max-time 10 https://ifconfig.me 2>/dev/null || true)"
for d in "$@"; do
  RESOLU="$(getent ahostsv4 "$d" 2>/dev/null | awk '{print $1}' | sort -u | head -1)"
  if [ -z "$RESOLU" ]; then
    echec "$d ne résout pas. Créer l'enregistrement A avant de continuer."
  fi
  if [ -n "$IP_PUBLIQUE" ] && [ "$RESOLU" != "$IP_PUBLIQUE" ]; then
    avert "$d pointe vers $RESOLU alors que ce serveur est en $IP_PUBLIQUE."
    confirme "Continuer quand même ?" || exit 1
  else
    ok "$d -> $RESOLU"
  fi
done

# ── Certificat ───────────────────────────────────────────────────────────
# Méthode webroot : nginx continue de servir pendant la validation, contrairement
# à --standalone qui exigerait de l'arrêter.
ARGS_D=()
for d in "$@"; do ARGS_D+=(-d "$d"); done

info "Demande du certificat pour : $*"
certbot certonly --webroot -w /var/www/certbot \
  --non-interactive --agree-tos --email "$EMAIL_ADMIN" \
  --cert-name "$PRINCIPAL" "${ARGS_D[@]}"

# certbot dépose ces deux fichiers, inclus par nos vhosts.
[ -f /etc/letsencrypt/options-ssl-nginx.conf ] \
  || curl -fsS -o /etc/letsencrypt/options-ssl-nginx.conf \
       https://raw.githubusercontent.com/certbot/certbot/main/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf
[ -f /etc/letsencrypt/ssl-dhparams.pem ] \
  || openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048

# ── Activation du vhost ──────────────────────────────────────────────────
VHOST="/etc/nginx/sites-available/${PRINCIPAL}.conf"
[ -f "$VHOST" ] || echec "$VHOST absent. Rejouer 03-nginx.sh."

ln -sf "$VHOST" /etc/nginx/sites-enabled/
if ! nginx -t; then
  rm -f "/etc/nginx/sites-enabled/${PRINCIPAL}.conf"
  echec "nginx -t a échoué : vhost désactivé, service intact."
fi
systemctl reload nginx
ok "https://${PRINCIPAL} est actif."

# Le renouvellement est assuré par le timer systemd du paquet certbot.
systemctl enable --now certbot.timer >/dev/null 2>&1 || true
info "Renouvellement automatique : $(systemctl is-active certbot.timer 2>/dev/null || echo 'timer absent, vérifier manuellement')"
