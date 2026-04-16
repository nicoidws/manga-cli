#!/bin/bash

clear
echo -e "\e[32m"
figlet "MANGA-CLI PRO"
echo -e "\e[0m"
echo "by an0mia"
echo ""
echo "📖 Reader iniciado..."
sleep 1

URL="$1"
LIMITE="$2"
CARPETA="imgs"
COOKIE_JAR="cookies.txt"

if [ -z "$URL" ]; then
  echo "Uso: ./manga-cli.sh <URL|PATH_LOCAL> [LIMITE]"
  exit 1
fi

mkdir -p "$CARPETA"
rm -f "$CARPETA"/*

echo "🔍 Procesando..."

# ===== DETECCIÓN =====

if [[ "$URL" =~ ^/|^file:// ]]; then
  TIPO="local"

elif [[ "$URL" =~ yupmanga\.com ]]; then
  TIPO="yupmanga"

else
  TIPO="generico"
fi

COUNT=0

# =========================================================
# 🧠 MODO LOCAL (NUEVO)
# =========================================================

if [ "$TIPO" = "local" ]; then
  echo "📂 Modo local activado..."

  if [[ "$URL" =~ file:// ]]; then
    DIR="${URL#file://}"
  else
    DIR="$URL"
  fi

  mapfile -t FILES < <(ls "$DIR" | grep -E '\.(jpg|png|webp)' | sort -V)

  for file in "${FILES[@]}"; do
    if [ -n "$LIMITE" ] && [ $COUNT -ge $LIMITE ]; then
      break
    fi

    ((COUNT++))
    cp "$DIR/$file" "$CARPETA/$COUNT.jpg"
  done
fi

# =========================================================
# 🌐 YUPMANGA PRO (SCRAPER REAL)
# =========================================================

if [ "$TIPO" = "yupmanga" ]; then
  echo "🌐 YupManga PRO..."

  rm -f "$COOKIE_JAR"

  CHAPTER=$(echo "$URL" | grep -oP 'chapter=\K[^&]+')
  TOKEN=$(echo "$URL" | grep -oP 'token=\K[^&]+')

  READER_URL="https://www.yupmanga.com/reader_v2.php?chapter=$CHAPTER"

  # Crear sesión real
  curl -s -c "$COOKIE_JAR" \
    -H "User-Agent: Mozilla/5.0" \
    "https://www.yupmanga.com/" > /dev/null

  # Obtener HTML real
  HTML=$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -H "User-Agent: Mozilla/5.0" \
    -H "Referer: https://www.yupmanga.com/" \
    "$READER_URL")

  # 🔥 EXTRAER TOKEN DESDE JS REAL
  if [ -z "$TOKEN" ]; then
    TOKEN=$(echo "$HTML" | grep -oP 'token["'\'']?\s*[:=]\s*["'\'']\K[^"'\'']+')
  fi

  if [ -z "$TOKEN" ]; then
    echo "❌ No se pudo obtener token"
    exit 1
  fi

  echo "🔑 Token OK"

  # 🔥 EXTRAER TOTAL DE PÁGINAS (MUY IMPORTANTE)
  TOTAL_PAGES=$(echo "$HTML" | grep -oP 'total_pages["'\'']?\s*[:=]\s*\K[0-9]+' | head -n1)

  if [ -z "$TOTAL_PAGES" ]; then
    TOTAL_PAGES=999  # fallback
  fi

  echo "📊 Páginas detectadas: $TOTAL_PAGES"

  for ((PAGE=1; PAGE<=TOTAL_PAGES; PAGE++)); do

    if [ -n "$LIMITE" ] && [ $COUNT -ge $LIMITE ]; then
      break
    fi

    FILE="$CARPETA/$PAGE.jpg"

    IMG_URL="https://www.yupmanga.com/image-proxy-v2.php?chapter=$CHAPTER&page=$PAGE&token=$TOKEN&context=reader"

    echo "⬇ Página $PAGE"

    curl -s -L \
      -b "$COOKIE_JAR" \
      -H "User-Agent: Mozilla/5.0" \
      -H "Referer: $READER_URL&token=$TOKEN&page=$PAGE" \
      -H "Accept: image/*" \
      "$IMG_URL" -o "$FILE"

    if file "$FILE" | grep -qE 'image'; then
      ((COUNT++))
    else
      rm -f "$FILE"
      echo "⚠ Corte en página $PAGE"
      break
    fi
  done
fi

# =========================================================
# 🌍 GENERICO (fallback)
# =========================================================

if [ "$TIPO" = "generico" ]; then
  echo "🌍 Modo genérico..."

  BASE=$(echo "$URL" | sed -E 's#(.*/)[0-9]+\.(jpg|png|webp)#\1#')
  FILE=$(basename "$URL")
  NUM=$(echo "$FILE" | grep -oE '^[0-9]+')
  EXT=".$(echo "$FILE" | cut -d'.' -f2)"
  PAD=${#NUM}
  i=$NUM

  while true; do

    if [ -n "$LIMITE" ] && [ $COUNT -ge $LIMITE ]; then
      break
    fi

    NUM_FORMAT=$(printf "%0${PAD}d" $i)
    FILE="$CARPETA/$NUM_FORMAT$EXT"

    curl -s -L "$BASE$NUM_FORMAT$EXT" -o "$FILE"

    if file "$FILE" | grep -qE 'image'; then
      ((COUNT++))
    else
      rm -f "$FILE"
      break
    fi

    ((i++))
  done
fi

# ===== VALIDACIÓN =====

if [ $COUNT -eq 0 ]; then
  echo "❌ No se pudo descargar nada"
  exit 1
fi

echo "✅ Total: $COUNT imágenes"

# =========================================================
# 📖 LECTOR
# =========================================================

mapfile -t IMGS < <(ls "$CARPETA" | sort -V)
INDEX=0
TOTAL=${#IMGS[@]}

while true; do
    clear
    echo "📖 Página $((INDEX+1)) / $TOTAL"
    echo "[d] siguiente | [a] anterior | [q] salir"
    echo ""

    chafa \
      --fit-width \
      --symbols=block \
      --color-space=rgb \
      "$CARPETA/${IMGS[$INDEX]}"

    read -rsn1 key

    case "$key" in
        d) ((INDEX++)) ;;
        a) ((INDEX--)) ;;
        q) clear; exit ;;
    esac

    if [ $INDEX -lt 0 ]; then INDEX=0; fi
    if [ $INDEX -ge $TOTAL ]; then INDEX=$((TOTAL-1)); fi
done
