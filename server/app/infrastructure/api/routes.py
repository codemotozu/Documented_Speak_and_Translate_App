# Speak and Translate API Server
#
# A FastAPI server that provides endpoints for translation and speech processing. # Ein FastAPI-Server, der Endpunkte für Übersetzung und Sprachverarbeitung bereitstellt.
# Connects the frontend application to translation and speech services. # Verbindet die Frontend-Anwendung mit Übersetzungs- und Sprachdiensten.
#
# Usage:
# uvicorn app.main:app --reload  # Starts the API server with auto-reload for development. # Startet den API-Server mit Auto-Reload für die Entwicklung.
#
# EN: Implements a RESTful API for text translation, speech-to-text, and text-to-speech functionalities.
# DE: Implementiert eine RESTful-API für Textübersetzung, Sprache-zu-Text und Text-zu-Sprache-Funktionalitäten.

import logging # Imports Python's logging module for application logging. # Importiert Pythons Logging-Modul für Anwendungsprotokollierung.
import tempfile # Imports tempfile for creating temporary files. # Importiert tempfile zum Erstellen temporärer Dateien.
import os # Imports operating system interfaces. # Importiert Betriebssystemschnittstellen.
from datetime import datetime # Imports datetime for timestamp handling. # Importiert datetime für die Verarbeitung von Zeitstempeln.
from contextlib import asynccontextmanager # Imports async context manager for managing application lifecycle. # Importiert async-Kontextmanager für die Verwaltung des Anwendungslebenszyklus.
from fastapi import FastAPI, HTTPException, UploadFile, File # Imports FastAPI framework and components. # Importiert FastAPI-Framework und Komponenten.
from fastapi.responses import FileResponse, JSONResponse # Imports FastAPI response types. # Importiert FastAPI-Antworttypen.
from fastapi.middleware.cors import CORSMiddleware # Imports CORS middleware for cross-origin requests. # Importiert CORS-Middleware für ursprungsübergreifende Anfragen.
from pydantic import BaseModel # Imports Pydantic for data validation. # Importiert Pydantic für Datenvalidierung.
from typing import Optional # Imports Optional type for optional fields. # Importiert Optional-Typ für optionale Felder.
from ...application.services.speech_service import SpeechService # Imports SpeechService from application layer. # Importiert SpeechService aus der Anwendungsschicht.
from ...application.services.translation_service import TranslationService # Imports TranslationService from application layer. # Importiert TranslationService aus der Anwendungsschicht.
from ...domain.entities.translation import Translation # Imports Translation entity from domain layer. # Importiert Translation-Entität aus der Domänenschicht.

logging.basicConfig( # Configures the basic logging system. # Konfiguriert das grundlegende Logging-System.
    level=logging.DEBUG, # Sets the logging level to DEBUG. # Setzt die Protokollierungsstufe auf DEBUG.
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', # Sets log message format with timestamp, logger name, level and message. # Setzt das Protokollnachrichtenformat mit Zeitstempel, Logger-Name, Stufe und Nachricht.
    handlers=[ # Configures where logs will be sent. # Konfiguriert, wohin Logs gesendet werden.
        logging.StreamHandler(), # Sends logs to the console. # Sendet Logs an die Konsole.
        logging.FileHandler("api.log") # Sends logs to the api.log file. # Sendet Logs an die Datei api.log.
    ]
)
logger = logging.getLogger(__name__) # Creates a logger instance for this module. # Erstellt eine Logger-Instanz für dieses Modul.

@asynccontextmanager # Decorator that creates an async context manager. # Dekorator, der einen asynchronen Kontextmanager erstellt.
async def lifespan(app: FastAPI): # Function that manages the application lifecycle. # Funktion, die den Anwendungslebenszyklus verwaltet.
    logger.info("Starting API server") # Logs server startup. # Protokolliert Serverstart.
    logger.info(f"Temp directory: {tempfile.gettempdir()}") # Logs the temporary directory location. # Protokolliert den Speicherort des temporären Verzeichnisses.
    logger.info(f"Current working directory: {os.getcwd()}") # Logs the current working directory. # Protokolliert das aktuelle Arbeitsverzeichnis.
    
    yield # Yields control back to FastAPI until shutdown. # Gibt die Kontrolle zurück an FastAPI bis zum Herunterfahren.
    
    logger.info("Shutting down API server") # Logs server shutdown. # Protokolliert Server-Herunterfahren.

app = FastAPI( # Creates a FastAPI application instance. # Erstellt eine FastAPI-Anwendungsinstanz.
    title="Speak and Translate API", # Sets the API title. # Setzt den API-Titel.
    root_path="", # Sets the root path (empty for direct access). # Setzt den Root-Pfad (leer für direkten Zugriff).
    openapi_url="/openapi.json" # Sets the OpenAPI documentation URL. # Setzt die OpenAPI-Dokumentations-URL.
)

app.add_middleware( # Adds middleware to the application. # Fügt Middleware zur Anwendung hinzu.
    CORSMiddleware, # Uses Cross-Origin Resource Sharing middleware. # Verwendet Cross-Origin Resource Sharing Middleware.
    allow_origins=["*"], # Allows all origins to access the API. # Erlaubt allen Ursprüngen den Zugriff auf die API.
    allow_credentials=True, # Allows cookies to be included in cross-origin requests. # Erlaubt, dass Cookies in ursprungsübergreifenden Anfragen enthalten sind.
    allow_methods=["*"], # Allows all HTTP methods (GET, POST, etc.). # Erlaubt alle HTTP-Methoden (GET, POST, usw.).
    allow_headers=["*"], # Allows all headers in requests. # Erlaubt alle Header in Anfragen.
)

translation_service = TranslationService() # Creates a translation service instance. # Erstellt eine Instanz des Übersetzungsdienstes.
speech_service = SpeechService() # Creates a speech service instance. # Erstellt eine Instanz des Sprachdienstes.

class PromptRequest(BaseModel): # Defines the request model for translation requests. # Definiert das Anforderungsmodell für Übersetzungsanfragen.
    text: str # The text to translate (required). # Der zu übersetzende Text (erforderlich).
    source_lang: Optional[str] = "en" # Source language, defaults to English. # Quellsprache, standardmäßig Englisch.
    target_lang: Optional[str] = "en" # Target language, defaults to English. # Zielsprache, standardmäßig Englisch.


@app.get("/health") # Defines a GET endpoint at /health. # Definiert einen GET-Endpunkt unter /health.
async def health_check(): # Defines the health check function. # Definiert die Funktion zur Gesundheitsprüfung.
    """
    Health check endpoint for Azure Container Apps
    Azure expects a 200 response from this endpoint
    """
    audio_dir = "/tmp/tts_audio" if os.name != "nt" else os.path.join(os.environ.get("TEMP", ""), "tts_audio") # Sets audio directory based on operating system. # Legt das Audio-Verzeichnis basierend auf dem Betriebssystem fest.
    try: # Begins try block for directory creation. # Beginnt Try-Block für Verzeichniserstellung.
        os.makedirs(audio_dir, exist_ok=True) # Creates audio directory if it doesn't exist. # Erstellt Audio-Verzeichnis, wenn es nicht existiert.
        os.chmod(audio_dir, 0o755) # Sets directory permissions to readable and executable. # Setzt Verzeichnisberechtigungen auf lesbar und ausführbar.
    except Exception as e: # Catches any exceptions during directory creation. # Fängt alle Ausnahmen während der Verzeichniserstellung ab.
        logger.warning(f"Could not create or set permissions on audio directory: {str(e)}") # Logs warning if directory creation fails. # Protokolliert Warnung, wenn Verzeichniserstellung fehlschlägt.

    env_vars = { # Creates dictionary of environment variables. # Erstellt Wörterbuch mit Umgebungsvariablen.
        "AZURE_SPEECH_KEY": bool(os.environ.get("AZURE_SPEECH_KEY")), # Checks if Azure speech key is set. # Prüft, ob der Azure-Sprachschlüssel gesetzt ist.
        "AZURE_SPEECH_REGION": bool(os.environ.get("AZURE_SPEECH_REGION")), # Checks if Azure speech region is set. # Prüft, ob die Azure-Sprachregion gesetzt ist.
        "GEMINI_API_KEY": bool(os.environ.get("GEMINI_API_KEY")), # Checks if Gemini API key is set. # Prüft, ob der Gemini-API-Schlüssel gesetzt ist.
        "PORT": os.environ.get("PORT", "8000"), # Gets server port or defaults to 8000. # Holt Server-Port oder setzt Standard auf 8000.
        "TTS_DEVICE": os.environ.get("TTS_DEVICE", "cpu"), # Gets TTS device or defaults to CPU. # Holt TTS-Gerät oder setzt Standard auf CPU.
        "CONTAINER_ENV": os.environ.get("CONTAINER_ENV", "false") # Checks if running in container environment. # Prüft, ob in Container-Umgebung ausgeführt wird.
    }

    return { # Returns health check response. # Gibt Gesundheitsprüfungsantwort zurück.
        "status": "healthy", # Indicates the server is healthy. # Zeigt an, dass der Server gesund ist.
        "timestamp": datetime.utcnow().isoformat(), # Includes current UTC time. # Enthält aktuelle UTC-Zeit.
        "temp_dir": tempfile.gettempdir(), # Includes temporary directory path. # Enthält temporären Verzeichnispfad.
        "audio_dir": audio_dir, # Includes audio directory path. # Enthält Audio-Verzeichnispfad.
        "environment_vars": env_vars # Includes environment variable status. # Enthält Umgebungsvariablenstatus.
    }

@app.get("/") # Defines a GET endpoint at the root path. # Definiert einen GET-Endpunkt am Root-Pfad.
async def root(): # Defines the root endpoint function. # Definiert die Root-Endpunkt-Funktion.
    return {"status": "ok from server/app/infrastructure/api/routes.py test 4"} # Returns simple status message. # Gibt einfache Statusmeldung zurück.

@app.post("/api/conversation", response_model=Translation) # Defines a POST endpoint for translations with Translation response model. # Definiert einen POST-Endpunkt für Übersetzungen mit Translation-Antwortmodell.
async def start_conversation(prompt: PromptRequest): # Handles translation requests. # Verarbeitet Übersetzungsanfragen.
    try: # Begins try block for translation processing. # Beginnt Try-Block für Übersetzungsverarbeitung.
        response = await translation_service.process_prompt( # Calls translation service to process the prompt. # Ruft Übersetzungsdienst auf, um die Anfrage zu verarbeiten.
            prompt.text, prompt.source_lang, prompt.target_lang # Passes text and language parameters. # Übergibt Text- und Sprachparameter.
        )
        return response # Returns the translation response. # Gibt die Übersetzungsantwort zurück.
    except Exception as e: # Catches any exceptions during translation. # Fängt alle Ausnahmen während der Übersetzung ab.
        logger.error(f"Conversation error: {str(e)}", exc_info=True) # Logs error with full traceback. # Protokolliert Fehler mit vollständigem Traceback.
        raise HTTPException(status_code=500, detail=str(e)) # Raises HTTP 500 error with exception details. # Wirft HTTP 500-Fehler mit Ausnahmedetails.

@app.post("/api/speech-to-text") # Defines a POST endpoint for speech-to-text conversion. # Definiert einen POST-Endpunkt für Sprache-zu-Text-Umwandlung.
async def speech_to_text(file: UploadFile = File(...)): # Handles file uploads for speech recognition. # Verarbeitet Datei-Uploads für Spracherkennung.
    tmp_path = None # Initializes temporary path variable. # Initialisiert temporäre Pfadvariable.
    try: # Begins try block for file processing. # Beginnt Try-Block für Dateiverarbeitung.
        content_type = file.content_type or "audio/wav" # Gets file content type or defaults to WAV. # Holt Datei-Inhaltstyp oder setzt Standard auf WAV.
        ext = ".wav" # Default file extension. # Standard-Dateierweiterung.
        mime_map = { # Maps MIME types to file extensions. # Ordnet MIME-Typen Dateierweiterungen zu.
            "audio/wav": ".wav", # WAV audio file extension. # WAV-Audiodateierweiterung.
            "audio/aac": ".aac", # AAC audio file extension. # AAC-Audiodateierweiterung.
            "audio/mpeg": ".mp3", # MP3 audio file extension. # MP3-Audiodateierweiterung.
            "audio/ogg": ".ogg" # OGG audio file extension. # OGG-Audiodateierweiterung.
        }
        
        if content_type in mime_map: # Checks if content type is in the MIME map. # Prüft, ob Inhaltstyp in der MIME-Zuordnung ist.
            ext = mime_map[content_type] # Sets extension based on MIME type. # Setzt Erweiterung basierend auf MIME-Typ.
        else: # If MIME type is not recognized. # Wenn MIME-Typ nicht erkannt wird.
            filename_ext = os.path.splitext(file.filename or "")[1].lower() # Gets extension from filename. # Holt Erweiterung aus Dateinamen.
            ext = filename_ext if filename_ext in [".wav", ".aac", ".mp3", ".ogg"] else ".wav" # Uses filename extension if valid, otherwise defaults to WAV. # Verwendet Dateinamen-Erweiterung wenn gültig, sonst Standard WAV.

        with tempfile.NamedTemporaryFile(suffix=ext, delete=False) as tmp: # Creates a temporary file with the correct extension. # Erstellt temporäre Datei mit der richtigen Erweiterung.
            content = await file.read() # Reads uploaded file content. # Liest hochgeladenen Dateiinhalt.
            tmp.write(content) # Writes content to temporary file. # Schreibt Inhalt in temporäre Datei.
            tmp_path = tmp.name # Stores the temporary file path. # Speichert den temporären Dateipfad.
            logger.debug(f"Created temp file: {tmp_path}") # Logs temporary file creation. # Protokolliert Erstellung der temporären Datei.

        recognized_text = await speech_service.process_audio(tmp_path) # Processes audio for speech-to-text. # Verarbeitet Audio für Sprache-zu-Text.
        return {"text": recognized_text} # Returns recognized text. # Gibt erkannten Text zurück.

    except HTTPException as he: # Catches HTTP exceptions. # Fängt HTTP-Ausnahmen ab.
        raise he # Re-raises HTTP exceptions. # Wirft HTTP-Ausnahmen erneut.
    except Exception as e: # Catches other exceptions. # Fängt andere Ausnahmen ab.
        logger.error(f"Speech-to-text error: {str(e)}", exc_info=True) # Logs error with full traceback. # Protokolliert Fehler mit vollständigem Traceback.
        raise HTTPException( # Raises HTTP 500 error. # Wirft HTTP 500-Fehler.
            status_code=500, # Server error status code. # Serverfehlerstatus-Code.
            detail="Audio processing failed. See server logs for details." # Generic error message for client. # Generische Fehlermeldung für Client.
        )
    finally: # Finally block for cleanup. # Finally-Block für Bereinigung.
        if tmp_path and os.path.exists(tmp_path): # Checks if temporary file exists. # Prüft, ob temporäre Datei existiert.
            try: # Tries to delete temporary file. # Versucht, temporäre Datei zu löschen.
                os.unlink(tmp_path) # Deletes the temporary file. # Löscht die temporäre Datei.
                logger.debug(f"Cleaned up temp file: {tmp_path}") # Logs successful cleanup. # Protokolliert erfolgreiche Bereinigung.
            except Exception as e: # Catches cleanup exceptions. # Fängt Bereinigungsausnahmen ab.
                logger.error(f"Final cleanup failed: {str(e)}") # Logs cleanup failure. # Protokolliert Bereinigungsfehler.


@app.post("/api/voice-command") # Defines a POST endpoint for voice command processing. # Definiert einen POST-Endpunkt für Sprachbefehlsverarbeitung.
async def process_voice_command(file: UploadFile = File(...)): # Handles file uploads for voice commands. # Verarbeitet Datei-Uploads für Sprachbefehle.
    tmp_path = None # Initializes temporary path variable. # Initialisiert temporäre Pfadvariable.
    try: # Begins try block for command processing. # Beginnt Try-Block für Befehlsverarbeitung.
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp: # Creates temporary WAV file. # Erstellt temporäre WAV-Datei.
            content = await file.read() # Reads uploaded file content. # Liest hochgeladenen Dateiinhalt.
            tmp.write(content) # Writes content to temporary file. # Schreibt Inhalt in temporäre Datei.
            tmp_path = tmp.name # Stores temporary file path. # Speichert temporären Dateipfad.
            
        command_text = await speech_service.process_command(tmp_path) # Processes audio for command detection. # Verarbeitet Audio für Befehlserkennung.
        return {"command": command_text} # Returns detected command. # Gibt erkannten Befehl zurück.
        
    except Exception as e: # Catches any exceptions. # Fängt alle Ausnahmen ab.
        logger.error(f"Voice command error: {str(e)}", exc_info=True) # Logs error with full traceback. # Protokolliert Fehler mit vollständigem Traceback.
        raise HTTPException( # Raises HTTP 500 error. # Wirft HTTP 500-Fehler.
            status_code=500, # Server error status code. # Serverfehlerstatus-Code.
            detail="Command processing failed" # Error message for client. # Fehlermeldung für Client.
        )
    finally: # Finally block for cleanup. # Finally-Block für Bereinigung.
        if tmp_path and os.path.exists(tmp_path): # Checks if temporary file exists. # Prüft, ob temporäre Datei existiert.
            os.unlink(tmp_path) # Deletes the temporary file. # Löscht die temporäre Datei.


@app.get("/api/audio/{filename}") # Defines a GET endpoint for retrieving audio files. # Definiert einen GET-Endpunkt zum Abrufen von Audiodateien.
async def get_audio(filename: str): # Handles audio file retrieval by filename. # Verarbeitet Audiodateiabruf nach Dateinamen.
    try: # Begins try block for file retrieval. # Beginnt Try-Block für Dateiabruf.
        if ".." in filename or "/" in filename: # Checks for path traversal attempts. # Prüft auf Pfad-Traversal-Versuche.
            raise HTTPException(status_code=400, detail="Invalid filename") # Raises HTTP 400 for invalid filenames. # Wirft HTTP 400 für ungültige Dateinamen.

        audio_dir = os.path.join( # Constructs the audio directory path. # Konstruiert den Audio-Verzeichnispfad.
            os.environ.get("TEMP", ""), # Gets system temp directory. # Holt System-Temp-Verzeichnis.
            "tts_audio" # Audio subdirectory name. # Audio-Unterverzeichnisname.
        ) if os.name == "nt" else "/tmp/tts_audio" # Uses Windows or Unix path format. # Verwendet Windows- oder Unix-Pfadformat.

        file_path = os.path.join(audio_dir, filename) # Builds full path to the audio file. # Erstellt vollständigen Pfad zur Audiodatei.
        
        if not os.path.exists(file_path): # Checks if file exists. # Prüft, ob Datei existiert.
            logger.warning(f"Audio file not found: {file_path}") # Logs warning for missing file. # Protokolliert Warnung für fehlende Datei.
            raise HTTPException(status_code=404, detail="Audio file not found") # Raises HTTP 404 for missing files. # Wirft HTTP 404 für fehlende Dateien.

        return FileResponse( # Returns file as HTTP response. # Gibt Datei als HTTP-Antwort zurück.
            path=file_path, # Path to the file. # Pfad zur Datei.
            media_type="audio/mp3", # Sets media type to MP3 audio. # Setzt Medientyp auf MP3-Audio.
            filename=filename, # Sets filename in the response. # Setzt Dateiname in der Antwort.
            headers={"Cache-Control": "no-cache"} # Prevents caching of audio files. # Verhindert Caching von Audiodateien.
        )
    except Exception as e: # Catches any exceptions. # Fängt alle Ausnahmen ab.
        logger.error(f"Audio delivery error: {str(e)}", exc_info=True) # Logs error with full traceback. # Protokolliert Fehler mit vollständigem Traceback.
        raise HTTPException(status_code=500, detail=str(e)) # Raises HTTP 500 with error details. # Wirft HTTP 500 mit Fehlerdetails.
