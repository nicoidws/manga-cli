#!/bin/bash

echo "🔧 Instalando dependencias..."

DEPS=(curl chafa figlet file)

install_apt() {
    sudo apt update
    sudo apt install -y "${DEPS[@]}"
}

install_pacman() {
    sudo pacman -Sy --noconfirm "${DEPS[@]}"
}

install_dnf() {
    sudo dnf install -y "${DEPS[@]}"
}

install_pkg() {
    pkg update
    pkg install -y "${DEPS[@]}"
}

# Detectar sistema
if [[ "$OSTYPE" == "linux-android"* ]]; then
    echo "📱 Detectado Termux"
    install_pkg

elif command -v apt >/dev/null; then
    echo "🐧 Linux (apt)"
    install_apt

elif command -v pacman >/dev/null; then
    echo "🐧 Arch Linux"
    install_pacman

elif command -v dnf >/dev/null; then
    echo "🐧 Fedora"
    install_dnf

elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 macOS"
    echo "👉 Instala con: brew install curl chafa figlet file-formula"

elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win32" ]]; then
    echo "🪟 Windows detectado"
    echo "Instala manualmente:"
    echo "1. Git Bash"
    echo "2. chafa → https://hpjansson.org/chafa/"
    echo "3. curl (ya viene en Git Bash)"
    echo "4. figlet"
    echo "5. file (opcional)"

else
    echo "❌ Sistema no soportado automáticamente"
fi

echo "✅ Instalación finalizada"