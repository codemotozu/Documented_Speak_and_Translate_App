# Dockerfile for SpeakAndTranslate Application
#
# A container configuration for deploying the translation and speech API service. # Eine Container-Konfiguration für die Bereitstellung des Übersetzungs- und Sprach-API-Dienstes.
# Sets up a Python environment with all necessary audio and speech processing dependencies. # Richtet eine Python-Umgebung mit allen notwendigen Audio- und Sprachverarbeitungsabhängigkeiten ein.
#
# Usage:
# docker build -t speakandtranslate . # Builds the container image. # Erstellt das Container-Image.
# docker run -p 8000:8000 -e AZURE_SPEECH_KEY=your_key -e AZURE_SPEECH_REGION=your_region speakandtranslate # Runs the container. # Führt den Container aus.
#
# EN: Creates a containerized environment with all system dependencies needed for multilingual speech and translation services.
# DE: Erstellt eine containerisierte Umgebung mit allen Systemabhängigkeiten, die für mehrsprachige Sprach- und Übersetzungsdienste benötigt werden.

FROM python:3.9-slim # Uses Python 3.9 with minimal Debian Linux as the base image. # Verwendet Python 3.9 mit minimalem Debian Linux als Basis-Image.

# Install system dependencies for Azure Speech SDK
RUN apt-get update && apt-get install -y \ # Updates package lists and installs packages with automatic yes to prompts. # Aktualisiert Paketlisten und installiert Pakete mit automatischem Ja zu Aufforderungen.
    build-essential \ # Installs compiler and build tools for native extensions. # Installiert Compiler und Build-Tools für native Erweiterungen.
    libssl-dev \ # Installs OpenSSL development libraries for secure connections. # Installiert OpenSSL-Entwicklungsbibliotheken für sichere Verbindungen.
    ca-certificates \ # Installs certificate authorities for secure communication. # Installiert Zertifizierungsstellen für sichere Kommunikation.
    libasound2 \ # Installs ALSA sound library for audio processing. # Installiert ALSA-Sound-Bibliothek für Audioverarbeitung.
    portaudio19-dev \ # Installs PortAudio development libraries for audio I/O. # Installiert PortAudio-Entwicklungsbibliotheken für Audio-E/A.
    python3-pyaudio \ # Installs Python bindings for PortAudio. # Installiert Python-Anbindungen für PortAudio.
    ffmpeg \ # Installs media processing tools for audio conversion. # Installiert Medienverarbeitungstools für Audiokonvertierung.
    alsa-utils \ # Installs ALSA utilities for audio device management. # Installiert ALSA-Dienstprogramme für die Verwaltung von Audiogeräten.
    libasound2-plugins \ # Installs additional ALSA plugins for audio support. # Installiert zusätzliche ALSA-Plugins für Audio-Unterstützung.
    libsndfile1 \ # Installs library for reading/writing sound files. # Installiert Bibliothek zum Lesen/Schreiben von Sounddateien.
    curl \ # Installs tool for making HTTP requests. # Installiert Tool für HTTP-Anfragen.
    # Additional dependencies for headless audio
    libpulse0 \ # Installs PulseAudio client libraries for audio processing without GUI. # Installiert PulseAudio-Client-Bibliotheken für Audioverarbeitung ohne GUI.
    libnss3 \ # Installs Network Security Services for cryptography. # Installiert Network Security Services für Kryptographie.
    libatk1.0-0 \ # Installs accessibility toolkit for UI-less operation. # Installiert Accessibility-Toolkit für Betrieb ohne Benutzeroberfläche.
    libatk-bridge2.0-0 \ # Installs ATK-Bridge for accessibility interfaces. # Installiert ATK-Bridge für Accessibility-Schnittstellen.
    libcups2 \ # Installs Common UNIX Printing System libraries. # Installiert Common UNIX Printing System-Bibliotheken.
    libgbm1 \ # Installs Mesa Generic Buffer Management for graphics. # Installiert Mesa Generic Buffer Management für Grafik.
    # GStreamer dependencies
    libgstreamer1.0-0 \ # Installs GStreamer core library for multimedia processing. # Installiert GStreamer-Kernbibliothek für Multimedia-Verarbeitung.
    gstreamer1.0-plugins-base \ # Installs essential GStreamer plugins. # Installiert wesentliche GStreamer-Plugins.
    gstreamer1.0-plugins-good \ # Installs high-quality GStreamer plugins. # Installiert hochwertige GStreamer-Plugins.
    gstreamer1.0-plugins-bad \ # Installs less-tested GStreamer plugins. # Installiert weniger getestete GStreamer-Plugins.
    gstreamer1.0-plugins-ugly \ # Installs GStreamer plugins with licensing issues. # Installiert GStreamer-Plugins mit Lizenzproblemen.
    libgstreamer-plugins-base1.0-dev \ # Installs development files for GStreamer plugins. # Installiert Entwicklungsdateien für GStreamer-Plugins.
    # ICU libraries for text processing
    libicu-dev \ # Installs International Components for Unicode libraries for text handling. # Installiert International Components for Unicode-Bibliotheken für Textverarbeitung.
    # Cleanup
    && rm -rf /var/lib/apt/lists/* \ # Removes package lists to reduce image size. # Entfernt Paketlisten, um die Image-Größe zu reduzieren.
    && update-ca-certificates # Updates certificate authorities to ensure secure connections. # Aktualisiert Zertifizierungsstellen, um sichere Verbindungen zu gewährleisten.

WORKDIR /app # Sets the working directory inside the container to /app. # Setzt das Arbeitsverzeichnis innerhalb des Containers auf /app.

# Copy requirements first to leverage Docker cache
COPY requirements.txt . # Copies only the requirements file to leverage Docker's build cache. # Kopiert nur die Requirements-Datei, um Docker's Build-Cache zu nutzen.
RUN pip install --no-cache-dir -r requirements.txt # Installs Python dependencies without caching pip packages. # Installiert Python-Abhängigkeiten ohne Zwischenspeicherung von pip-Paketen.

# Copy the rest of your application
COPY . . # Copies all application files from build context to container's /app directory. # Kopiert alle Anwendungsdateien aus dem Build-Kontext in das /app-Verzeichnis des Containers.

# Create and set permissions for audio directory
RUN mkdir -p /tmp/tts_audio && chmod 777 /tmp/tts_audio # Creates directory for audio files with full permissions for all users. # Erstellt Verzeichnis für Audiodateien mit vollen Berechtigungen für alle Benutzer.

# Set environment variables
ENV PORT=8000 # Sets the default server port to 8000. # Setzt den Standard-Server-Port auf 8000.
ENV TTS_DEVICE=cpu # Configures text-to-speech to use CPU instead of GPU. # Konfiguriert Text-zu-Sprache zur Verwendung der CPU anstelle der GPU.
ENV CONTAINER_ENV=true # Indicates that the application is running in a container environment. # Zeigt an, dass die Anwendung in einer Container-Umgebung läuft.

EXPOSE 8000 # Documents that the container listens on port 8000. # Dokumentiert, dass der Container auf Port 8000 lauscht.

CMD ["python", "-m", "app.main"] # Specifies the command to run when the container starts. # Gibt den Befehl an, der beim Start des Containers ausgeführt wird.
