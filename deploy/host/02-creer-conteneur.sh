#!/usr/bin/env bash
#
# Étape 2 — Crée un conteneur LXC et le met à jour.
#
# Usage : ./02-creer-conteneur.sh <nom-du-conteneur>
#   ex.  ./02-creer-conteneur.sh ct-portfolio
#
# Le script est sans effet si le conteneur existe déjà.

set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=lib.sh
. ./lib.sh
# shellcheck source=../vars.sh
. ../vars.sh

exige_root

CT="${1:-}"
[ -n "$CT" ] || echec "Usage : $0 <nom-du-conteneur>  (ex. $CT_PORTFOLIO)"

# Le nom doit figurer dans les réservations DHCP, sinon l'adresse fixe
# attendue par nginx ne sera pas attribuée.
grep -q "dhcp-host=${CT}," /etc/lxc/dnsmasq.conf \
  || echec "$CT n'a pas de réservation dans /etc/lxc/dnsmasq.conf. Le déclarer dans deploy/vars.sh puis rejouer 01-lxc-setup.sh."

if lxc-info -n "$CT" >/dev/null 2>&1; then
  ok "$CT existe déjà, rien à créer."
else
  info "Vérification de la disponibilité de l'image ${LXC_DISTRIB}/${LXC_VERSION}/${LXC_ARCH}…"
  if ! lxc-create -n "$CT" -t download -- \
        --list 2>/dev/null | grep -qE "^${LXC_DISTRIB}[[:space:]]+${LXC_VERSION}[[:space:]]+${LXC_ARCH}"; then
    avert "Image ${LXC_DISTRIB}/${LXC_VERSION}/${LXC_ARCH} introuvable dans le catalogue."
    avert "Images disponibles :"
    lxc-create -n tmp-liste -t download -- --list 2>/dev/null | head -40 >&2 || true
    echec "Corriger LXC_VERSION dans deploy/vars.sh."
  fi

  info "Création de $CT…"
  lxc-create -n "$CT" -t download -- \
    --dist "$LXC_DISTRIB" --release "$LXC_VERSION" --arch "$LXC_ARCH"
  ok "$CT créé."
fi

# Démarrage automatique au boot de l'hôte.
if ! grep -q '^lxc.start.auto' "/var/lib/lxc/$CT/config"; then
  printf 'lxc.start.auto = 1\nlxc.start.delay = 5\n' >> "/var/lib/lxc/$CT/config"
  info "Démarrage automatique activé pour $CT."
fi

lxc-info -n "$CT" -s | grep -q RUNNING || lxc-start -n "$CT"
attendre_reseau "$CT"

IP_OBTENUE="$(lxc-info -n "$CT" -iH | head -1)"
info "$CT a l'adresse $IP_OBTENUE"

info "Mise à jour de $CT…"
dans_ct "$CT" env DEBIAN_FRONTEND=noninteractive apt-get update -qq
dans_ct "$CT" env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
dans_ct "$CT" env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ca-certificates curl

ok "$CT est prêt (adresse $IP_OBTENUE)."
