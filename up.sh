#!/bin/bash
# Mise a jour manuelle du VPS (une fois). Ensuite le timer s'en charge.
# Commandes a coller dans la console Hetzner (sans &, sans _, sans *, sans >) :
#   wget -O u.sh https://github.com/ElAlonsoo/kimchi/raw/main/up.sh
#   bash u.sh
set -e
if [ -d /root/simbots ]; then
  DIR=/root/simbots
elif [ -d "$HOME/simbots" ]; then
  DIR="$HOME/simbots"
else
  echo "dossier simbots introuvable"
  exit 1
fi
cd "$DIR"

URL="https://raw.githubusercontent.com/ElAlonsoo/kimchi/main/bot_vps_sim5.zip"
TMPZIP="/tmp/bot-vps-sim5.zip"
UNPACK="/tmp/bot-vps-sim5-unpack"
SHA_FILE="$DIR/data/.zipsha"
mkdir -p "$DIR/data"

echo "telechargement..."
curl -fSL --retry 3 --retry-delay 2 -o "$TMPZIP" "$URL"
unzip -t "$TMPZIP" >/dev/null

rm -rf "$UNPACK"
mkdir -p "$UNPACK"
unzip -o "$TMPZIP" -d "$UNPACK" >/dev/null
SRC="$UNPACK"
if [ ! -f "$SRC/bots_sim.py" ] && [ -f "$SRC/simbots/bots_sim.py" ]; then
  SRC="$SRC/simbots"
fi
if [ ! -f "$SRC/bots_sim.py" ]; then
  echo "zip incomplet (pas de bots_sim.py)"
  exit 1
fi
rm -rf "$SRC/data" "$SRC/venv"
rm -f "$SRC/ntfy_topic.txt"

for f in "$SRC"/*; do
  [ -e "$f" ] || continue
  base=$(basename "$f")
  case "$base" in
    data|ntfy_topic.txt|venv) continue ;;
  esac
  cp -a "$f" "$DIR/"
done

NEW=$(sha256sum "$TMPZIP" | awk '{print $1}')
echo "$NEW" > "$SHA_FILE"
chmod +x "$DIR"/*.sh
rm -rf "$UNPACK" "$TMPZIP"

echo "installation (sans raz des donnees)..."
bash "$DIR/install.sh"
if [ "$(id -u)" -eq 0 ]; then
  systemctl restart pumpbot-sim
else
  sudo systemctl restart pumpbot-sim
fi
echo "OK. Les prochaines mises a jour se feront toutes seules (toutes les 10 min)."
