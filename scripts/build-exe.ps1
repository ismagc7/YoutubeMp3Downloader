# Genera el instalador .exe para Windows.
# Requisitos: JDK 21+, Maven, WiX Toolset 3.x (https://wixtoolset.org/), curl o Invoke-WebRequest.
# Ejecutar desde la raiz del proyecto: .\scripts\build-exe.ps1

#Requires -Version 5.1
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot)

$AppVersion = "1.0.0"
$AppName    = "YouTube MP3 Downloader"
$Staging    = "target\package-input"
$Dist       = "target\dist"

Write-Host "==> Compilando JAR..."
mvn package -DskipTests -q

Write-Host "==> Preparando directorio de staging..."
Remove-Item -Recurse -Force $Staging -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $Staging, $Dist | Out-Null
Copy-Item "target\ytmp3.jar" "$Staging\ytmp3.jar" -Force

Write-Host "==> Descargando yt-dlp (Windows)..."
Invoke-WebRequest `
    -Uri "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" `
    -OutFile "$Staging\yt-dlp.exe"

Write-Host "==> Descargando ffmpeg (Windows)..."
$FfmpegZip     = "target\ffmpeg.zip"
$FfmpegExtract = "target\ffmpeg-extract"
Invoke-WebRequest `
    -Uri "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-lgpl.zip" `
    -OutFile $FfmpegZip
Expand-Archive -Path $FfmpegZip -DestinationPath $FfmpegExtract -Force
$FfmpegExe = Get-ChildItem $FfmpegExtract -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1
Copy-Item $FfmpegExe.FullName "$Staging\ffmpeg.exe" -Force

Write-Host "==> Generando instalador .exe con jpackage..."
jpackage `
    --type exe `
    --name $AppName `
    --app-version $AppVersion `
    --vendor "YouTube MP3 Downloader" `
    --input $Staging `
    --main-jar ytmp3.jar `
    --dest $Dist `
    --win-shortcut `
    --win-menu `
    --win-dir-chooser `
    --java-options "-Dytdlp.path=`$APPDIR/yt-dlp.exe" `
    --java-options "-Dffmpeg.path=`$APPDIR/ffmpeg.exe" `
    --java-options "-Xms128m" `
    --java-options "-Xmx512m"

Write-Host ""
Write-Host "Instalador generado en $Dist\:"
Get-ChildItem "$Dist\*.exe"
Write-Host ""
Write-Host "Instala haciendo doble clic en el .exe o ejecuta como administrador."
