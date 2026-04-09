🖥️ MANGA CLI

«📖 Lector de manga en la terminal con descarga automática desde URLs de imágenes (nhentai) y visualización en ASCII usando "chafa".»

---

✨ Features

- 🔍 Descarga automática de páginas
- 🌐 Soporte para servidores dinámicos ("i1", "i2", "i3", "i4")
- 🧠 Detección inteligente del servidor correcto
- 🖼️ Soporte para "jpg", "png", "webp"
- ⚡ Límite opcional de páginas
- 📖 Navegación interactiva en CLI
- 📱 Compatible con Termux (Android)
- 🪟 Compatible con Windows (Git Bash / WSL)
- 🐧 Compatible con Linux

---

📦 Requisitos

Necesitas tener instalados:

- "curl"
- "chafa"
- "figlet"
- "file"

---

⚙️ Instalación

📱 Termux

pkg update
pkg install curl chafa figlet file

---

🐧 Linux (Debian/Ubuntu)

sudo apt update
sudo apt install curl chafa figlet file

---

🪟 Windows

Opción 1 (Recomendada)

- Instala Git Bash
- Instala chafa manualmente

Opción 2 (Pro 🔥)

Usa WSL:

sudo apt install curl chafa figlet file

---

🚀 Uso

chmod +x manga_reader_url.sh
./manga_reader_url.sh "<URL_IMAGEN>" [LIMITE]

---

📌 Ejemplo

./manga_reader_url.sh "https://i1.nhentai.net/galleries/792106/1.jpg"

---

🔢 Con límite

./manga_reader_url.sh "https://i1.nhentai.net/galleries/792106/1.jpg" 10

---

🎮 Controles

Tecla| Acción
"d"| Siguiente página
"a"| Página anterior
"q"| Salir

---

🧠 Cómo funciona

1. Detecta automáticamente el servidor correcto ("i1", "i2", etc.)
2. Descarga imágenes secuencialmente
3. Valida que sean imágenes reales
4. Las renderiza en consola usando "chafa"
5. Permite navegar entre páginas

---

⚠️ Notas

- Debes usar una URL directa de imagen, por ejemplo:

https://i1.nhentai.net/galleries/XXXXXX/1.jpg

- No usar URLs incompletas o sin "https"

---

📁 Estructura

manga-cli/
├── manga_reader_url.sh
├── install.sh
├── requirements.txt
└── README.md

---

🔮 Roadmap

- [ ] Soporte directo para "/g/xxxxx/"
- [ ] Descarga paralela
- [ ] Scroll automático tipo manga
- [ ] Caché de imágenes
- [ ] Zoom dinámico

---

🤝 Contribuciones

Pull requests son bienvenidos. Para cambios grandes, abre un issue primero.

---

📜 Licencia

MIT License

---

💀 Autor

Hecho con terminal y café ☕
por Nicolás Álvarez (an0mia)
