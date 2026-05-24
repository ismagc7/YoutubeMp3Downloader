.DEFAULT_GOAL := help
IMAGE_NAME    := ytmp3
APP_PORT      := 8080

# ─────────────────────────────────────────────
#  Ayuda
# ─────────────────────────────────────────────
.PHONY: help
help:
	@echo ""
	@echo "YouTube MP3 Downloader — comandos disponibles:"
	@echo ""
	@echo "  make run          Arranca en modo escritorio (JavaFX, requiere pantalla)"
	@echo "  make run-web      Arranca solo el servidor HTTP en puerto $(APP_PORT)"
	@echo "  make build        Genera el JAR en target/ytmp3.jar"
	@echo "  make deb          Genera el paquete .deb  (requiere Linux + JDK 21)"
	@echo "  make install-deb  Instala el paquete .deb generado"
	@echo "  make exe          Genera el instalador .exe (requiere Windows + WiX 3)"
	@echo "  make docker-build Construye la imagen Docker '$(IMAGE_NAME)'"
	@echo "  make docker-run   Arranca el contenedor en el puerto $(APP_PORT)"
	@echo "  make docker-stop  Detiene el contenedor"
	@echo "  make clean        Elimina artefactos de compilacion"
	@echo ""

# ─────────────────────────────────────────────
#  Desarrollo
# ─────────────────────────────────────────────
# Modo escritorio (JavaFX) - requiere pantalla
.PHONY: run
run:
	./mvnw spring-boot:run 2>/dev/null || mvn spring-boot:run

# Modo solo servidor HTTP (sin ventana)
.PHONY: run-web
run-web:
	./mvnw spring-boot:run -Dspring-boot.run.arguments=--web 2>/dev/null || \
	mvn spring-boot:run -Dspring-boot.run.arguments=--web

.PHONY: build
build:
	./mvnw package -DskipTests 2>/dev/null || mvn package -DskipTests
	@echo "JAR generado: target/ytmp3.jar"

# ─────────────────────────────────────────────
#  Instaladores nativos
# ─────────────────────────────────────────────
.PHONY: deb
deb:
	@command -v jpackage >/dev/null 2>&1 || { echo "ERROR: jpackage no encontrado. Instala JDK 21+."; exit 1; }
	@command -v dpkg    >/dev/null 2>&1 || { echo "ERROR: dpkg no encontrado. Este target requiere Linux/Debian."; exit 1; }
	bash scripts/build-deb.sh

.PHONY: install-deb
install-deb:
	@DEB=$$(ls "$(CURDIR)/target/dist/"*.deb 2>/dev/null | head -1); \
	[ -n "$$DEB" ] || { echo "ERROR: no hay .deb en target/dist/. Ejecuta primero 'make deb'."; exit 1; }; \
	sudo dpkg -i "$$DEB"; \
	sudo apt-get install -f -y

.PHONY: exe
exe:
	@echo "AVISO: Este target debe ejecutarse en Windows con PowerShell y WiX Toolset 3.x."
	powershell -ExecutionPolicy Bypass -File scripts/build-exe.ps1

# ─────────────────────────────────────────────
#  Docker
# ─────────────────────────────────────────────
.PHONY: docker-build
docker-build:
	docker build -t $(IMAGE_NAME) .

.PHONY: docker-run
docker-run:
	docker run -d --name $(IMAGE_NAME) -p $(APP_PORT):$(APP_PORT) $(IMAGE_NAME)
	@echo "Aplicacion disponible en http://localhost:$(APP_PORT)"

.PHONY: docker-stop
docker-stop:
	docker stop $(IMAGE_NAME) && docker rm $(IMAGE_NAME)

# ─────────────────────────────────────────────
#  Limpieza
# ─────────────────────────────────────────────
.PHONY: clean
clean:
	./mvnw clean 2>/dev/null || mvn clean
	@echo "Artefactos eliminados."
