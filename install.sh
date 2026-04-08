#!/bin/bash

echo "🔧 Instalando dependencias..."

# Detectar sistema
if [[ "$OSTYPE" == "linux-android"* ]]; then
    echo "📱 Detectado Termux"
    pkg update -y
    pkg install -y curl chafa figlet file

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Linux"
    sudo apt update
    sudo apt install -y curl chafa figlet file

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

echo "✅ Listo"
