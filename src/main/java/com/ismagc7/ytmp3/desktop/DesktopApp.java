package com.ismagc7.ytmp3.desktop;

import com.ismagc7.ytmp3.YtMp3Application;
import javafx.application.Application;
import javafx.application.Platform;
import javafx.concurrent.Worker;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressIndicator;
import javafx.scene.image.Image;
import javafx.scene.layout.StackPane;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.scene.web.WebView;
import javafx.stage.Stage;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ConfigurableApplicationContext;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;

public class DesktopApp extends Application {

    private ConfigurableApplicationContext springContext;
    private boolean alreadyRunning = false;
    private int port = 8080;

    @Override
    public void init() throws Exception {
        // Comprobar si el servidor ya está corriendo
        if (isServerRunning()) {
            alreadyRunning = true;
            return;
        }
        String[] args = getParameters().getRaw().toArray(new String[0]);
        springContext = SpringApplication.run(YtMp3Application.class, args);
        port = springContext.getEnvironment()
                .getProperty("server.port", Integer.class, 8080);

        // Esperar a que el servidor esté listo
        waitForServer();
    }

    @Override
    public void start(Stage stage) {
        WebView webView = new WebView();
        webView.getEngine().setJavaScriptEnabled(true);

        // Pantalla de carga mientras WebView inicializa
        ProgressIndicator spinner = new ProgressIndicator();
        spinner.setMaxSize(60, 60);
        Label loadingLabel = new Label("Iniciando...");
        loadingLabel.setStyle("-fx-text-fill: white; -fx-font-size: 14px;");
        VBox loadingBox = new VBox(12, spinner, loadingLabel);
        loadingBox.setAlignment(javafx.geometry.Pos.CENTER);
        loadingBox.setStyle("-fx-background-color: #1a1a2e;");

        StackPane root = new StackPane(loadingBox, webView);
        webView.setVisible(false);

        // Mostrar WebView cuando cargue
        webView.getEngine().getLoadWorker().stateProperty().addListener((obs, old, state) -> {
            if (state == Worker.State.SUCCEEDED) {
                webView.setVisible(true);
                loadingBox.setVisible(false);
            }
        });

        webView.getEngine().load("http://localhost:" + port);

        Scene scene = new Scene(root, 900, 660);
        scene.setFill(Color.web("#1a1a2e"));

        stage.setTitle("YouTube MP3 Downloader");
        stage.setScene(scene);
        stage.setMinWidth(560);
        stage.setMinHeight(480);
        stage.setOnCloseRequest(e -> shutdown());
        loadIcon(stage);
        // Nombre de aplicación para que el DE asocie el icono del .desktop correctamente
        stage.getProperties().put("x.window.class", "youtube-mp3-downloader");
        stage.show();
    }

    @Override
    public void stop() {
        shutdown();
    }

    private void loadIcon(Stage stage) {
        try (var stream = getClass().getResourceAsStream("/icon.png")) {
            if (stream != null) {
                stage.getIcons().add(new Image(stream));
            }
        } catch (Exception ignored) {
        }
    }

    private void shutdown() {
        if (springContext != null && springContext.isRunning()) {
            springContext.close();
        }
        Platform.exit();
    }

    private boolean isServerRunning() {
        try {
            HttpURLConnection conn = (HttpURLConnection)
                    new URL("http://localhost:" + port).openConnection();
            conn.setConnectTimeout(500);
            conn.connect();
            conn.disconnect();
            return true;
        } catch (IOException e) {
            return false;
        }
    }

    private void waitForServer() throws InterruptedException {
        for (int i = 0; i < 30; i++) {
            if (isServerRunning()) return;
            Thread.sleep(1000);
        }
    }
}
