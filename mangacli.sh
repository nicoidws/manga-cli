#!/bin/bash

clear
echo -e "\e[32m"
figlet "MANGA-CLI"
echo -e "\e[0m"
echo "by an0mia"
echo ""
echo "📖 Reader iniciado..."
sleep 1

URL="$1"
LIMITE="$2"
CARPETA="imgs"

if [ -z "$URL" ]; then
  echo "Uso: ./mangacli.sh <URL_IMAGEN> [LIMITE]"
  exit 1
fi

mkdir -p "$CARPETA"
rm -f "$CARPETA"/*

echo "🔍 Descargando imágenes..."

# Extraer base
BASE_ORIGINAL=$(echo "$URL" | sed -E 's#(https://i[0-9]+\.nhentai\.net/galleries/[0-9]+).*#\1#')

SERVERS=("i1" "i2" "i3" "i4")

i=1
COUNT=0

while true; do

  # límite opcional
  if [ -n "$LIMITE" ] && [ $COUNT -ge $LIMITE ]; then
    echo "⛔ Límite alcanzado: $LIMITE imágenes"
    break
  fi

  echo "📄 Página $i..."

  DESCARGADA=false

  for server in "${SERVERS[@]}"; do
    BASE=$(echo "$BASE_ORIGINAL" | sed "s#i[0-9]#$server#")

    for ext in jpg png webp; do
      FILE="$CARPETA/$i.$ext"

      curl -s -L \
        -H "User-Agent: Mozilla/5.0 (Linux; Android 10)" \
        -H "Referer: https://nhentai.net/" \
        -H "Accept: image/webp,image/apng,image/*,*/*;q=0.8" \
        "$BASE/$i.$ext" -o "$FILE"

      # validar que sea imagen real
      if file "$FILE" | grep -qE 'image'; then
        DESCARGADA=true
        ((COUNT++))
        echo "✅ $i.$ext ($server)"
        break 2
      else
        rm -f "$FILE"
      fi
    done
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

    chafa --size=120x60 --symbols=block --color-space=rgb "$CARPETA/${IMGS[$INDEX]}"

    read -rsn1 key

    case "$key" in
        d) ((INDEX++)) ;;
        a) ((INDEX--)) ;;
        q) clear; exit ;;
    esac

    if [ $INDEX -lt 0 ]; then INDEX=0; fi
    if [ $INDEX -ge $TOTAL ]; then INDEX=$((TOTAL-1)); fi
done
