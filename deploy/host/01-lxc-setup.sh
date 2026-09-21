#!/usr/bin/env bash
#
# Étape 1 — Installe LXC sur l'hôte et prépare le bridge lxcbr0.
#
# À lancer en root sur le VPS.

set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=lib.sh
. ./lib.sh
# shellcheck source=../vars.sh
. ../vars.sh

exige_root

info "Installation de LXC et de ses dépendances…"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq lxc lxc-templates debootstrap bridge-utils \
                       uidmap dnsmasq-base rsync

# ── Bridge ───────────────────────────────────────────────────────────────
# Le paquet lxc fournit le service lxc-net, qui crée lxcbr0 et lance un
# dnsmasq dédié. On force la configuration plutôt que de supposer les
# valeurs par défaut.
info "Configuration de lxc-net…"
cat > /etc/default/lxc-net <<CONF
USE_LXC_BRIDGE="true"
LXC_BRIDGE="lxcbr0"
LXC_ADDR="${LXC_PASSERELLE}"
LXC_NETMASK="255.255.255.0"
LXC_NETWORK="${LXC_RESEAU}"
LXC_DHCP_RANGE="10.0.3.100,10.0.3.200"
LXC_DHCP_MAX="253"
LXC_DHCP_CONFILE="/etc/lxc/dnsmasq.conf"
CONF

# Adresses fixes : dnsmasq attribue toujours la même IP à un conteneur
# donné, d'après son nom d'hôte. Plus simple à maintenir qu'une
# configuration réseau statique dans chaque conteneur.
info "Réservation des adresses fixes…"
cat > /etc/lxc/dnsmasq.conf <<CONF
dhcp-host=${CT_DB},${IP_DB}
dhcp-host=${CT_PORTFOLIO},${IP_PORTFOLIO}
dhcp-host=${CT_BLOG},${IP_BLOG}
dhcp-host=${CT_BRASSERIE},${IP_BRASSERIE}
CONF

# Gabarit appliqué à tout nouveau conteneur.
info "Configuration par défaut des conteneurs…"
cat > /etc/lxc/default.conf <<'CONF'
lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.apparmor.profile = generated
lxc.apparmor.allow_nesting = 0
CONF

systemctl enable lxc-net lxc >/dev/null 2>&1 || true
systemctl restart lxc-net
ok "lxc-net redémarré."

# ── Contrôles ────────────────────────────────────────────────────────────
ip link show lxcbr0 >/dev/null 2>&1 \
  || echec "lxcbr0 n'existe pas. Consulter : journalctl -u lxc-net"
ok "Bridge lxcbr0 présent : $(ip -4 addr show lxcbr0 | awk '/inet /{print $2}')"

# Le routage vers les conteneurs ne marche que si le noyau relaie les
# paquets. Une configuration de pare-feu personnalisée le désactive parfois.
if [ "$(sysctl -n net.ipv4.ip_forward)" != "1" ]; then
  avert "net.ipv4.ip_forward est à 0 : les conteneurs n'auront pas Internet."
  echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-lxc-forward.conf
  sysctl -q -w net.ipv4.ip_forward=1
  ok "Relayage IPv4 activé (persistant)."
fi

# lxc-net pose ses propres règles de NAT. Un script de pare-feu maison
# (IPset, iptables) exécuté après coup peut les effacer sans prévenir.
if ! iptables -t nat -C POSTROUTING -s "$LXC_RESEAU" ! -d "$LXC_RESEAU" -j MASQUERADE 2>/dev/null; then
  avert "La règle de NAT de lxc-net est absente des règles actuelles."
  avert "Si tu as un script de pare-feu (IPset/iptables), il l'a probablement"
  avert "écrasée. Il doit être rejoué AVANT lxc-net, ou laisser passer :"
  avert "  iptables -t nat -A POSTROUTING -s $LXC_RESEAU ! -d $LXC_RESEAU -j MASQUERADE"
  avert "  iptables -A FORWARD -i lxcbr0 -j ACCEPT"
  avert "  iptables -A FORWARD -o lxcbr0 -j ACCEPT"
fi

ok "Étape 1 terminée. Suite : ./02-creer-conteneur.sh"
