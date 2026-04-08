#!/bin/bash

clear
echo -e "\e[32m"
figlet "MANGA CLI"
echo -e "\e[0m"

echo "📖 Reader iniciado..."
sleep 1

URL="$1"
LIMITE="$2"
CARPETA="imgs"

if [ -z "$URL" ]; then
  echo "Uso: ./manga_reader_url.sh <URL_IMAGEN> [LIMITE]"
  exit 1
fi

mkdir -p "$CARPETA"
rm -f "$CARPETA"/*

echo "🔍 Preparando descarga..."

# ===== EXTRAER BASE =====
BASE_PATH=$(echo "$URL" | sed -E 's#https://i[0-9]+\.nhentai\.net##')

SERVERS=("i1" "i2" "i3" "i4")
SERVER_OK=""

# ===== DETECTAR SERVER =====
echo "🔎 Detectando servidor..."

for server in "${SERVERS[@]}"; do
  TEST_URL="https://$server.nhentai.net$BASE_PATH/1.jpg"

  curl -s -L \
    -H "User-Agent: Mozilla/5.0" \
    -H "Referer: https://nhentai.net/" \
    -o test_img "$TEST_URL"

  if file test_img | grep -q image; then
    SERVER_OK="$server"
    rm -f test_img
    echo "✅ Servidor: $SERVER_OK"
    break
  fi

  rm -f test_img
done

if [ -z "$SERVER_OK" ]; then
  echo "❌ No se encontró servidor válido"
  exit 1
fi

BASE="https://$SERVER_OK.nhentai.net$BASE_PATH"

# ===== DESCARGA =====
i=1
COUNT=0

while true; do

  if [ -n "$LIMITE" ] && [ $COUNT -ge $LIMITE ]; then
    echo "⛔ Límite alcanzado: $LIMITE"
    break
  fi

  echo "📄 Página $i..."

  DESCARGADA=false

  for ext in jpg png webp; do
    FILE="$CARPETA/$i.$ext"

    curl -s -L \
      -H "User-Agent: Mozilla/5.0 (Linux; Android 10)" \
      -H "Referer: https://nhentai.net/" \
      -H "Accept: image/webp,image/apng,image/*,*/*;q=0.8" \
      "$BASE/$i.$ext" -o "$FILE"

    if file "$FILE" | grep -q image; then
      DESCARGADA=true
      ((COUNT++))
      echo "✅ $i.$ext"
      break
    else
      rm -f "$FILE"
    fi
  done

  if [ "$DESCARGADA" = false ]; then
    echo "🏁 Fin en página $i"
    break
  fi

  ((i++))
done

if [ $COUNT -eq 0 ]; then
  echo "❌ No se pudo descargar ninguna imagen"
  exit 1
fi

echo "✅ Total: $COUNT imágenes descargadas"

# ===== LECTOR =====

mapfile -t IMGS < <(ls "$CARPETA" | sort -V)
INDEX=0
TOTAL=${#IMGS[@]}

while true; do
    clear
    echo "📖 Página $((INDEX+1)) / $TOTAL"
    echo "[d] siguiente | [a] anterior | [q] salir"
    echo ""

    # Resolución mejorada pero estable
    chafa --size=120x60 --symbols=block "$CARPETA/${IMGS[$INDEX]}"

    read -rsn1 key

    case "$key" in
        d) ((INDEX++)) ;;
        a) ((INDEX--)) ;;
        q) clear; exit ;;
    esac

    if [ $INDEX -lt 0 ]; then INDEX=0; fi
    if [ $INDEX -ge $TOTAL ]; then INDEX=$((TOTAL-1)); fi
done
