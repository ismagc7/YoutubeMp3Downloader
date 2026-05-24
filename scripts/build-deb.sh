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
ICON_PATH="src/main/resources/icon.png"
ICON_ARG=""
if [ -f "$ICON_PATH" ]; then
  echo "    Usando icono: $ICON_PATH"
  ICON_ARG="--icon $ICON_PATH"
else
  echo "    Sin icono personalizado (coloca un PNG 512x512 en $ICON_PATH para usarlo)"
fi

# shellcheck disable=SC2086
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
  $ICON_ARG \
  --java-options "-Dytdlp.path=\$APPDIR/yt-dlp" \
  --java-options "-Xms128m" \
  --java-options "-Xmx512m" \
  --java-options "--add-opens=javafx.graphics/com.sun.javafx.application=ALL-UNNAMED" \
  --java-options "--add-opens=java.base/java.lang=ALL-UNNAMED"

echo "==> Aplicando post-proceso al paquete .deb..."
DEB_FILE=$(ls "$DIST"/*.deb | head -1)
TMPDIR_DEB=$(mktemp -d)
dpkg-deb -R "$DEB_FILE" "$TMPDIR_DEB"

# Añadir dependencia de ffmpeg en el control
CONTROL="$TMPDIR_DEB/DEBIAN/control"
if grep -q "^Depends:" "$CONTROL"; then
  sed -i 's/^Depends:/Depends: ffmpeg,/' "$CONTROL"
else
  echo "Depends: ffmpeg" >> "$CONTROL"
fi

# Añadir dependencias de sistema para JavaFX (GTK3 + WebKit)
# libwebkit2gtk-4.0-37 en Ubuntu 22.04, libwebkit2gtk-4.1-0 en Ubuntu 24.04
if grep -q "^Depends:" "$CONTROL"; then
  sed -i 's/^Depends:/Depends: libgtk-3-0, libwebkit2gtk-4.0-37 | libwebkit2gtk-4.1-0, libgl1,/' "$CONTROL"
else
  echo "Depends: ffmpeg, libgtk-3-0, libwebkit2gtk-4.0-37 | libwebkit2gtk-4.1-0, libgl1" >> "$CONTROL"
fi

# Corregir el fichero .desktop: nombre legible, StartupWMClass e icono en el tema del sistema
DESKTOP_FILE=$(find "$TMPDIR_DEB/usr/share/applications" -name "*.desktop" 2>/dev/null | head -1)
if [ -n "$DESKTOP_FILE" ]; then
  sed -i 's/^Name=.*/Name=YouTube MP3 Downloader/'           "$DESKTOP_FILE"
  sed -i 's/^Comment=.*/Comment=Convierte vídeos de YouTube a MP3/' "$DESKTOP_FILE"
  # StartupWMClass permite que el DE asocie la ventana abierta con esta entrada
  if ! grep -q "^StartupWMClass=" "$DESKTOP_FILE"; then
    echo "StartupWMClass=youtube-mp3-downloader" >> "$DESKTOP_FILE"
  fi
fi

# Instalar el icono en el tema hicolor para que el centro de aplicaciones lo muestre
if [ -f "$ICON_PATH" ]; then
  ICON_DIR="$TMPDIR_DEB/usr/share/icons/hicolor/512x512/apps"
  mkdir -p "$ICON_DIR"
  cp "$ICON_PATH" "$ICON_DIR/$APP_NAME.png"
fi

# Script post-instalación: actualizar caché de iconos
POSTINST="$TMPDIR_DEB/DEBIAN/postinst"
cat > "$POSTINST" <<'POSTINST_EOF'
#!/bin/sh
set -e
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database /usr/share/applications 2>/dev/null || true
fi
POSTINST_EOF
chmod 755 "$POSTINST"

dpkg-deb -b "$TMPDIR_DEB" "$DEB_FILE"
rm -rf "$TMPDIR_DEB"

DEB_ABS=$(realpath "$DEB_FILE")

echo ""
echo "Paquete generado:"
echo "  $DEB_ABS"
echo ""
echo "Para instalar:"
echo "  sudo dpkg -i \"$DEB_ABS\" && sudo apt-get install -f -y"
