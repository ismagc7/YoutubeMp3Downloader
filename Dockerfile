# ─── Stage 1: Build ───────────────────────────────────────────────────────────
FROM maven:3.9-amazoncorretto-21 AS builder

WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -q

COPY src ./src
RUN mvn package -DskipTests -q

# ─── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-jammy

# Instalar ffmpeg
RUN apt-get update && apt-get install -y --no-install-recommends \
        ffmpeg \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Instalar yt-dlp (binario standalone, sin necesidad de Python)
RUN curl -sL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux \
        -o /usr/local/bin/yt-dlp \
    && chmod +x /usr/local/bin/yt-dlp

# Usuario no-root por seguridad
RUN groupadd -r appuser && useradd -r -g appuser -m appuser

WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
RUN chown appuser:appuser app.jar

USER appuser

ENV YTDLP_PATH=/usr/local/bin/yt-dlp

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
