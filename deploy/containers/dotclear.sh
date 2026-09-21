#!/usr/bin/env bash
#
# S'exécute À L'INTÉRIEUR de ct-blog, après web-base.sh.
# Télécharge et met en place Dotclear.
#
# Usage (depuis l'hôte) :
#   executer_dans_ct ct-blog deploy/containers/dotclear.sh <url-archive> [docroot]
#
# L'URL n'est pas codée en dur : elle se relève sur https://dotclear.org/download
# et change à chaque version. Le script contrôle ce qu'il a reçu au lieu de
# supposer que l'URL est la bonne.

set -euo pipefail

URL="${1:?URL de l archive Dotclear attendue, a relever sur https://dotclear.org/download}"
DOCROOT="${2:-/var/www/dotclear}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "[i] Téléchargement depuis $URL"
curl -fSL --max-time 180 -o "$TMP/dotclear.archive" "$URL"

TAILLE="$(stat -c%s "$TMP/dotclear.archive")"
[ "$TAILLE" -gt 500000 ] \
  || { echo "[x] Archive de $TAILLE octets : trop petite, ce n'est pas Dotclear." >&2
       echo "[x] L'URL renvoie probablement une page HTML d'erreur." >&2; exit 1; }

# ── Extraction, selon le format réellement reçu ──────────────────────────
TYPE="$(file -b --mime-type "$TMP/dotclear.archive")"
echo "[i] Archive de $TAILLE octets, type $TYPE"

case "$TYPE" in
  application/gzip|application/x-gzip) tar -xzf "$TMP/dotclear.archive" -C "$TMP" ;;
  application/zip)                     unzip -q "$TMP/dotclear.archive" -d "$TMP" ;;
  *) echo "[x] Format inattendu : $TYPE (ni .tar.gz ni .zip)." >&2; exit 1 ;;
esac

# ── Contrôle du contenu ──────────────────────────────────────────────────
# On cherche le répertoire qui contient réellement Dotclear plutôt que de
# supposer qu'il s'appelle « dotclear ».
SOURCE=""
for d in "$TMP"/*/; do
  if [ -f "${d}index.php" ] && [ -d "${d}admin" ]; then SOURCE="$d"; break; fi
done
[ -n "$SOURCE" ] || {
  echo "[x] Ni index.php ni admin/ trouvés dans l'archive. Contenu extrait :" >&2
  find "$TMP" -maxdepth 2 >&2; exit 1; }

echo "[+] Dotclear trouvé dans $(basename "$SOURCE")"

# ── Mise en place ────────────────────────────────────────────────────────
if [ -d "$DOCROOT" ] && [ -n "$(ls -A "$DOCROOT" 2>/dev/null)" ]; then
  SAUVEGARDE="${DOCROOT}.avant-$(date +%Y%m%d-%H%M%S)"
  echo "[!] $DOCROOT n'est pas vide, sauvegarde vers $SAUVEGARDE"
  mv "$DOCROOT" "$SAUVEGARDE"
fi

mkdir -p "$DOCROOT"
cp -a "$SOURCE". "$DOCROOT/"

# L'installateur web écrit inc/config.php : le serveur doit pouvoir écrire
# dans ce répertoire, et dans cache/ et public/ ensuite.
chown -R www-data:www-data "$DOCROOT"
find "$DOCROOT" -type d -exec chmod 750 {} +
find "$DOCROOT" -type f -exec chmod 640 {} +

# ── Extensions PHP requises ──────────────────────────────────────────────
MANQUANTES=""
for ext in mbstring pdo_mysql simplexml curl gd zip dom json openssl iconv; do
  php -m | grep -qix "$ext" || MANQUANTES="$MANQUANTES $ext"
done
if [ -n "$MANQUANTES" ]; then
  echo "[!] Extensions PHP absentes :$MANQUANTES"
  echo "[!] Les installer avant de lancer l'assistant."
else
  echo "[+] Toutes les extensions PHP attendues sont présentes."
fi

# ── Chemin réel de l'assistant ───────────────────────────────────────────
# Il a changé de place selon les versions : on affiche celui qui existe.
INSTALLATEUR=""
for p in admin/install/index.php admin/install.php install/index.php; do
  [ -f "$DOCROOT/$p" ] && { INSTALLATEUR="$p"; break; }
done

echo
echo "[+] Dotclear déposé dans $DOCROOT"
if [ -n "$INSTALLATEUR" ]; then
  echo "[+] Terminer dans le navigateur : https://blog.dumlu.top/${INSTALLATEUR}"
else
  echo "[!] Assistant d'installation non localisé. Fichiers à la racine :"
  find "$DOCROOT" -maxdepth 1 -printf '%f\n' | head -20
fi
echo
echo "    Renseigner alors : hôte de la base = 10.0.3.10, base = dotclear,"
echo "    utilisateur = dotclear, et le mot de passe affiché par db-base.sh."
