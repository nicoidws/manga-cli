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
COOKIE_JAR="cookies.txt"

URL="$1"
LIMITE="$2"

# =========================
# VALIDACIÓN
# =========================

if [ -z "$URL" ]; then
  echo "Uso: ./manga-cli.sh <URL|PATH_LOCAL> [LIMITE]"
  exit 1
fi

# =========================
# CONFIGURACIÓN
# =========================

BASE_DIR="imgs"
CACHE_DIR=".cache"
COOKIE_JAR="cookies.txt"

mkdir -p "$BASE_DIR"
mkdir -p "$CACHE_DIR"

HASH=$(echo "$URL" | md5sum | cut -d' ' -f1)
CARPETA="$BASE_DIR/$HASH"

mkdir -p "$CARPETA"

echo "📁 Guardando en: $CARPETA"

COUNT=0

# =========================
# CACHE
# =========================

if [ -d "$CACHE_DIR/$HASH" ] && [ "$(ls -A "$CACHE_DIR/$HASH")" ]; then
  echo "⚡ Usando cache"
  cp "$CACHE_DIR/$HASH"/* "$CARPETA/"
  COUNT=$(ls "$CARPETA" | wc -l)
else
  SAVE_CACHE=true
fi
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
# 📚 SELECTOR DE CAPÍTULOS (yupmanga)
# =========================================================

if [[ "$TIPO" = "yupmanga" && "$URL" != *"chapter="* ]]; then
  echo "📚 Detectando capítulos..."

  HTML=$(curl -s -L "$URL" -H "User-Agent: Mozilla/5.0")

  mapfile -t CHAPTERS < <(echo "$HTML" | grep -oP 'reader_v2\.php\?chapter=\K[^"]+' | sort -u)

  if [ ${#CHAPTERS[@]} -eq 0 ]; then
    echo "❌ No se encontraron capítulos"
    exit 1
  fi

  echo ""
  echo "📖 Capítulos encontrados:"
  echo ""

  for i in "${!CHAPTERS[@]}"; do
    echo "[$i] Capítulo ${CHAPTERS[$i]}"
  done

  echo ""
  read -p "👉 Elige un número: " INDEX

  read -p "📥 ¿Descargar todos los capítulos? (y/n): " ALL

  if [ "$ALL" = "y" ]; then
    for ch in "${CHAPTERS[@]}"; do
      echo "🚀 Descargando capítulo $ch"
      ./manga-cli.sh "https://www.yupmanga.com/reader_v2.php?chapter=$ch"
    done
    exit
  fi

  CHAPTER_SELECTED=${CHAPTERS[$INDEX]}

  if [ -z "$CHAPTER_SELECTED" ]; then
    echo "❌ Selección inválida"
    exit 1
  fi

  URL="https://www.yupmanga.com/reader_v2.php?chapter=$CHAPTER_SELECTED"

  echo ""
  echo "🚀 Cargando capítulo..."
  sleep 1
fi

# =========================================================
# 🧠 MODO LOCAL
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
# 🌐 yupmanga PRO
# =========================================================

if [ "$TIPO" = "yupmanga" ]; then
  echo "🌐 yupmanga PRO..."

  rm -f "$COOKIE_JAR"

  CHAPTER=$(echo "$URL" | grep -oP 'chapter=\K[^&]+')
  TOKEN=$(echo "$URL" | grep -oP 'token=\K[^&]+')

  if [ -z "$CHAPTER" ]; then
    echo "❌ URL inválida (sin chapter)"
    exit 1
  fi

  READER_URL="https://www.yupmanga.com/reader_v2.php?chapter=$CHAPTER"

  curl -s -c "$COOKIE_JAR" \
    -H "User-Agent: Mozilla/5.0" \
    "https://www.yupmanga.com/" > /dev/null

  HTML=$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -H "User-Agent: Mozilla/5.0" \
    -H "Referer: https://www.yupmanga.com/" \
    "$READER_URL")

  if [ -z "$TOKEN" ]; then
    TOKEN=$(echo "$HTML" | grep -oP 'token["'\'']?\s*[:=]\s*["'\'']\K[^"'\'']+')
  fi

  if [ -z "$TOKEN" ]; then
  echo "⚠ Token no encontrado → usando modo navegador..."

  node scraper.js "$URL"

  COUNT=$(ls imgs 2>/dev/null | wc -l)

  if [ "$COUNT" -eq 0 ]; then
    echo "❌ Puppeteer tampoco pudo obtener imágenes"
    exit 1
  fi

    echo "✅ Descargado con Puppeteer ($COUNT imágenes)"
  else

  echo "🔑 Token OK"

  fi

  TOTAL_PAGES=$(echo "$HTML" | grep -oP 'total_pages["'\'']?\s*[:=]\s*\K[0-9]+' | head -n1)

  if [ -z "$TOTAL_PAGES" ]; then
    TOTAL_PAGES=999
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
# 🌍 GENERICO PRO
# =========================================================

if [[ "$URL" =~ mlatz ]]; then
  echo "🧠 Dominio protegido → usando navegador..."

  node scraper.js "$URL" "$CARPETA"

  COUNT=$(ls "$CARPETA" 2>/dev/null | wc -l)

  if [ "$COUNT" -gt 0 ]; then
    echo "✅ Descargado con Puppeteer ($COUNT imágenes)"
    exit 0
  else
    echo "❌ Puppeteer no encontró imágenes"
    exit 1
  fi
fi

if [ "$TIPO" = "generico" ]; then
  echo "🌍 Modo genérico PRO..."

  HTML=$(curl -s -L --compressed -H "User-Agent: Mozilla/5.0" "$URL" | tr -d '\000')

  mapfile -t IMG_URLS < <(echo "$HTML" | grep -oP '(?<=src=["'\''])[^\"]+\.(jpg|jpeg|png|webp)' | sed 's/^\/\//https:\/\//')

  if [ ${#IMG_URLS[@]} -gt 0 ]; then
    echo "🖼 Imágenes encontradas: ${#IMG_URLS[@]}"

    for img in "${IMG_URLS[@]}"; do

  if [ -n "$LIMITE" ] && [ $COUNT -ge $LIMITE ]; then
    break
  fi

  ((COUNT++))
  FILE="$CARPETA/$COUNT.jpg"

  if [[ "$img" =~ ^/ ]]; then
    DOMAIN=$(echo "$URL" | grep -oP '^https?://[^/]+')
    img="$DOMAIN$img"
  fi

  echo "⬇ $img"

  curl -s -L \
    -H "User-Agent: Mozilla/5.0" \
    -H "Referer: $URL" \
    -H "Accept: image/webp,image/*,*/*;q=0.8" \
    "$img" -o "$FILE"

  if ! file "$FILE" | grep -qiE 'image|webp'; then
    echo "⚠ Bloqueado → usando modo navegador..."

    rm -f "$FILE"

    node scraper.js "$URL" "$CARPETA"

    COUNT=$(ls "$CARPETA" | wc -l)

    if [ "$COUNT" -gt 0 ]; then
      break
    else
      ((COUNT--))
    fi
  fi

done

    echo "⚠ Fallback numerico..."

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
fi

# =========================
# VALIDACIÓN
# =========================

if [ -z "$URL" ]; then
  echo "Uso: ./manga-cli.sh <URL|PATH_LOCAL> [LIMITE]"
  exit 1
fi

# =========================
# 🖼 URL DIRECTA A IMAGEN
# =========================

if [[ "$URL" =~ \.(jpg|jpeg|png|webp)$ ]]; then
  echo "🖼 URL directa detectada..."

  EXT="${URL##*.}"
  BASE=$(echo "$URL" | sed -E 's/[0-9]+\.(jpg|jpeg|png|webp)$//')
  NUM=$(basename "$URL" | grep -oE '^[0-9]+')

  if [ -z "$NUM" ]; then
    NUM=1
  fi

  PAD=${#NUM}
  i=$NUM

  mkdir -p "$CARPETA"

  while true; do

    if [ -n "$LIMITE" ] && [ $COUNT -ge $LIMITE ]; then
      break
    fi

    NUM_FORMAT=$(printf "%0${PAD}d" $i)
    FILE="$CARPETA/$NUM_FORMAT.$EXT"

    IMG="$BASE$NUM_FORMAT.$EXT"

    echo "⬇ $IMG"

    curl -s -L \
      -H "User-Agent: Mozilla/5.0" \
      -H "Referer: https://nhentai.net/" \
      "$IMG" -o "$FILE"

    if file "$FILE" | grep -qi 'image'; then
      ((COUNT++))
    else
      rm -f "$FILE"
      break
    fi

    ((i++))
  done

  echo "✅ Total: $COUNT imágenes"
  
fi

# =========================================================
# 📖 LECTOR
# =========================================================

mapfile -t IMGS < <(ls "$CARPETA" | sort -V)
INDEX=0
TOTAL=${#IMGS[@]}

while true; do
    clear
    echo "📖 Página $((INDEX+1)) / $TOTAL"
    echo "[<] siguiente | [>] anterior | [q] salir"
    echo ""

    WIDTH=$(tput cols)
    HEIGHT=$(tput lines)

    chafa -s --size=$(tput cols)x$(tput lines) "$CARPETA/${IMGS[$INDEX]}"

    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
      read -rsn2 key
    fi
    case "$key" in
      "[C") ((INDEX++)) ;; # →
      "[D") ((INDEX--)) ;; # ←
      q) clear; exit ;;
    esac

    if [ $INDEX -lt 0 ]; then INDEX=0; fi
    if [ $INDEX -ge $TOTAL ]; then INDEX=$((TOTAL-1)); fi
done