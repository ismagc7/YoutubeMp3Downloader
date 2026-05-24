package com.ismagc7.ytmp3;

import com.ismagc7.ytmp3.desktop.DesktopApp;
import javafx.application.Application;
import org.springframework.boot.SpringApplication;

import java.util.Arrays;

/**
 * Punto de entrada de la aplicación.
 *
 * Modos de ejecución:
 *   - Sin argumentos o con display disponible → abre ventana JavaFX (modo escritorio)
 *   - Con flag --web                          → solo servidor HTTP en puerto 8080
 */
public class Main {

    public static void main(String[] args) {
        // Nombre de clase de ventana para integración con el escritorio Linux
        System.setProperty("javafx.application.name", "youtube-mp3-downloader");
        if (isWebMode(args)) {
            SpringApplication.run(YtMp3Application.class, args);
        } else {
            Application.launch(DesktopApp.class, args);
        }
    }

    private static boolean isWebMode(String[] args) {
        if (Arrays.asList(args).contains("--web")) {
            return true;
        }
        // Sin pantalla disponible (servidor headless) → modo web automáticamente
        boolean noDisplay = System.getenv("DISPLAY") == null
                && System.getenv("WAYLAND_DISPLAY") == null;
        return noDisplay;
    }
}
