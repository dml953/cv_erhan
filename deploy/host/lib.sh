#!/usr/bin/env bash
# Fonctions communes aux scripts exécutés sur l'hôte.

set -euo pipefail

info()    { printf '\033[1;34m[i]\033[0m %s\n' "$*"; }
ok()      { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
avert()   { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
echec()   { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

exige_root() {
  [ "$(id -u)" -eq 0 ] || echec "Ce script doit être lancé en root (sudo)."
}

# Demande confirmation avant une action non triviale.
confirme() {
  local reponse
  printf '\033[1;33m[?]\033[0m %s [o/N] ' "$1"
  read -r reponse
  case "$reponse" in
    [oO]|[oO][uU][iI]|[yY]) return 0 ;;
    *) info "Annulé."; return 1 ;;
  esac
}

# Exécute une commande dans un conteneur.
dans_ct() {
  local ct="$1"; shift
  lxc-attach -n "$ct" -- "$@"
}

# Attend qu'un conteneur ait une adresse IP et accède au réseau.
attendre_reseau() {
  local ct="$1"
  info "Attente du réseau dans $ct…"
  for _ in $(seq 1 30); do
    if lxc-attach -n "$ct" -- getent hosts deb.debian.org >/dev/null 2>&1; then
      ok "$ct : réseau opérationnel."
      return 0
    fi
    sleep 2
  done
  echec "$ct n'a pas accès au réseau après 60 s. Vérifier lxc-net et le pare-feu de l'hôte."
}

# Exécute un script local à l'intérieur d'un conteneur, avec ses arguments.
# Le script n'est pas copié : il est envoyé sur l'entrée standard de bash.
executer_dans_ct() {
  local ct="$1" script="$2"; shift 2
  [ -f "$script" ] || echec "Script introuvable : $script"
  info "Exécution de $(basename "$script") dans $ct…"
  lxc-attach -n "$ct" -- bash -s -- "$@" < "$script"
}
