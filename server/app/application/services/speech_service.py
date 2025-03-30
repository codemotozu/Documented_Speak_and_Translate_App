# SpeechService
#
# A Python service for speech recognition and audio processing. # Ein Python-Service für Spracherkennung und Audioverarbeitung.
# Provides wake word detection and speech-to-text conversion for an AI Chat Assistant. # Bietet Aktivierungswort-Erkennung und Sprache-zu-Text-Umwandlung für einen KI-Chat-Assistenten.
#
# Usage:
# speech_service = SpeechService() # Creates a new instance of the SpeechService class. # Erstellt eine neue Instanz der SpeechService-Klasse.
# command = await speech_service.process_command("audio.wav") # Asynchronously processes an audio file to detect wake words like "open" or "stop". # Verarbeitet asynchron eine Audiodatei, um Aktivierungswörter wie "open" oder "stop" zu erkennen.
# text = await speech_service.process_audio("recording.mp3") # Asynchronously converts speech in an audio file to text, supporting various formats like MP3. # Wandelt asynchron Sprache in einer Audiodatei in Text um, unterstützt verschiedene Formate wie MP3.
#
# EN: Uses Azure Speech Services for wake word detection and Google's speech recognition for text conversion.
# DE: Verwendet Azure Speech Services für die Erkennung von Aktivierungswörtern und Googles Spracherkennung für die Textumwandlung.

from ...domain.entities.translation import Translation # Imports Translation entity from domain layer. # Importiert die Translation-Entität aus der Domain-Schicht.
from ..services.translation_service import TranslationService # Imports the TranslationService for text translation. # Importiert den TranslationService für Textübersetzungen.
from pydub import AudioSegment # Imports AudioSegment for audio file manipulation. # Importiert AudioSegment für die Manipulation von Audiodateien.
import speech_recognition as sr # Imports speech_recognition library for audio processing. # Importiert die speech_recognition-Bibliothek für die Audioverarbeitung.
import azure.cognitiveservices.speech as speechsdk # Imports Azure Speech SDK for cloud-based speech recognition. # Importiert Azure Speech SDK für cloudbasierte Spracherkennung.
import tempfile # Imports tempfile for creating temporary files. # Importiert tempfile zum Erstellen temporärer Dateien.
import os # Imports os module for file system operations. # Importiert das os-Modul für Dateisystemoperationen.
import asyncio # Imports asyncio for asynchronous programming. # Importiert asyncio für asynchrone Programmierung.
from fastapi import HTTPException # Imports HTTPException for API error handling. # Importiert HTTPException für API-Fehlerbehandlung.
import logging # Imports logging for application logging. # Importiert logging für Anwendungsprotokollierung.

logging.basicConfig(level=logging.DEBUG) # Configures basic logging with DEBUG level. # Konfiguriert grundlegende Protokollierung mit DEBUG-Level.
logger = logging.getLogger(__name__) # Creates a logger instance for this module. # Erstellt eine Logger-Instanz für dieses Modul.


class SpeechService: # Defines the SpeechService class. # Definiert die SpeechService-Klasse.
    def __init__(self): # Initializes the SpeechService. # Initialisiert den SpeechService.
        self.speech_key = os.getenv("AZURE_SPEECH_KEY") # Gets Azure Speech API key from environment variables. # Holt den Azure Speech API-Schlüssel aus Umgebungsvariablen.
        self.speech_region = os.getenv("AZURE_SPEECH_REGION") # Gets Azure Speech region from environment variables. # Holt die Azure Speech-Region aus Umgebungsvariablen.
        
        if not self.speech_key or not self.speech_region: # Checks if Azure credentials are available. # Prüft, ob Azure-Anmeldedaten verfügbar sind.
            raise ValueError("Azure Speech credentials not found") # Raises error if credentials are missing. # Löst einen Fehler aus, wenn Anmeldedaten fehlen.
            
        self.speech_config = speechsdk.SpeechConfig( # Creates Azure Speech configuration. # Erstellt die Azure Speech-Konfiguration.
            subscription=self.speech_key, # Sets the subscription key. # Setzt den Abonnementschlüssel.
            region=self.speech_region # Sets the region. # Setzt die Region.
        )
        self.speech_config.speech_recognition_language = "en-EN" # Sets English as the recognition language. # Setzt Englisch als Erkennungssprache.
        
        # Initialize speech recognizer for general audio processing
        self.recognizer = sr.Recognizer() # Creates a speech recognizer instance. # Erstellt eine Spracherkennungsinstanz.
        self.recognizer.energy_threshold = 300 # Sets the energy level threshold for detection. # Setzt den Energieschwellenwert für die Erkennung.
        self.recognizer.dynamic_energy_threshold = True # Enables dynamic adjustment of energy threshold. # Aktiviert die dynamische Anpassung des Energieschwellenwerts.
        
        # Define wake words/commands
        self.WAKE_WORDS = { # Defines a dictionary of wake words and their meanings. # Definiert ein Wörterbuch von Aktivierungswörtern und ihren Bedeutungen.
            "open": "START_RECORDING", # Maps "open" to start recording command. # Ordnet "open" dem Befehl zum Starten der Aufnahme zu.
            "stop": "STOP_RECORDING" # Maps "stop" to stop recording command. # Ordnet "stop" dem Befehl zum Stoppen der Aufnahme zu.
        }
        
        # Audio format configuration
        self.supported_formats = [".wav", ".aac", ".mp3", ".ogg", ".mp4", ".m4a"] # Lists supported audio file extensions. # Listet unterstützte Audiodatei-Erweiterungen auf.
        self.valid_mime_types = [ # Lists valid MIME types for audio files. # Listet gültige MIME-Typen für Audiodateien auf.
            "audio/wav", "audio/aac", "audio/mpeg", "audio/ogg",
            "audio/mp4", "audio/x-m4a"
        ]
        
        self.translation_service = TranslationService() # Creates a translation service instance. # Erstellt eine Instanz des Übersetzungsdienstes.

    async def process_command(self, audio_path: str) -> str: # Defines method to process audio for wake word detection. # Definiert eine Methode zur Verarbeitung von Audio für die Erkennung von Aktivierungswörtern.
        """Process audio for wake word detection using Azure Speech Services"""
        working_path = audio_path # Sets the initial working path to the input path. # Setzt den anfänglichen Arbeitspfad auf den Eingabepfad.
        converted_path = None # Initializes converted path variable to None. # Initialisiert die Variable für den konvertierten Pfad mit None.
        
        try: # Begins a try block for error handling. # Beginnt einen Try-Block für die Fehlerbehandlung.
            # Convert to WAV if needed
            if not working_path.lower().endswith(".wav"): # Checks if the file is not already in WAV format. # Prüft, ob die Datei nicht bereits im WAV-Format ist.
                converted_path = await self._convert_to_wav(working_path) # Converts the file to WAV format. # Konvertiert die Datei in das WAV-Format.
                working_path = converted_path # Updates working path to the converted file. # Aktualisiert den Arbeitspfad auf die konvertierte Datei.

            # Set up Azure speech recognition
            audio_config = speechsdk.AudioConfig(filename=working_path) # Creates audio configuration with the file path. # Erstellt eine Audiokonfiguration mit dem Dateipfad.
            speech_recognizer = speechsdk.SpeechRecognizer( # Creates a speech recognizer with the configurations. # Erstellt einen Spracherkenner mit den Konfigurationen.
                speech_config=self.speech_config, # Sets the speech configuration. # Setzt die Sprachkonfiguration.
                audio_config=audio_config # Sets the audio configuration. # Setzt die Audiokonfiguration.
            )

            # Use promise for async recognition
            done = False # Initializes done flag to False. # Initialisiert die Fertig-Flagge mit False.
            recognized_text = None # Initializes recognized text to None. # Initialisiert den erkannten Text mit None.

            def handle_result(evt): # Defines a callback function for handling recognition results. # Definiert eine Callback-Funktion für die Behandlung von Erkennungsergebnissen.
                nonlocal done, recognized_text # Uses nonlocal to access outer scope variables. # Verwendet nonlocal, um auf Variablen im äußeren Gültigkeitsbereich zuzugreifen.
                if evt.result.reason == speechsdk.ResultReason.RecognizedSpeech: # Checks if speech was recognized. # Prüft, ob Sprache erkannt wurde.
                    recognized_text = evt.result.text.lower().strip() # Stores the recognized text in lowercase and trimmed. # Speichert den erkannten Text in Kleinbuchstaben und getrimmt.
                done = True # Sets done flag to True. # Setzt die Fertig-Flagge auf True.

            speech_recognizer.recognized.connect(handle_result) # Connects the result handler to the recognized event. # Verbindet den Ergebnishandler mit dem Erkennungsereignis.
            
            # Start recognition
            speech_recognizer.start_continuous_recognition() # Starts continuous recognition. # Startet die kontinuierliche Erkennung.
            
            # Wait for result with timeout
            timeout = 5  # 5 seconds timeout # Sets a 5-second timeout. # Setzt ein 5-Sekunden-Timeout.
            start_time = asyncio.get_event_loop().time() # Gets the current time. # Holt die aktuelle Zeit.
            
            while not done: # Loops until done flag is set or timeout occurs. # Schleife, bis die Fertig-Flagge gesetzt ist oder Timeout eintritt.
                if asyncio.get_event_loop().time() - start_time > timeout: # Checks if timeout has occurred. # Prüft, ob ein Timeout eingetreten ist.
                    speech_recognizer.stop_continuous_recognition() # Stops recognition if timeout. # Stoppt die Erkennung bei Timeout.
                    raise HTTPException( # Raises an HTTP exception for timeout. # Löst eine HTTP-Ausnahme für Timeout aus.
                        status_code=408, # Sets 408 Request Timeout status code. # Setzt den Statuscode 408 Request Timeout.
                        detail="Recognition timeout" # Sets error detail message. # Setzt die detaillierte Fehlermeldung.
                    )
                await asyncio.sleep(0.1) # Waits for 0.1 seconds before checking again. # Wartet 0,1 Sekunden, bevor erneut geprüft wird.
            
            speech_recognizer.stop_continuous_recognition() # Stops recognition after getting result. # Stoppt die Erkennung nach Erhalt des Ergebnisses.

            # Check if recognized text matches any wake words
            if recognized_text in self.WAKE_WORDS: # Checks if text is a wake word command. # Prüft, ob der Text ein Aktivierungswort-Befehl ist.
                return recognized_text # Returns the recognized wake word. # Gibt das erkannte Aktivierungswort zurück.
            
            return "UNKNOWN_COMMAND" # Returns unknown command if no wake word is matched. # Gibt unbekannten Befehl zurück, wenn kein Aktivierungswort übereinstimmt.

        except Exception as e: # Catches any exceptions. # Fängt alle Ausnahmen ab.
            logger.error(f"Command processing error: {str(e)}") # Logs the error. # Protokolliert den Fehler.
            raise HTTPException( # Raises an HTTP exception with error details. # Löst eine HTTP-Ausnahme mit Fehlerdetails aus.
                status_code=500, # Sets 500 Internal Server Error status code. # Setzt den Statuscode 500 Internal Server Error.
                detail=f"Command processing failed: {str(e)}" # Sets error detail message. # Setzt die detaillierte Fehlermeldung.
            )
        finally: # Finally block to ensure cleanup happens. # Finally-Block, um sicherzustellen, dass die Bereinigung stattfindet.
            # Cleanup temporary files
            await self._cleanup_temp_files(converted_path) # Cleans up any temporary files. # Bereinigt alle temporären Dateien.

    async def _convert_to_wav(self, audio_path: str) -> str: # Defines a private method to convert audio to WAV format. # Definiert eine private Methode zur Konvertierung von Audio in das WAV-Format.
        """Convert any audio format to WAV using pydub"""
        try: # Begins a try block for error handling. # Beginnt einen Try-Block für die Fehlerbehandlung.
            logger.debug(f"Converting {audio_path} to WAV") # Logs conversion attempt. # Protokolliert den Konvertierungsversuch.
            
            ext = os.path.splitext(audio_path)[1].lower().replace(".", "") # Extracts and normalizes file extension. # Extrahiert und normalisiert die Dateierweiterung.
            if ext not in ["mp3", "aac", "ogg", "m4a", "mp4"]: # Checks if the format is supported. # Prüft, ob das Format unterstützt wird.
                raise HTTPException( # Raises exception for unsupported format. # Löst eine Ausnahme für nicht unterstütztes Format aus.
                    status_code=400, # Sets 400 Bad Request status code. # Setzt den Statuscode 400 Bad Request.
                    detail=f"Unsupported conversion format: {ext}" # Sets error detail message. # Setzt die detaillierte Fehlermeldung.
                )

            try: # Nested try block for file loading. # Verschachtelter Try-Block für das Laden von Dateien.
                sound = AudioSegment.from_file(audio_path, format=ext) # Loads audio file with pydub. # Lädt Audiodatei mit pydub.
            except Exception as e: # Catches exceptions during file loading. # Fängt Ausnahmen während des Ladens der Datei ab.
                logger.error(f"Error loading {ext} file: {str(e)}") # Logs the error. # Protokolliert den Fehler.
                raise HTTPException( # Raises HTTP exception for invalid file. # Löst eine HTTP-Ausnahme für ungültige Datei aus.
                    status_code=400, # Sets 400 Bad Request status code. # Setzt den Statuscode 400 Bad Request.
                    detail=f"Invalid {ext.upper()} file structure" # Sets error detail message. # Setzt die detaillierte Fehlermeldung.
                )

            wav_path = f"{os.path.splitext(audio_path)[0]}.wav" # Creates path for the WAV file. # Erstellt Pfad für die WAV-Datei.
            sound.export(wav_path, format="wav", parameters=[ # Exports audio to WAV format with specific parameters. # Exportiert Audio ins WAV-Format mit bestimmten Parametern.
                "-ar", "16000",     # Set sample rate # Sets 16kHz sample rate for better recognition. # Setzt 16kHz Abtastrate für bessere Erkennung.
                "-ac", "1",         # Set mono channel # Sets mono channel (single channel). # Setzt Mono-Kanal (einzelner Kanal).
                "-bits_per_raw_sample", "16" # Sets 16-bit sample depth. # Setzt 16-Bit Abtasttiefe.
            ])
            
            return wav_path # Returns the path to the converted WAV file. # Gibt den Pfad zur konvertierten WAV-Datei zurück.
            
        except Exception as e: # Catches any exceptions not caught in nested try blocks. # Fängt alle Ausnahmen ab, die nicht in verschachtelten Try-Blöcken gefangen wurden.
            logger.error(f"Conversion error: {str(e)}") # Logs the error. # Protokolliert den Fehler.
            raise HTTPException(status_code=500, detail=f"Audio conversion failed: {str(e)}") # Raises HTTP exception with error details. # Löst eine HTTP-Ausnahme mit Fehlerdetails aus.

    async def _cleanup_temp_files(self, *files): # Defines a private method to clean up temporary files. # Definiert eine private Methode zum Bereinigen temporärer Dateien.
        """Clean up temporary files"""
        for f in files: # Iterates through each file in the arguments. # Iteriert durch jede Datei in den Argumenten.
            try: # Try block for each file deletion. # Try-Block für jede Dateilöschung.
                if f and os.path.exists(f): # Checks if the file exists. # Prüft, ob die Datei existiert.
                    os.remove(f) # Removes the file. # Entfernt die Datei.
                    logger.debug(f"Cleaned up file: {f}") # Logs successful cleanup. # Protokolliert erfolgreiche Bereinigung.
            except Exception as e: # Catches exceptions during file deletion. # Fängt Ausnahmen während der Dateilöschung ab.
                logger.error(f"Error cleaning up file {f}: {str(e)}") # Logs the error. # Protokolliert den Fehler.

    async def process_audio(self, audio_file_path: str) -> str: # Defines method to process audio and return recognized text. # Definiert eine Methode zur Verarbeitung von Audio und Rückgabe von erkanntem Text.
        """Process audio file and return recognized text only"""
        working_path = audio_file_path # Sets the initial working path. # Setzt den anfänglichen Arbeitspfad.
        converted_path = None # Initializes converted path variable. # Initialisiert die Variable für den konvertierten Pfad.
        
        try: # Begins a try block for error handling. # Beginnt einen Try-Block für die Fehlerbehandlung.
            # Validate file existence
            if not os.path.exists(working_path): # Checks if the file exists. # Prüft, ob die Datei existiert.
                raise HTTPException(status_code=400, detail="File not found") # Raises exception if file not found. # Löst eine Ausnahme aus, wenn die Datei nicht gefunden wird.

            # Convert non-WAV files
            if not working_path.lower().endswith(".wav"): # Checks if file is not WAV format. # Prüft, ob die Datei nicht im WAV-Format ist.
                converted_path = await self._convert_to_wav(working_path) # Converts file to WAV. # Konvertiert die Datei in WAV.
                working_path = converted_path # Updates working path to converted file. # Aktualisiert den Arbeitspfad auf die konvertierte Datei.

            # Speech recognition
            with sr.AudioFile(working_path) as source: # Opens WAV file for recognition. # Öffnet WAV-Datei für die Erkennung.
                self.recognizer.adjust_for_ambient_noise(source, duration=0.5) # Adjusts for background noise. # Passt sich an Hintergrundgeräusche an.
                audio = self.recognizer.record(source) # Records audio from the file. # Nimmt Audio aus der Datei auf.
                text = self.recognizer.recognize_google(audio, language="es-ES") # Uses Google's API for Spanish recognition. # Verwendet Googles API für spanische Erkennung.
                
            return text # Returns the recognized text. # Gibt den erkannten Text zurück.

        finally: # Finally block to ensure cleanup. # Finally-Block für die Sicherstellung der Bereinigung.
            # Cleanup converted files
            await self._cleanup_temp_files(converted_path) # Cleans up temporary files. # Bereinigt temporäre Dateien.
