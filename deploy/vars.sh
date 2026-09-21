#!/usr/bin/env bash
# shellcheck disable=SC2034  # fichier de variables : consommé par les autres scripts
# Variables partagées par tous les scripts de déploiement.
# Unique endroit à modifier si le domaine, le plan d'adressage ou les noms
# de conteneurs changent.

# ── Domaine ──────────────────────────────────────────────────────────────
DOMAINE="dumlu.top"
EMAIL_ADMIN="dumluerhan@yahoo.com"        # utilisé par Let's Encrypt

# ── Réseau LXC ───────────────────────────────────────────────────────────
# Plage par défaut du bridge lxcbr0 fourni par le paquet lxc sous Debian.
LXC_RESEAU="10.0.3.0/24"
LXC_PASSERELLE="10.0.3.1"

# ── Conteneurs : nom, adresse fixe, rôle ────────────────────────────────
CT_DB="ct-db";               IP_DB="10.0.3.10"
CT_PORTFOLIO="ct-portfolio"; IP_PORTFOLIO="10.0.3.11"
CT_BLOG="ct-blog";           IP_BLOG="10.0.3.12"
CT_BRASSERIE="ct-brasserie"; IP_BRASSERIE="10.0.3.13"

# Distribution des conteneurs. `lxc-create -t download -- --list` donne la
# liste des images disponibles ; le script vérifie avant de créer.
LXC_DISTRIB="debian"
LXC_VERSION="trixie"
LXC_ARCH="amd64"

# ── Dotclear ─────────────────────────────────────────────────────────────
# URL de l'archive, à relever sur https://dotclear.org/download
# (laisser vide : le script demandera l'URL plutôt que d'en inventer une).
DOTCLEAR_URL="${DOTCLEAR_URL:-}"
DOTCLEAR_BDD="dotclear"
DOTCLEAR_USER="dotclear"

# ── Sorties ──────────────────────────────────────────────────────────────
# Répertoire du dépôt, déduit de l'emplacement de ce fichier.
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$DEPLOY_DIR")"
