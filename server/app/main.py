# SpeakAndTranslate Server Launcher
#
# Server initialization script for the translation and speech API service. # Server-Initialisierungsskript für den Übersetzungs- und Sprach-API-Dienst.
# Configures logging, environment, directories, and starts the Uvicorn server. # Konfiguriert Protokollierung, Umgebung, Verzeichnisse und startet den Uvicorn-Server.
#
# Usage:
# python main.py  # Starts the server with default settings. # Startet den Server mit Standardeinstellungen.
# PORT=9000 python main.py  # Starts the server on a custom port. # Startet den Server auf einem benutzerdefinierten Port.
#
# EN: Sets up and launches the FastAPI server for the translation application with proper configuration and error handling.
# DE: Richtet den FastAPI-Server für die Übersetzungsanwendung ein und startet ihn mit korrekter Konfiguration und Fehlerbehandlung.

import uvicorn # Imports the ASGI server implementation for FastAPI. # Importiert die ASGI-Server-Implementierung für FastAPI.
from app.infrastructure.api.routes import app # Imports the FastAPI application from routes module. # Importiert die FastAPI-Anwendung aus dem Routes-Modul.
import os # Imports operating system interfaces for environment and file operations. # Importiert Betriebssystemschnittstellen für Umgebungs- und Dateioperationen.
import logging # Imports logging functionality for application monitoring. # Importiert Protokollierungsfunktionalität für Anwendungsüberwachung.
from datetime import datetime # Imports datetime for timestamp handling. # Importiert datetime für die Verarbeitung von Zeitstempeln.

# Configure logging first to capture all events
logging.basicConfig( # Configures the logging system for the application. # Konfiguriert das Protokollierungssystem für die Anwendung.
    level=logging.DEBUG, # Sets logging level to capture all messages including debug information. # Setzt die Protokollierungsstufe, um alle Nachrichten einschließlich Debug-Informationen zu erfassen.
    format='%(asctime)s.%(msecs)03d - %(name)s - %(levelname)s - %(message)s', # Defines log message format with millisecond precision. # Definiert das Format der Protokollnachrichten mit Millisekundengenauigkeit.
    datefmt='%Y-%m-%d %H:%M:%S', # Sets the date format for timestamp. # Legt das Datumsformat für den Zeitstempel fest.
    handlers=[ # Configures where logs will be sent. # Konfiguriert, wohin Protokolle gesendet werden.
        logging.StreamHandler(), # Sends logs to the console output. # Sendet Protokolle an die Konsolenausgabe.
        logging.FileHandler("api.log") # Saves logs to the api.log file. # Speichert Protokolle in der Datei api.log.
    ],
    force=True # Forces reconfiguration of the root logger. # Erzwingt die Neukonfiguration des Root-Loggers.
)
logger = logging.getLogger(__name__) # Creates a logger instance for this module. # Erstellt eine Logger-Instanz für dieses Modul.

if __name__ == "__main__": # Checks if this script is being run directly. # Prüft, ob dieses Skript direkt ausgeführt wird.
    # Log initialization details
    logger.info("🔧 Initializing SpeakAndTranslate Azure Server") # Logs server initialization with an emoji indicator. # Protokolliert Server-Initialisierung mit einem Emoji-Indikator.
    logger.debug(f"Python version: {os.sys.version}") # Logs Python version for debugging. # Protokolliert Python-Version zur Fehlersuche.
    logger.debug(f"Current working directory: {os.getcwd()}") # Logs current working directory for path references. # Protokolliert aktuelles Arbeitsverzeichnis für Pfadreferenzen.
    logger.debug(f"Environment variables: {dict(os.environ)}") # Logs all environment variables for configuration validation. # Protokolliert alle Umgebungsvariablen zur Konfigurationsvalidierung.

    # Create audio directory with proper permissions
    audio_dir = "/tmp/tts_audio" if os.name != "nt" else os.path.join( # Sets audio directory path based on operating system. # Legt den Audio-Verzeichnispfad basierend auf dem Betriebssystem fest.
        os.environ.get("TEMP", ""), "tts_audio" # Gets system temp directory or uses empty string if not found. # Holt das System-Temp-Verzeichnis oder verwendet einen leeren String, wenn nicht gefunden.
    )
    
    try: # Begins try block for directory creation operations. # Beginnt einen Try-Block für Verzeichniserstellungsoperationen.
        os.makedirs(audio_dir, exist_ok=True) # Creates audio directory and parent directories if they don't exist. # Erstellt Audio-Verzeichnis und übergeordnete Verzeichnisse, falls sie nicht existieren.
        os.chmod(audio_dir, 0o755) # Sets directory permissions to readable and executable by all users. # Setzt Verzeichnisberechtigungen auf lesbar und ausführbar für alle Benutzer.
        logger.info(f"✅ Created audio directory at {audio_dir}") # Logs successful directory creation. # Protokolliert erfolgreiche Verzeichniserstellung.
        
        
        test_file = os.path.join(audio_dir, "permission_test.txt") # Creates path for test file to verify write permissions. # Erstellt Pfad für Testdatei zur Überprüfung von Schreibberechtigungen.
        with open(test_file, "w") as f: # Opens test file in write mode. # Öffnet Testdatei im Schreibmodus.
            f.write("test") # Writes test content to verify write permissions. # Schreibt Testinhalt zur Überprüfung der Schreibberechtigungen.
        os.remove(test_file) # Removes the test file after successful write test. # Entfernt die Testdatei nach erfolgreichem Schreibtest.
        logger.debug("✅ Verified audio directory write permissions") # Logs successful write permission verification. # Protokolliert erfolgreiche Überprüfung der Schreibberechtigungen.
        
    except Exception as e: # Catches any exceptions during directory setup. # Fängt alle Ausnahmen während der Verzeichniseinrichtung ab.
        logger.critical(f"❌ Failed to create audio directory: {str(e)}") # Logs critical error if directory setup fails. # Protokolliert kritischen Fehler, wenn die Verzeichniseinrichtung fehlschlägt.
        raise # Re-raises exception to stop server launch if directory creation fails. # Wirft Ausnahme erneut, um Serverstart zu stoppen, wenn Verzeichniserstellung fehlschlägt.

    # Configure server parameters
    port = int(os.environ.get("PORT", 8000)) # Gets port from environment variable or uses default 8000. # Holt Port aus Umgebungsvariable oder verwendet Standard 8000.
    host = "0.0.0.0"  # Always bind to all interfaces in container. # Bindet immer an alle Schnittstellen im Container.
    # host = "127.0.0.1", # Commented out localhost-only binding. # Auskommentierte nur-localhost-Bindung.
   
    # Log final configuration
    logger.info("⚙️ Final Configuration:") # Logs section header for final configuration. # Protokolliert Abschnittsüberschrift für endgültige Konfiguration.
    logger.info(f"Host: {host}") # Logs the host address server will bind to. # Protokolliert die Host-Adresse, an die der Server gebunden wird.
    logger.info(f"Port: {port}") # Logs the port server will listen on. # Protokolliert den Port, auf dem der Server hören wird.
    logger.info(f"Azure Speech Key: {'set' if os.getenv('AZURE_SPEECH_KEY') else 'missing'}") # Logs whether Azure Speech API key is configured. # Protokolliert, ob der Azure Speech API-Schlüssel konfiguriert ist.
    logger.info(f"Azure Region: {os.getenv('AZURE_SPEECH_REGION', 'not configured')}") # Logs the Azure region setting. # Protokolliert die Azure-Regionseinstellung.
    logger.info(f"TTS Device: {os.getenv('TTS_DEVICE', 'cpu')}") # Logs the text-to-speech device (CPU/GPU). # Protokolliert das Text-zu-Sprache-Gerät (CPU/GPU).
    logger.info(f"Container Env: {os.getenv('CONTAINER_ENV', 'false')}") # Logs whether running in container environment. # Protokolliert, ob in Container-Umgebung ausgeführt wird.

    # Start the server with detailed UVicorn configuration
    uvicorn.run( # Starts the Uvicorn ASGI server with the FastAPI application. # Startet den Uvicorn ASGI-Server mit der FastAPI-Anwendung.
        app, # The FastAPI application instance. # Die FastAPI-Anwendungsinstanz.
        host=host, # The host address to bind to. # Die Host-Adresse, an die gebunden werden soll.
        port=port, # The port to listen on. # Der Port, auf dem gehört werden soll.
        proxy_headers=True, # Enables processing of proxy headers like X-Forwarded-For. # Aktiviert die Verarbeitung von Proxy-Headern wie X-Forwarded-For.
        forwarded_allow_ips="*", # Trusts forwarded headers from all IPs for proxy setups. # Vertraut Forward-Headern von allen IPs für Proxy-Setups.
        log_config=None, # Disables Uvicorn's internal logging to use the application's logging. # Deaktiviert Uvicorns interne Protokollierung, um die Protokollierung der Anwendung zu verwenden.
        access_log=False, # Disables access logging to reduce noise. # Deaktiviert Zugriffsprotokollierung, um Rauschen zu reduzieren.
        server_header=False, # Disables the Server header in responses for security. # Deaktiviert den Server-Header in Antworten für Sicherheit.
        date_header=False, # Disables the Date header in responses. # Deaktiviert den Datums-Header in Antworten.
        timeout_keep_alive=300, # Sets keep-alive timeout to 5 minutes for long-running connections. # Setzt Keep-Alive-Timeout auf 5 Minuten für langlebige Verbindungen.
        log_level="debug" if os.getenv("DEBUG_MODE") else "info" # Sets log level based on DEBUG_MODE environment variable. # Setzt Protokollierungsstufe basierend auf DEBUG_MODE-Umgebungsvariable.
    )
