#!/usr/bin/env bash
# Genera el paquete .deb para Linux (Debian/Ubuntu).
# Requisitos: JDK 21+, Maven, dpkg (preinstalado en Debian/Ubuntu), curl.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_VERSION="1.0.0"
APP_NAME="youtube-mp3-downloader"
STAGING="target/package-input"
DIST="target/dist"

echo "==> Compilando JAR..."
mvn package -DskipTests -q

echo "==> Preparando directorio de staging..."
rm -rf "$STAGING"
mkdir -p "$STAGING" "$DIST"
cp target/ytmp3.jar "$STAGING/ytmp3.jar"

echo "==> Descargando yt-dlp (Linux standalone)..."
curl -sL "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux" \
     -o "$STAGING/yt-dlp"
chmod +x "$STAGING/yt-dlp"

echo "==> Generando paquete .deb con jpackage..."
jpackage \
  --type deb \
  --name "$APP_NAME" \
  --app-version "$APP_VERSION" \
  --vendor "YouTube MP3 Downloader" \
  --input "$STAGING" \
  --main-jar ytmp3.jar \
  --dest "$DIST" \
  --linux-shortcut \
  --linux-menu-group "Multimedia" \
  --linux-deb-depends ffmpeg \
  --java-options "-Dytdlp.path=\$APPDIR/yt-dlp" \
  --java-options "-Xms128m" \
  --java-options "-Xmx512m"

echo ""
echo "Paquete generado en $DIST/:"
ls "$DIST"/*.deb
echo ""
echo "Para instalar:"
echo "  sudo apt install ./$DIST/*.deb"
