#!/usr/bin/env bash
#
# Publie le contenu de site/ dans le conteneur ct-portfolio.
#
# Les conteneurs LXC privilégiés partagent l'espace d'UID de l'hôte : on écrit
# directement dans leur système de fichiers, sans passer par SSH.
#
# À lancer en root sur le VPS, depuis le dépôt cloné.

set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=host/lib.sh
. ./host/lib.sh
# shellcheck source=vars.sh
. ./vars.sh

exige_root

SOURCE="${REPO_DIR}/site/"
CIBLE="/var/lib/lxc/${CT_PORTFOLIO}/rootfs/var/www/portfolio/"

[ -d "$SOURCE" ]  || echec "Source introuvable : $SOURCE"
[ -d "/var/lib/lxc/${CT_PORTFOLIO}/rootfs" ] \
  || echec "Conteneur ${CT_PORTFOLIO} introuvable. Lancer host/02-creer-conteneur.sh."

mkdir -p "$CIBLE"

# ── Aperçu avant écriture ────────────────────────────────────────────────
# --delete aligne la cible sur la source : tout fichier présent uniquement
# dans le conteneur disparaît. On montre d'abord ce qui va changer.
info "Différences avec la version publiée :"
rsync -a --delete --itemize-changes --dry-run "$SOURCE" "$CIBLE" | sed 's/^/    /'

echo
confirme "Appliquer ces changements ?" || exit 0

rsync -a --delete "$SOURCE" "$CIBLE"

# www-data porte l'UID 33 dans le conteneur comme sur l'hôte.
chown -R 33:33 "$CIBLE"
find "$CIBLE" -type d -exec chmod 755 {} +
find "$CIBLE" -type f -exec chmod 644 {} +

ok "Site publié dans ${CT_PORTFOLIO}."
info "Contrôle depuis l'hôte :"
info "  curl -I -H 'Host: ${DOMAINE}' http://${IP_PORTFOLIO}/"
