package com.example.ytmp3.controller;

import com.example.ytmp3.service.YoutubeDownloadService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

import java.io.InputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;

@Controller
public class DownloadController {

    private final YoutubeDownloadService downloadService;

    public DownloadController(YoutubeDownloadService downloadService) {
        this.downloadService = downloadService;
    }

    @GetMapping("/")
    public String index() {
        return "index";
    }

    @PostMapping("/download")
    public ResponseEntity<StreamingResponseBody> download(@RequestParam String url) throws Exception {
        Path mp3File = downloadService.downloadAsMp3(url);
        String filename = mp3File.getFileName().toString();

        String asciiName = filename.replaceAll("[^\\x20-\\x7E]", "_");
        String encodedName = URLEncoder.encode(filename, StandardCharsets.UTF_8).replace("+", "%20");
        String contentDisposition = "attachment; filename=\"" + asciiName + "\"; filename*=UTF-8''" + encodedName;

        StreamingResponseBody body = outputStream -> {
            try (InputStream is = Files.newInputStream(mp3File)) {
                is.transferTo(outputStream);
            } finally {
                downloadService.deleteDirectory(mp3File.getParent());
            }
        };

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, contentDisposition)
                .contentType(MediaType.parseMediaType("audio/mpeg"))
                .body(body);
    }

    @ExceptionHandler(Exception.class)
    @ResponseBody
    public ResponseEntity<Map<String, String>> handleError(Exception e) {
        return ResponseEntity.badRequest()
                .contentType(MediaType.APPLICATION_JSON)
                .body(Map.of("error", e.getMessage()));
    }
}
