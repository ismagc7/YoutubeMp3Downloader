package com.example.ytmp3.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Service
public class YoutubeDownloadService {

  @Value("${ytdlp.path:/usr/local/bin/yt-dlp}")
  private String ytDlpPath;

  private Path tempDir;

  @PostConstruct
  public void init() throws IOException {
    this.tempDir = Path.of(System.getProperty("java.io.tmpdir"), "ytmp3");
    Files.createDirectories(this.tempDir);
  }

  public Path downloadAsMp3(String url) throws Exception {
    validateUrl(url);

    Path downloadDir = tempDir.resolve(UUID.randomUUID().toString());
    Files.createDirectories(downloadDir);

    String outputTemplate = downloadDir + "/%(title)s.%(ext)s";

    ProcessBuilder pb =
        new ProcessBuilder(
            ytDlpPath,
            "-x",
            "--audio-format",
            "mp3",
            "--audio-quality",
            "0",
            "--no-playlist",
            "--no-warnings",
            "-o",
            outputTemplate,
            url);
    pb.redirectErrorStream(true);

    Process process = pb.start();
    String output = new String(process.getInputStream().readAllBytes());

    boolean finished = process.waitFor(10, TimeUnit.MINUTES);
    if (!finished) {
      process.destroyForcibly();
      deleteDirectory(downloadDir);
      throw new RuntimeException("El proceso superó el tiempo máximo de espera.");
    }

    int exitCode = process.exitValue();
    if (exitCode != 0) {
      deleteDirectory(downloadDir);
      String errorMsg = extractUserFriendlyError(output);
      throw new RuntimeException(errorMsg);
    }

    List<Path> mp3Files;
    try (var stream = Files.walk(downloadDir, 1)) {
      mp3Files = stream.filter(p -> p.toString().endsWith(".mp3")).toList();
    }

    if (mp3Files.isEmpty()) {
      deleteDirectory(downloadDir);
      throw new RuntimeException("No se encontró el archivo MP3 tras la conversión.");
    }

    return mp3Files.getFirst();
  }

  private void validateUrl(String url) {
    if (url == null || url.isBlank()) {
      throw new IllegalArgumentException("La URL no puede estar vacía.");
    }
    if (!url.contains("youtube.com/") && !url.contains("youtu.be/")) {
      throw new IllegalArgumentException("La URL debe ser de YouTube (youtube.com o youtu.be).");
    }
  }

  private String extractUserFriendlyError(String output) {
    if (output.contains("Video unavailable")) {
      return "El vídeo no está disponible o es privado.";
    }
    if (output.contains("is not a valid URL")) {
      return "La URL introducida no es válida.";
    }
    if (output.contains("Sign in to confirm your age")) {
      return "El vídeo requiere verificación de edad.";
    }
    if (output.contains("copyright")) {
      return "El vídeo no está disponible por derechos de autor.";
    }
    return "Error al procesar el vídeo. Comprueba que la URL es correcta.";
  }

  public void deleteDirectory(Path dir) {
    try (var stream = Files.walk(dir)) {
      stream
          .sorted(Comparator.reverseOrder())
          .forEach(
              p -> {
                try {
                  Files.delete(p);
                } catch (IOException ignored) {
                }
              });
    } catch (IOException ignored) {
    }
  }
}