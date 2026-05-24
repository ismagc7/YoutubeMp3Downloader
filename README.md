# YouTube MP3 Downloader

Aplicación web local que convierte vídeos de YouTube a audio MP3. Introduce la URL de un vídeo, pulsa el botón y el fichero se descarga directamente en tu navegador.

Construida con **Java 21**, **Spring Boot 3** y **Thymeleaf**. Utiliza [yt-dlp](https://github.com/yt-dlp/yt-dlp) y [ffmpeg](https://ffmpeg.org/) para la extracción y conversión del audio.

---

## Características

- Interfaz web limpia accesible desde cualquier navegador
- Conversión a MP3 con la máxima calidad disponible
- Descarga directa sin almacenamiento en servidor (los ficheros temporales se eliminan tras enviarse)
- Sin registro ni cuenta requerida

---

## Requisitos previos

### Para ejecutar desde el instalador
- **Linux (.deb):** Debian / Ubuntu 20.04 o superior
- **Windows (.exe):** Windows 10 / 11

### Para compilar desde el código fuente
- JDK 21+
- Maven 3.9+
- `yt-dlp` instalado y accesible
- `ffmpeg` instalado y accesible

---

## Instalación

### Opción 1 — Paquete `.deb` (Linux)

```bash
sudo apt install ./youtube-mp3-downloader_1.0.0_amd64.deb
```

El paquete instala automáticamente `ffmpeg` como dependencia y deja `yt-dlp` bundleado en el directorio de la aplicación.

### Opción 2 — Instalador `.exe` (Windows)

Ejecuta el fichero `YouTube MP3 Downloader-1.0.0.exe` como administrador y sigue el asistente.

Incluye `yt-dlp.exe` y `ffmpeg.exe` bundleados. No requiere instalar nada más.

### Opción 3 — Docker

```bash
docker build -t ytmp3 .
docker run -p 8080:8080 ytmp3
```

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
mvn package -DskipTests
```

El resultado queda en `target/ytmp3.jar`.

### 4. Generar instaladores nativos

**Paquete `.deb` (ejecutar en Linux):**
```bash
./scripts/build-deb.sh
```
> Requiere `dpkg` (preinstalado en Debian/Ubuntu) y JDK 21+.

**Instalador `.exe` (ejecutar en Windows con PowerShell):**
```powershell
.\scripts\build-exe.ps1
```
> Requiere [WiX Toolset 3.x](https://wixtoolset.org/) instalado.

Los artefactos generados se encuentran en `target/dist/`.

---

## Ejecución

### Desde el JAR

```bash
mvn spring-boot:run
```

o bien, si ya tienes el JAR compilado:

```bash
java -jar target/ytmp3.jar
```

Abre el navegador en **http://localhost:8080**.

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
├── scripts/
│   ├── build-deb.sh        # Genera el paquete .deb
│   └── build-exe.ps1       # Genera el instalador .exe
└── src/main/
    ├── java/com/example/ytmp3/
    │   ├── YtMp3Application.java
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
