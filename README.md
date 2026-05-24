# YouTube MP3 Downloader

Aplicación que convierte vídeos de YouTube a audio MP3. Soporta dos modos de uso:

- **Modo escritorio** — abre una ventana nativa con JavaFX WebView (por defecto al instalar el `.deb` o ejecutar con pantalla disponible)
- **Modo web** — arranca un servidor HTTP en `localhost:8080` accesible desde cualquier navegador (flag `--web` o entornos sin pantalla)

Construida con **Java 21**, **Spring Boot 3**, **Thymeleaf** y **JavaFX**. Utiliza [yt-dlp](https://github.com/yt-dlp/yt-dlp) y [ffmpeg](https://ffmpeg.org/) para la extracción y conversión del audio.

---

## Características

- **Ventana de escritorio nativa** (JavaFX WebView) al lanzar desde el instalador `.deb`
- **Servidor web** accesible en cualquier navegador con el flag `--web`
- Detecta automáticamente si ya hay una instancia en ejecución y se conecta a ella
- Conversión a MP3 con la máxima calidad disponible
- Descarga directa sin almacenamiento en servidor (los ficheros temporales se eliminan tras enviarse)
- Sin registro ni cuenta requerida

---

## Requisitos previos

### Para ejecutar desde el instalador
- **Linux (.deb):** Debian / Ubuntu 20.04 o superior (`libgtk-3-0`, `libwebkit2gtk` y `ffmpeg` se instalan automáticamente)
- **Windows (.exe):** Windows 10 / 11

### Para compilar desde el código fuente
- JDK 21+
- Maven 3.9+
- `yt-dlp` instalado y accesible
- `ffmpeg` instalado y accesible

### Para ejecutar en modo escritorio (desde el código fuente)
Además de lo anterior, se requieren las librerías de sistema para JavaFX:
```bash
sudo apt install libgtk-3-0 libwebkit2gtk-4.0-37 libgl1
```

---

## Instalación

### Opción 1 — Paquete `.deb` (Linux)

```bash
sudo apt install ./youtube-mp3-downloader_1.0.0_amd64.deb
```

El paquete instala automáticamente `ffmpeg`, `libgtk-3-0` y `libwebkit2gtk` como dependencias, y deja `yt-dlp` bundleado. Al abrirlo se muestra una **ventana de escritorio nativa** con la aplicación embebida.

### Opción 2 — Instalador `.exe` (Windows)

Ejecuta el fichero `YouTube MP3 Downloader-1.0.0.exe` como administrador y sigue el asistente.

Incluye `yt-dlp.exe` y `ffmpeg.exe` bundleados. No requiere instalar nada más.

### Opción 3 — Docker

```bash
make docker-build
make docker-run
```

---

## Makefile

El proyecto incluye un `Makefile` para simplificar las operaciones más comunes. Ejecuta `make` sin argumentos para ver la ayuda.

| Comando | Descripción |
|---|---|
| `make run` | Arranca en **modo escritorio** (ventana JavaFX, requiere pantalla) |
| `make run-web` | Arranca en **modo web** — solo servidor HTTP en `localhost:8080` |
| `make build` | Genera `target/ytmp3.jar` sin ejecutar tests |
| `make deb` | Genera el paquete `.deb` (solo Linux, requiere JDK 21+) |
| `make install-deb` | Instala el `.deb` generado |
| `make exe` | Genera el instalador `.exe` (solo Windows, requiere WiX 3) |
| `make docker-build` | Construye la imagen Docker `ytmp3` |
| `make docker-run` | Arranca el contenedor en `http://localhost:8080` |
| `make docker-stop` | Detiene y elimina el contenedor |
| `make clean` | Elimina todos los artefactos de compilación |

---

## Compilación desde el código fuente

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd Youtubemp3downloader
```

### 2. Instalar dependencias del sistema

**Linux (Debian/Ubuntu):**
```bash
sudo apt install ffmpeg
curl -sL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux \
     -o ~/.local/bin/yt-dlp && chmod +x ~/.local/bin/yt-dlp
```

**Windows (PowerShell):**
```powershell
winget install yt-dlp.yt-dlp
winget install Gyan.FFmpeg
```

### 3. Compilar el JAR

```bash
make build
```

El resultado queda en `target/ytmp3.jar`.

### 4. Generar instaladores nativos

**Paquete `.deb` (ejecutar en Linux):**
```bash
make deb
```
> Requiere `dpkg` (preinstalado en Debian/Ubuntu) y JDK 21+.

**Instalador `.exe` (ejecutar en Windows con PowerShell):**
```powershell
make exe
```
> Requiere [WiX Toolset 3.x](https://wixtoolset.org/) instalado.

Los artefactos generados se encuentran en `target/dist/`.

---

## Ejecución

La aplicación detecta automáticamente el modo según el entorno:
- Con pantalla disponible (`DISPLAY` / `WAYLAND_DISPLAY`) → **modo escritorio** (ventana JavaFX)
- Sin pantalla o con flag `--web` → **modo web** (solo servidor HTTP)

### Modo escritorio (ventana JavaFX)

```bash
make run
# o directamente:
java -jar target/ytmp3.jar
```

Se abre una ventana nativa con la aplicación embebida. Al cerrar la ventana se detiene el servidor.

### Modo web (solo servidor HTTP)

```bash
make run-web
# o directamente:
java -jar target/ytmp3.jar --web
```

Abre el navegador en **http://localhost:8080**. Útil en servidores, Docker o entornos sin pantalla.

### Variables de entorno opcionales

| Variable | Descripción | Valor por defecto |
|---|---|---|
| `YTDLP_PATH` | Ruta al ejecutable de yt-dlp | `~/.local/bin/yt-dlp` |
| `FFMPEG_PATH` | Ruta al ejecutable de ffmpeg | *(buscado en PATH)* |
| `SERVER_PORT` | Puerto del servidor web | `8080` |

Ejemplo:
```bash
YTDLP_PATH=/usr/local/bin/yt-dlp SERVER_PORT=9090 java -jar target/ytmp3.jar
```

---

## Estructura del proyecto

```
├── Dockerfile
├── Makefile
├── scripts/
│   ├── build-deb.sh              # Genera el paquete .deb
│   └── build-exe.ps1             # Genera el instalador .exe
└── src/main/
    ├── java/com/ismagc7/ytmp3/
    │   ├── Main.java             # Punto de entrada (detecta modo escritorio/web)
    │   ├── YtMp3Application.java # Configuración Spring Boot
    │   ├── desktop/
    │   │   └── DesktopApp.java   # Ventana JavaFX con WebView embebido
    │   ├── controller/DownloadController.java
    │   └── service/YoutubeDownloadService.java
    └── resources/
        ├── application.properties
        └── templates/index.html
```

---

## Aviso legal

> **Este software se proporciona únicamente con fines educativos y de uso personal.**
>
> El autor **no se hace responsable** del uso que se haga de esta herramienta. La descarga de contenido protegido por derechos de autor sin la autorización expresa del titular es ilegal en la mayoría de jurisdicciones. El usuario es el único responsable de asegurarse de que su uso cumple con la legislación aplicable y con los [Términos de Servicio de YouTube](https://www.youtube.com/static?template=terms).
>
> Úsalo solo con contenido del que tengas los derechos o que esté bajo licencias que lo permitan (Creative Commons, dominio público, etc.).
