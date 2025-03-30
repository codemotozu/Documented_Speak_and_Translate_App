# EnhancedTTSService
#
# A service for converting text to speech using Azure Cognitive Services. # Ein Dienst zur Umwandlung von Text in Sprache mit Azure Cognitive Services.
# Specialized in handling multilingual word-by-word translations with phonetic accuracy. # Spezialisiert auf die Behandlung mehrsprachiger Wort-für-Wort-Übersetzungen mit phonetischer Genauigkeit.
#
# Usage:
# tts_service = EnhancedTTSService() # Creates a new TTS service instance. # Erstellt eine neue TTS-Dienst-Instanz.
# ssml = tts_service.generate_enhanced_ssml(text="Hello world", source_lang="en", target_lang="es") # Generates SSML markup with language tags. # Generiert SSML-Markup mit Sprachtags.
# audio_file = await tts_service.text_to_speech(ssml) # Converts the SSML to an audio file. # Konvertiert das SSML in eine Audiodatei.
#
# EN: Creates high-quality multilingual text-to-speech with precise language transitions and pronunciation.
# DE: Erstellt hochwertige mehrsprachige Text-zu-Sprache mit präzisen Sprachübergängen und Aussprache.

from azure.cognitiveservices.speech import ( # Imports Azure Speech SDK components. # Importiert Azure Speech SDK-Komponenten.
    SpeechConfig, # For configuring speech service connection. # Zur Konfiguration der Sprachdienstverbindung.
    SpeechSynthesizer, # For performing text-to-speech conversion. # Zur Durchführung der Text-zu-Sprache-Umwandlung.
    SpeechSynthesisOutputFormat, # For defining audio output format. # Zur Definition des Audio-Ausgabeformats.
    ResultReason, # For checking speech synthesis results. # Zur Prüfung der Sprachsyntheseresultate.
    CancellationReason, # For handling synthesis cancellations. # Zur Behandlung von Syntheseabbrüchen.
)
from azure.cognitiveservices.speech.audio import AudioOutputConfig # For configuring audio output settings. # Zur Konfiguration der Audio-Ausgabeeinstellungen.
import os # For accessing operating system functionality. # Für den Zugriff auf Betriebssystemfunktionalität.
from typing import Optional # For type hinting with optional values. # Für Typhinweise mit optionalen Werten.
from datetime import datetime # For generating timestamps. # Zur Erzeugung von Zeitstempeln.
import asyncio # For asynchronous programming. # Für asynchrone Programmierung.
import re # For regular expression pattern matching. # Für reguläre Ausdruckmusterabgleiche.

from asyncio import Semaphore # For limiting concurrent operations. # Zur Begrenzung gleichzeitiger Operationen.
import time # For time-related functions. # Für zeitbezogene Funktionen.


class EnhancedTTSService: # Defines the EnhancedTTSService class. # Definiert die EnhancedTTSService-Klasse.
    def __init__(self): # Initializes the service. # Initialisiert den Dienst.
        self.subscription_key = os.getenv("AZURE_SPEECH_KEY") # Gets Azure API key from environment variables. # Holt den Azure-API-Schlüssel aus Umgebungsvariablen.
        self.region = os.getenv("AZURE_SPEECH_REGION") # Gets Azure region from environment variables. # Holt die Azure-Region aus Umgebungsvariablen.

        if not self.subscription_key or not self.region: # Checks if credentials are missing. # Prüft, ob Anmeldedaten fehlen.
            raise ValueError( # Raises an error if credentials are missing. # Löst einen Fehler aus, wenn Anmeldedaten fehlen.
                "Azure Speech credentials not found in environment variables" # Error message for missing credentials. # Fehlermeldung für fehlende Anmeldedaten.
            )

        os.environ["SPEECH_CONTAINER_OPTION"] = "1" # Sets container mode for Azure Speech SDK. # Setzt den Container-Modus für das Azure Speech SDK.
        os.environ["SPEECH_SYNTHESIS_PLATFORM_CONFIG"] = "container" # Configures synthesis platform for containers. # Konfiguriert die Syntheseplattform für Container.
        
    
        self.speech_host = f"wss://{self.region}.tts.speech.microsoft.com/cognitiveservices/websocket/v1" # Constructs WebSocket endpoint URL. # Konstruiert die WebSocket-Endpunkt-URL.
        self.speech_config = SpeechConfig( # Creates speech configuration. # Erstellt die Sprachkonfiguration.
            subscription=self.subscription_key, # Sets the API key. # Setzt den API-Schlüssel.
            endpoint=self.speech_host # Sets the endpoint URL. # Setzt die Endpunkt-URL.
        )
        
        self.speech_config.set_speech_synthesis_output_format( # Sets output audio format. # Setzt das Ausgabe-Audioformat.
            SpeechSynthesisOutputFormat.Audio16Khz32KBitRateMonoMp3 # Uses 16kHz 32kbps mono MP3 format. # Verwendet 16kHz 32kbps Mono-MP3-Format.
        )

        tts_device = os.getenv("TTS_DEVICE", "cpu").lower() # Gets device setting (CPU/GPU) from environment or defaults to CPU. # Holt Geräteeinstellung (CPU/GPU) aus der Umgebung oder setzt Standard auf CPU.
        if os.getenv("CONTAINER_ENV", "false").lower() == "true": # Checks if running in container environment. # Prüft, ob in Container-Umgebung ausgeführt wird.
            tts_device = "cpu" # Forces CPU mode in container environment. # Erzwingt CPU-Modus in Container-Umgebung.
            
        print(f"Using TTS device: {tts_device}") # Logs the device being used. # Protokolliert das verwendete Gerät.

        self.voice_mapping = { # Maps language codes to voice names. # Ordnet Sprachcodes den Stimmnamen zu.
            "en": "en-US-JennyMultilingualNeural", # English voice. # Englische Stimme.
            "es": "es-ES-ArabellaMultilingualNeural", # Spanish voice. # Spanische Stimme.
            "de": "de-DE-SeraphinaMultilingualNeural", # German voice. # Deutsche Stimme.
        }

    async def _execute_speech_synthesis( # Defines private method for executing speech synthesis. # Definiert private Methode zur Ausführung der Sprachsynthese.
        self, ssml: str, output_path: Optional[str] = None # Takes SSML and optional output path. # Nimmt SSML und optionalen Ausgabepfad.
    ) -> Optional[str]: # Returns filename or None if failed. # Gibt Dateinamen zurück oder None bei Fehlschlag.
        """Execute the speech synthesis with proper resource cleanup"""
        synthesizer = None # Initializes synthesizer to None for cleanup in finally block. # Initialisiert Synthesizer mit None für Bereinigung im Finally-Block.
        try: # Starts try block for error handling. # Beginnt Try-Block für Fehlerbehandlung.
            if not output_path: # Checks if output path is not provided. # Prüft, ob kein Ausgabepfad angegeben ist.
                temp_dir = self._get_temp_directory() # Gets temporary directory. # Holt temporäres Verzeichnis.
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S") # Creates timestamp for unique filename. # Erstellt Zeitstempel für eindeutigen Dateinamen.
                output_path = os.path.join(temp_dir, f"speech_{timestamp}.mp3") # Creates full output path. # Erstellt vollständigen Ausgabepfad.

            audio_config = AudioOutputConfig(filename=output_path) # Configures audio output to file. # Konfiguriert Audio-Ausgabe in Datei.
            synthesizer = SpeechSynthesizer( # Creates speech synthesizer. # Erstellt Sprachsynthesizer.
                speech_config=self.speech_config, audio_config=audio_config # Configures with speech and audio settings. # Konfiguriert mit Sprach- und Audioeinstellungen.
            )

            result = await asyncio.get_event_loop().run_in_executor( # Runs CPU-intensive task in thread pool. # Führt CPU-intensive Aufgabe im Thread-Pool aus.
                None, lambda: synthesizer.speak_ssml_async(ssml).get() # Executes SSML synthesis and gets result. # Führt SSML-Synthese aus und holt Ergebnis.
            )

            if result.reason == ResultReason.SynthesizingAudioCompleted: # Checks if synthesis completed successfully. # Prüft, ob Synthese erfolgreich abgeschlossen wurde.
                return os.path.basename(output_path) # Returns only filename without path. # Gibt nur Dateinamen ohne Pfad zurück.

            if result.reason == ResultReason.Canceled: # Checks if synthesis was canceled. # Prüft, ob Synthese abgebrochen wurde.
                cancellation_details = result.cancellation_details # Gets cancellation details. # Holt Abbruchdetails.
                error_message = ( # Creates error message with cancellation reason. # Erstellt Fehlermeldung mit Abbruchgrund.
                    f"Speech synthesis canceled: {cancellation_details.reason}" # Basic cancellation message. # Grundlegende Abbruchmeldung.
                )
                if cancellation_details.reason == CancellationReason.Error: # Checks if cancellation was due to error. # Prüft, ob Abbruch aufgrund eines Fehlers erfolgte.
                    error_message += ( # Adds error details to message. # Fügt Fehlerdetails zur Nachricht hinzu.
                        f"\nError details: {cancellation_details.error_details}" # Detailed error information. # Detaillierte Fehlerinformationen.
                    )
                raise Exception(error_message) # Raises exception with error details. # Löst Ausnahme mit Fehlerdetails aus.

            return None # Returns None if synthesis didn't complete successfully. # Gibt None zurück, wenn Synthese nicht erfolgreich abgeschlossen wurde.

        finally: # Finally block for cleanup regardless of success/failure. # Finally-Block für Bereinigung unabhängig von Erfolg/Fehlschlag.
            if synthesizer: # Checks if synthesizer was created. # Prüft, ob Synthesizer erstellt wurde.
                try: # Nested try for cleanup. # Verschachtelter Try für Bereinigung.
                    synthesizer.stop_speaking_async() # Stops any ongoing synthesis. # Stoppt laufende Synthese.
                except: # Ignores errors during cleanup. # Ignoriert Fehler während der Bereinigung.
                    pass # Does nothing if cleanup fails. # Tut nichts, wenn Bereinigung fehlschlägt.

    def _get_temp_directory(self) -> str: # Defines method to get temporary directory. # Definiert Methode zum Abrufen des temporären Verzeichnisses.
        """Create and return the temporary directory path"""
        if os.name == "nt":  # Checks if running on Windows. # Prüft, ob auf Windows ausgeführt.
            temp_dir = os.path.join(os.environ.get("TEMP", ""), "tts_audio") # Creates path in Windows temp. # Erstellt Pfad im Windows-Temp.
        else: # For non-Windows systems (Linux/Mac). # Für Nicht-Windows-Systeme (Linux/Mac).
            temp_dir = "/tmp/tts_audio" # Uses Unix standard temp directory. # Verwendet Unix-Standard-Temp-Verzeichnis.
        os.makedirs(temp_dir, exist_ok=True) # Creates directory if it doesn't exist. # Erstellt Verzeichnis, falls es nicht existiert.
        return temp_dir # Returns the directory path. # Gibt den Verzeichnispfad zurück.

    def _detect_language(self, text: str) -> str: # Defines method to detect language from text. # Definiert Methode zur Spracherkennung aus Text.
        """Detect the primary language of the text"""
        if re.search(r"[äöüßÄÖÜ]", text): # Checks for German-specific characters. # Prüft auf deutschspezifische Zeichen.
            return "de" # Returns German language code. # Gibt deutschen Sprachcode zurück.
        elif re.search(r"[áéíóúñ¿¡]", text): # Checks for Spanish-specific characters. # Prüft auf spanischspezifische Zeichen.
            return "es" # Returns Spanish language code. # Gibt spanischen Sprachcode zurück.
        return "en" # Default to English if no specific characters found. # Standardmäßig Englisch, wenn keine spezifischen Zeichen gefunden.

    def _is_german_word(self, word: str) -> bool: # Defines method to check if word is German. # Definiert Methode zur Prüfung, ob Wort deutsch ist.
        german_words = { # Set of common German words. # Menge häufiger deutscher Wörter.
            "dir", # you (dative) # dir
            "ich", # I # ich
            "du", # you (informal) # du
            "sie", # she/they/you (formal) # sie
            "er", # he # er
            "es", # it # es
            "wir", # we # wir
            "ihr", # you (plural) # ihr
            "ist", # is # ist
            "sind", # are # sind
            "haben", # have # haben
            "sein", # to be # sein
            "werden", # to become # werden
            "kann", # can # kann
            "könnte", # could # könnte
            "möchte", # would like # möchte
            "muss", # must # muss
            "darf", # may # darf
            "soll", # should # soll
        }
        return word.lower() in german_words # Checks if lowercased word is in German word set. # Prüft, ob Wort in Kleinbuchstaben in deutscher Wörtermenge ist.

    def _is_english_word(self, word: str) -> bool: # Defines method to check if word is English. # Definiert Methode zur Prüfung, ob Wort englisch ist.
        english_words = {"the", "a", "an", "in", "on", "at", "to", "for", "with", "by"} # Set of common English words. # Menge häufiger englischer Wörter.
        return word.lower() in english_words # Checks if lowercased word is in English word set. # Prüft, ob Wort in Kleinbuchstaben in englischer Wörtermenge ist.

    def generate_german_spanish_wordforword_ssml( # Defines method for German-Spanish word pairs SSML. # Definiert Methode für Deutsch-Spanisch-Wortpaar-SSML.
        self,
        word_pairs: list[tuple[str, str]], # List of source-target word pairs. # Liste von Quell-Ziel-Wortpaaren.
    ) -> str: # Returns SSML string. # Gibt SSML-Zeichenkette zurück.
        """Generate SSML specifically for German-Spanish word-by-word translations"""
        ssml = """
        <voice name="en-US-JennyMultilingualNeural">
            <prosody rate="0.8">""" # Creates SSML header with voice and slower speech rate. # Erstellt SSML-Header mit Stimme und langsamerer Sprechrate.

        for source_word, target_word in word_pairs: # Iterates through each word pair. # Iteriert durch jedes Wortpaar.
            source_word = source_word.strip().replace("&", "&amp;") # Cleans up source word and escapes ampersands. # Bereinigt Quellwort und escapet Kaufmannsund.
            target_word = target_word.strip().replace("&", "&amp;") # Cleans up target word and escapes ampersands. # Bereinigt Zielwort und escapet Kaufmannsund.

            ssml += f"""
                <lang xml:lang="de-DE">{source_word}</lang>
                <break time="300ms"/>
                <lang xml:lang="es-ES">{target_word}</lang>
                <break time="500ms"/>""" # Adds each word pair with language tags and pauses. # Fügt jedes Wortpaar mit Sprachtags und Pausen hinzu.

        ssml += """
                <break time="1000ms"/>
            </prosody>
        </voice>""" # Closes the SSML tags. # Schließt die SSML-Tags.

        return ssml # Returns the complete SSML. # Gibt das vollständige SSML zurück.

    def generate_english_spanish_wordforword_ssml( # Defines method for English-Spanish word pairs SSML. # Definiert Methode für Englisch-Spanisch-Wortpaar-SSML.
        self,
        word_pairs: list[tuple[str, str]], # List of source-target word pairs. # Liste von Quell-Ziel-Wortpaaren.
    ) -> str: # Returns SSML string. # Gibt SSML-Zeichenkette zurück.
        """Generate SSML specifically for English-Spanish word-by-word translations"""
        ssml = """
        <voice name="en-US-JennyMultilingualNeural">
            <prosody rate="0.8">""" # Creates SSML header with voice and slower speech rate. # Erstellt SSML-Header mit Stimme und langsamerer Sprechrate.

        for source_word, target_word in word_pairs: # Iterates through each word pair. # Iteriert durch jedes Wortpaar.
            source_word = source_word.strip().replace("&", "&amp;") # Cleans up source word and escapes ampersands. # Bereinigt Quellwort und escapet Kaufmannsund.
            target_word = target_word.strip().replace("&", "&amp;") # Cleans up target word and escapes ampersands. # Bereinigt Zielwort und escapet Kaufmannsund.

            ssml += f"""
                <lang xml:lang="en-US">{source_word}</lang>
                <break time="300ms"/>
                <lang xml:lang="es-ES">{target_word}</lang>
                <break time="500ms"/>""" # Adds each word pair with language tags and pauses. # Fügt jedes Wortpaar mit Sprachtags und Pausen hinzu.

        ssml += """
                <break time="1000ms"/>
            </prosody>
        </voice>""" # Closes the SSML tags. # Schließt die SSML-Tags.

        return ssml # Returns the complete SSML. # Gibt das vollständige SSML zurück.

    def generate_enhanced_ssml( # Defines method to generate enhanced SSML with multiple languages. # Definiert Methode zur Generierung von erweitertem SSML mit mehreren Sprachen.
        self,
        text: Optional[str] = None, # Optional text to translate. # Optionaler zu übersetzender Text.
        word_pairs: Optional[list[tuple[str, str, bool]]] = None, # Optional word pairs with language flag. # Optionale Wortpaare mit Sprachflagge.
        source_lang: str = "de", # Source language, defaults to German. # Quellsprache, standardmäßig Deutsch.
        target_lang: str = "es", # Target language, defaults to Spanish. # Zielsprache, standardmäßig Spanisch.
    ) -> str: # Returns SSML string. # Gibt SSML-Zeichenkette zurück.
        """Generate SSML with proper phrase handling for both German and English"""
        ssml = """<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">""" # Starts SSML document. # Startet SSML-Dokument.

        if text: # Checks if text is provided. # Prüft, ob Text bereitgestellt wird.
            sentences = (text.split("\n") + [""] * 8)[:8] # Splits text by lines and pads to 8 sentences. # Teilt Text nach Zeilen und füllt auf 8 Sätze auf.
            sentences = [ # Processes each sentence. # Verarbeitet jeden Satz.
                t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;") # Escapes XML special characters. # Escapet XML-Sonderzeichen.
                for t in sentences # For each sentence in the list. # Für jeden Satz in der Liste.
            ]

            ( # Unpacks sentences to named variables. # Entpackt Sätze in benannte Variablen.
                german_native, # Native German translation. # Muttersprachliche deutsche Übersetzung.
                german_colloquial, # Colloquial German translation. # Umgangssprachliche deutsche Übersetzung.
                german_informal, # Informal German translation. # Informelle deutsche Übersetzung.
                german_formal, # Formal German translation. # Formelle deutsche Übersetzung.
                english_native, # Native English translation. # Muttersprachliche englische Übersetzung.
                english_colloquial, # Colloquial English translation. # Umgangssprachliche englische Übersetzung.
                english_informal, # Informal English translation. # Informelle englische Übersetzung.
                english_formal, # Formal English translation. # Formelle englische Übersetzung.
            ) = sentences # Assigns sentence list to these variables. # Weist Satzliste diesen Variablen zu.

            if word_pairs: # Checks if word pairs are provided. # Prüft, ob Wortpaare bereitgestellt werden.
                german_pairs = [ # Filters for German word pairs. # Filtert nach deutschen Wortpaaren.
                    (src, tgt) for src, tgt, is_german in word_pairs if is_german # Keeps only German source pairs. # Behält nur deutsche Quellpaare.
                ]
                english_pairs = [ # Filters for English word pairs. # Filtert nach englischen Wortpaaren.
                    (src, tgt) for src, tgt, is_german in word_pairs if not is_german # Keeps only English source pairs. # Behält nur englische Quellpaare.
                ]

                if german_native: # Checks if native German translation exists. # Prüft, ob muttersprachliche deutsche Übersetzung existiert.
                    ssml += self._generate_language_section( # Adds native German section to SSML. # Fügt muttersprachlichen deutschen Abschnitt zum SSML hinzu.
                        german_native, # The sentence text. # Der Satztext.
                        german_pairs, # Word pairs for this section. # Wortpaare für diesen Abschnitt.
                        voice="de-DE-SeraphinaMultilingualNeural", # German voice to use. # Zu verwendende deutsche Stimme.
                        lang="de-DE", # German language code. # Deutscher Sprachcode.
                    )

                if german_colloquial: # Checks if colloquial German translation exists. # Prüft, ob umgangssprachliche deutsche Übersetzung existiert.
                    ssml += self._generate_language_section( # Adds colloquial German section to SSML. # Fügt umgangssprachlichen deutschen Abschnitt zum SSML hinzu.
                        german_colloquial, # The sentence text. # Der Satztext.
                        german_pairs, # Word pairs for this section. # Wortpaare für diesen Abschnitt.
                        voice="de-DE-SeraphinaMultilingualNeural", # German voice to use. # Zu verwendende deutsche Stimme.
                        lang="de-DE", # German language code. # Deutscher Sprachcode.
                    )

                if german_informal: # Checks if informal German translation exists. # Prüft, ob informelle deutsche Übersetzung existiert.
                    ssml += self._generate_language_section( # Adds informal German section to SSML. # Fügt informellen deutschen Abschnitt zum SSML hinzu.
                        german_informal, # The sentence text. # Der Satztext.
                        german_pairs, # Word pairs for this section. # Wortpaare für diesen Abschnitt.
                        voice="de-DE-KatjaNeural", # Alternative German voice for variety. # Alternative deutsche Stimme für Abwechslung.
                        lang="de-DE", # German language code. # Deutscher Sprachcode.
                    )

                if german_formal: # Checks if formal German translation exists. # Prüft, ob formelle deutsche Übersetzung existiert.
                    ssml += self._generate_language_section( # Adds formal German section to SSML. # Fügt formellen deutschen Abschnitt zum SSML hinzu.
                        german_formal, # The sentence text. # Der Satztext.
                        german_pairs, # Word pairs for this section. # Wortpaare für diesen Abschnitt.
                        voice="de-DE-SeraphinaMultilingualNeural", # German voice to use. # Zu verwendende deutsche Stimme.
                        lang="de-DE", # German language code. # Deutscher Sprachcode.
                    )

                if english_native: # Checks if native English translation exists. # Prüft, ob muttersprachliche englische Übersetzung existiert.
                    ssml += self._generate_language_section( # Adds native English section to SSML. # Fügt muttersprachlichen englischen Abschnitt zum SSML hinzu.
                        english_native, # The sentence text. # Der Satztext.
                        english_pairs, # Word pairs for this section. # Wortpaare für diesen Abschnitt.
                        voice="en-US-JennyMultilingualNeural", # English voice to use. # Zu verwendende englische Stimme.
                        lang="en-US", # English language code. # Englischer Sprachcode.
                    )

                if english_colloquial: # Checks if colloquial English translation exists. # Prüft, ob umgangssprachliche englische Übersetzung existiert.
                    ssml += self._generate_language_section( # Adds colloquial English section to SSML. # Fügt umgangssprachlichen englischen Abschnitt zum SSML hinzu.
                        english_colloquial, # The sentence text. # Der Satztext.
                        english_pairs, # Word pairs for this section. # Wortpaare für diesen Abschnitt.
                        voice="en-US-JennyMultilingualNeural", # English voice to use. # Zu verwendende englische Stimme.
                        lang="en-US", # English language code. # Englischer Sprachcode.
                    )

                if english_informal: # Checks if informal English translation exists. # Prüft, ob informelle englische Übersetzung existiert.
                    ssml += self._generate_language_section( # Adds informal English section to SSML. # Fügt informellen englischen Abschnitt zum SSML hinzu.
                        english_informal, # The sentence text. # Der Satztext.
                        english_pairs, # Word pairs for this section. # Wortpaare für diesen Abschnitt.
                        voice="en-US-JennyNeural", # Alternative English voice for variety. # Alternative englische Stimme für Abwechslung.
                        lang="en-US", # English language code. # Englischer Sprachcode.
                    )

                if english_formal: # Checks if formal English translation exists. # Prüft, ob formelle englische Übersetzung existiert.
                    ssml += self._generate_language_section( # Adds formal English section to SSML. # Fügt formellen englischen Abschnitt zum SSML hinzu.
                        english_formal, # The sentence text. # Der Satztext.
                        english_pairs, # Word pairs for this section. # Wortpaare für diesen Abschnitt.
                        voice="en-US-JennyMultilingualNeural", # English voice to use. # Zu verwendende englische Stimme.
                        lang="en-US", # English language code. # Englischer Sprachcode.
                    )

        ssml = re.sub(r'(<break time="500ms"\s*/>\s*)+', '<break time="500ms"/>', ssml) # Removes duplicate breaks. # Entfernt doppelte Pausen.
        ssml += "</speak>" # Closes the SSML root element. # Schließt das SSML-Root-Element.
        return ssml # Returns the complete SSML. # Gibt das vollständige SSML zurück.

    def _generate_language_section( # Defines method to generate a language-specific section. # Definiert Methode zur Generierung eines sprachspezifischen Abschnitts.
        self, sentence: str, word_pairs: list[tuple[str, str]], voice: str, lang: str # Parameters for sentence, word pairs, voice and language. # Parameter für Satz, Wortpaare, Stimme und Sprache.
    ) -> str: # Returns SSML string section. # Gibt SSML-Zeichenkettenabschnitt zurück.
        """Generate complete language section with phrase handling"""
        section = f"""
        <voice name="{voice}">
            <prosody rate="1.0">
                <lang xml:lang="{lang}">{sentence}</lang>
                <break time="1000ms"/>
            </prosody>
        </voice>""" # Creates section for full sentence with specified voice and language. # Erstellt Abschnitt für vollständigen Satz mit angegebener Stimme und Sprache.

        if word_pairs: # Checks if word pairs are provided. # Prüft, ob Wortpaare bereitgestellt werden.
            section += """
        <voice name="en-US-JennyMultilingualNeural">
            <prosody rate="0.8">""" # Starts word-by-word breakdown section with slower speech rate. # Startet Wort-für-Wort-Aufschlüsselungsabschnitt mit langsamerer Sprechrate.

            # Create phrase map and sort by phrase length
            phrase_map = {src.lower(): (src, tgt) for src, tgt in word_pairs} # Creates mapping of lowercase source to original pairs. # Erstellt Zuordnung von Kleinbuchstaben-Quelle zu Original-Paaren.
            phrases = sorted( # Sorts phrases by length (longest first). # Sortiert Phrasen nach Länge (längste zuerst).
                phrase_map.keys(), key=lambda x: len(x.split()), reverse=True # Sort key is word count in descending order. # Sortierschlüssel ist Wortzahl in absteigender Reihenfolge.
            )
            words = sentence.split() # Splits sentence into words. # Teilt Satz in Wörter.
            index = 0 # Initializes word index. # Initialisiert Wortindex.

            while index < len(words): # Loops through all words in sentence. # Schleife durch alle Wörter im Satz.
                matched = False # Tracks if current position matched a phrase. # Verfolgt, ob aktuelle Position einer Phrase entspricht.

                # Try to match multi-word phrases first
                for phrase_key in phrases: # Checks each potential phrase. # Prüft jede potenzielle Phrase.
                    phrase_words = phrase_key.split() # Splits phrase into words. # Teilt Phrase in Wörter.
                    if index + len(phrase_words) > len(words): # Checks if phrase would extend beyond sentence end. # Prüft, ob Phrase über Satzende hinausgehen würde.
                        continue # Skips to next phrase. # Springt zur nächsten Phrase.

                    candidate = " ".join( # Constructs candidate phrase from sentence words. # Konstruiert Kandidatenphrase aus Satzwörtern.
                        words[index : index + len(phrase_words)] # Takes slice of words. # Nimmt Ausschnitt von Wörtern.
                    ).lower() # Converts to lowercase for comparison. # Konvertiert für Vergleich in Kleinbuchstaben.
                    if candidate == phrase_key: # Checks if candidate matches known phrase. # Prüft, ob Kandidat mit bekannter Phrase übereinstimmt.
                        original_phrase, translation = phrase_map[phrase_key] # Gets original phrase and translation. # Holt Originalphrase und Übersetzung.
                        section += f"""
            <lang xml:lang="{lang}">{original_phrase}</lang>
            <break time="300ms"/>
            <lang xml:lang="es-ES">{translation}</lang>
            <break time="500ms"/>""" # Adds phrase with its translation to SSML. # Fügt Phrase mit ihrer Übersetzung zum SSML hinzu.
                        index += len(phrase_words) # Advances index past this phrase. # Verschiebt Index über diese Phrase hinaus.
                        matched = True # Marks as matched. # Markiert als übereinstimmend.
                        break # Exits phrase search loop. # Beendet Phrasen-Suchschleife.

                # Single word fallback
                if not matched: # If no phrase matched at current position. # Wenn keine Phrase an aktueller Position übereinstimmt.
                    word = words[index].strip(".,!?") # Gets current word without punctuation. # Holt aktuelles Wort ohne Interpunktion.
                    translation = next( # Finds matching translation for this word. # Findet passende Übersetzung für dieses Wort.
                        (tgt for src, tgt in word_pairs if src.lower() == word.lower()), # Searches case-insensitively. # Sucht unabhängig von Groß-/Kleinschreibung.
                        None, # Default to None if no match found. # Standardmäßig None, wenn keine Übereinstimmung gefunden.
                    )
                    section += f"""
            <lang xml:lang="{lang}">{word}</lang>
            <break time="300ms"/>""" # Adds word to SSML. # Fügt Wort zum SSML hinzu.
                    if translation: # If translation was found. # Wenn Übersetzung gefunden wurde.
                        section += f"""
            <lang xml:lang="es-ES">{translation}</lang>
            <break time="500ms"/>""" # Adds translation to SSML. # Fügt Übersetzung zum SSML hinzu.
                    else: # If no translation was found. # Wenn keine Übersetzung gefunden wurde.
                        section += """<break time="500ms"/>""" # Adds pause only. # Fügt nur Pause hinzu.
                    index += 1 # Advances to next word. # Verschiebt zu nächstem Wort.

            section += """
            <break time="1000ms"/>
            </prosody>
        </voice>""" # Closes word-by-word section. # Schließt Wort-für-Wort-Abschnitt.

        return section # Returns the complete section. # Gibt den vollständigen Abschnitt zurück.

    def _generate_sentence_section( # Defines method to generate a sentence section. # Definiert Methode zur Generierung eines Satzabschnitts.
        self,
        sentence: str, # The sentence text. # Der Satztext.
        word_pairs: list[tuple[str, str]], # Word pairs for translation. # Wortpaare für Übersetzung.
        voice: str, # Voice to use. # Zu verwendende Stimme.
        lang: str, # Language code. # Sprachcode.
    ) -> str: # Returns SSML string section. # Gibt SSML-Zeichenkettenabschnitt zurück.
        if not sentence: # Checks if sentence is empty. # Prüft, ob Satz leer ist.
            return "" # Returns empty string for empty input. # Gibt leere Zeichenkette für leere Eingabe zurück.

        # Generate the main sentence SSML
        ssml = f"""
            <voice name="{voice}">
                <prosody rate="1.0">
                    <lang xml:lang="{lang}">{sentence}</lang>
                    <break time="1000ms"/>
                </prosody>
            </voice>""" # Creates section for full sentence. # Erstellt Abschnitt für vollständigen Satz.

        if word_pairs: # Checks if word pairs are provided. # Prüft, ob Wortpaare bereitgestellt werden.
            ssml += """
                <voice name="en-US-JennyMultilingualNeural">
                    <prosody rate="0.8">""" # Starts word-by-word breakdown with slower speech. # Startet Wort-für-Wort-Aufschlüsselung mit langsamerer Sprache.

            # Create phrase map and sort by phrase length (longest first)
            phrase_map = {src.lower(): (src, tgt) for src, tgt in word_pairs} # Creates mapping of lowercase source to original pairs. # Erstellt Zuordnung von Kleinbuchstaben-Quelle zu Original-Paaren.
            phrases = sorted( # Sorts phrases by word count (longest first). # Sortiert Phrasen nach Wortzahl (längste zuerst).
                phrase_map.keys(), key=lambda x: len(x.split()), reverse=True # Sort key is word count in descending order. # Sortierschlüssel ist Wortzahl in absteigender Reihenfolge.
            )
            words = sentence.split() # Splits sentence into words. # Teilt Satz in Wörter.
            index = 0 # Initializes word index. # Initialisiert Wortindex.

            while index < len(words): # Loops through all words in sentence. # Schleife durch alle Wörter im Satz.
                matched = False # Tracks if current position matched a phrase. # Verfolgt, ob aktuelle Position einer Phrase entspricht.

                # Try to match multi-word phrases first
                for phrase_key in phrases: # Checks each potential phrase. # Prüft jede potenzielle Phrase.
                    phrase_words = phrase_key.split() # Splits phrase into words. # Teilt Phrase in Wörter.
                    phrase_len = len(phrase_words) # Gets phrase length in words. # Holt Phrasenlänge in Wörtern.

                    if index + phrase_len <= len(words): # Checks if phrase would fit in remaining words. # Prüft, ob Phrase in verbleibende Wörter passen würde.
                        current_phrase = " ".join( # Constructs candidate phrase from sentence words. # Konstruiert Kandidatenphrase aus Satzwörtern.
                            words[index : index + phrase_len] # Takes slice of words of phrase length. # Nimmt Ausschnitt von Wörtern der Phrasenlänge.
                        ).lower() # Converts to lowercase for comparison. # Konvertiert für Vergleich in Kleinbuchstaben.
                        if current_phrase == phrase_key: # Checks if candidate matches known phrase. # Prüft, ob Kandidat mit bekannter Phrase übereinstimmt.
                            original_phrase, translation = phrase_map[phrase_key] # Gets original phrase and translation. # Holt Originalphrase und Übersetzung.
                            ssml += f"""
                                <lang xml:lang="{lang}">{original_phrase}</lang>
                                <break time="300ms"/>
                                <lang xml:lang="es-ES">{translation}</lang>
                                <break time="500ms"/>""" # Adds phrase with translation to SSML. # Fügt Phrase mit Übersetzung zum SSML hinzu.
                            index += phrase_len # Advances index past phrase. # Verschiebt Index über Phrase hinaus.
                            matched = True # Marks as matched. # Markiert als übereinstimmend.
                            break # Exits phrase search loop. # Beendet Phrasen-Suchschleife.

                # Fallback to single-word matching
                if not matched: # If no phrase matched at current position. # Wenn keine Phrase an aktueller Position übereinstimmt.
                    current_word = words[index].strip(".,!?").lower() # Gets current word without punctuation, lowercase. # Holt aktuelles Wort ohne Interpunktion, in Kleinbuchstaben.
                    original_word = words[index] # Keeps original word with punctuation. # Behält Originalwort mit Interpunktion.
                    translation = next( # Finds matching translation for this word. # Findet passende Übersetzung für dieses Wort.
                        (tgt for src, tgt in word_pairs if src.lower() == current_word), # Searches case-insensitively. # Sucht unabhängig von Groß-/Kleinschreibung.
                        None, # Default to None if no match found. # Standardmäßig None, wenn keine Übereinstimmung gefunden.
                    )

                    ssml += f"""
                        <lang xml:lang="{lang}">{original_word}</lang>
                        <break time="300ms"/>""" # Adds word to SSML. # Fügt Wort zum SSML hinzu.
                    if translation: # If translation was found. # Wenn Übersetzung gefunden wurde.
                        ssml += f"""
                            <lang xml:lang="es-ES">{translation}</lang>
                            <break time="500ms"/>""" # Adds translation to SSML. # Fügt Übersetzung zum SSML hinzu.
                    else: # If no translation was found. # Wenn keine Übersetzung gefunden wurde.
                        ssml += """<break time="500ms"/>""" # Adds pause only. # Fügt nur Pause hinzu.

                    index += 1 # Advances to next word. # Verschiebt zu nächstem Wort.

            ssml += """
                        <break time="1000ms"/>
                    </prosody>
                </voice>""" # Closes word-by-word section. # Schließt Wort-für-Wort-Abschnitt.

        return ssml # Returns the complete section. # Gibt den vollständigen Abschnitt zurück.

    async def text_to_speech_word_pairs( # Defines method to convert word pairs to speech. # Definiert Methode zur Umwandlung von Wortpaaren in Sprache.
        self,
        word_pairs: list[tuple[str, str]], # Source-target word pairs. # Quell-Ziel-Wortpaare.
        source_lang: str, # Source language code. # Quellsprachcode.
        target_lang: str, # Target language code. # Zielsprachcode.
        output_path: Optional[str] = None, # Optional custom output path. # Optionaler benutzerdefinierter Ausgabepfad.
        complete_text: Optional[str] = None,  # New parameter for full text. # Neuer Parameter für vollständigen Text.
    ) -> Optional[str]: # Returns filename or None if failed. # Gibt Dateinamen zurück oder None bei Fehlschlag.
        try: # Starts try block for error handling. # Beginnt Try-Block für Fehlerbehandlung.
            if not output_path: # Checks if output path is not provided. # Prüft, ob kein Ausgabepfad angegeben ist.
                temp_dir = self._get_temp_directory() # Gets temporary directory. # Holt temporäres Verzeichnis.
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S") # Creates timestamp for filename. # Erstellt Zeitstempel für Dateinamen.
                output_path = os.path.join(temp_dir, f"speech_{timestamp}.mp3") # Creates full output path. # Erstellt vollständigen Ausgabepfad.
                print(f"Output path: {output_path}") # Logs the output path. # Protokolliert den Ausgabepfad.

            audio_config = AudioOutputConfig(filename=output_path) # Configures audio output to file. # Konfiguriert Audio-Ausgabe in Datei.
            speech_config = SpeechConfig( # Creates speech configuration. # Erstellt Sprachkonfiguration.
                subscription=self.subscription_key, region=self.region # Sets API key and region. # Setzt API-Schlüssel und Region.
            )
            speech_config.set_speech_synthesis_output_format( # Sets audio format. # Setzt Audioformat.
                SpeechSynthesisOutputFormat.Audio16Khz32KBitRateMonoMp3 # Uses 16kHz 32kbps mono MP3. # Verwendet 16kHz 32kbps Mono-MP3.
            )

            synthesizer = SpeechSynthesizer( # Creates speech synthesizer. # Erstellt Sprachsynthesizer.
                speech_config=speech_config, audio_config=audio_config # Configures with speech and audio settings. # Konfiguriert mit Sprach- und Audioeinstellungen.
            )

            # Use the new combined SSML generator
            ssml = self.generate_enhanced_ssml( # Generates enhanced SSML. # Generiert erweitertes SSML.
                text=complete_text, # Full text content. # Vollständiger Textinhalt.
                word_pairs=word_pairs, # Word pairs for pronunciation. # Wortpaare für Aussprache.
                source_lang=source_lang, # Source language. # Quellsprache.
                target_lang=target_lang, # Target language. # Zielsprache.
            )
            print(f"Generated SSML:\n{ssml}")  # Debug output. # Debug-Ausgabe.

            result = await asyncio.get_event_loop().run_in_executor( # Runs CPU-intensive task in thread pool. # Führt CPU-intensive Aufgabe im Thread-Pool aus.
                None, lambda: synthesizer.speak_ssml_async(ssml).get() # Executes SSML synthesis and gets result. # Führt SSML-Synthese aus und holt Ergebnis.
            )

            if result.reason == ResultReason.SynthesizingAudioCompleted: # Checks if synthesis completed successfully. # Prüft, ob Synthese erfolgreich abgeschlossen wurde.
                return os.path.basename(output_path) # Returns only filename without path. # Gibt nur Dateinamen ohne Pfad zurück.

            if result.reason == ResultReason.Canceled: # Checks if synthesis was canceled. # Prüft, ob Synthese abgebrochen wurde.
                cancellation_details = result.cancellation_details # Gets cancellation details. # Holt Abbruchdetails.
                print(f"Speech synthesis canceled: {cancellation_details.reason}") # Logs cancellation reason. # Protokolliert Abbruchgrund.
                if cancellation_details.reason == CancellationReason.Error: # Checks if cancellation was due to error. # Prüft, ob Abbruch aufgrund eines Fehlers erfolgte.
                    print(f"Error details: {cancellation_details.error_details}") # Logs error details. # Protokolliert Fehlerdetails.

            return None # Returns None if synthesis didn't complete successfully. # Gibt None zurück, wenn Synthese nicht erfolgreich abgeschlossen wurde.
        except Exception as e: # Catches any exceptions. # Fängt alle Ausnahmen ab.
            print(f"Error in text_to_speech_word_pairs: {str(e)}") # Logs the error. # Protokolliert den Fehler.
            return None # Returns None on error. # Gibt None bei Fehler zurück.

    # async def text_to_speech(
    #     self, ssml: str, output_path: Optional[str] = None
    # ) -> Optional[str]:
    async def text_to_speech( # Defines method to convert SSML to speech. # Definiert Methode zur Umwandlung von SSML in Sprache.
        self, ssml: str, output_path: Optional[str] = None # SSML text and optional output path. # SSML-Text und optionaler Ausgabepfad.
    ) -> Optional[str]: # Returns filename or None if failed. # Gibt Dateinamen zurück oder None bei Fehlschlag.
        """Convert SSML to speech with proper language handling"""
        synthesizer = None # Initializes synthesizer to None for cleanup in finally block. # Initialisiert Synthesizer mit None für Bereinigung im Finally-Block.
        try: # Starts try block for error handling. # Beginnt Try-Block für Fehlerbehandlung.
            if not output_path: # Checks if output path is not provided. # Prüft, ob kein Ausgabepfad angegeben ist.
                temp_dir = self._get_temp_directory() # Gets temporary directory. # Holt temporäres Verzeichnis.
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S") # Creates timestamp for filename. # Erstellt Zeitstempel für Dateinamen.
                output_path = os.path.join(temp_dir, f"speech_{timestamp}.mp3") # Creates full output path. # Erstellt vollständigen Ausgabepfad.
                print(f"Output path: {output_path}") # Logs the output path. # Protokolliert den Ausgabepfad.

            audio_config = AudioOutputConfig(filename=output_path) # Configures audio output to file. # Konfiguriert Audio-Ausgabe in Datei.
            synthesizer = SpeechSynthesizer( # Creates speech synthesizer. # Erstellt Sprachsynthesizer.
                speech_config=self.speech_config, audio_config=audio_config # Configures with speech and audio settings. # Konfiguriert mit Sprach- und Audioeinstellungen.
            )

            result = await asyncio.get_event_loop().run_in_executor( # Runs CPU-intensive task in thread pool. # Führt CPU-intensive Aufgabe im Thread-Pool aus.
                None, lambda: synthesizer.speak_ssml_async(ssml).get() # Executes SSML synthesis and gets result. # Führt SSML-Synthese aus und holt Ergebnis.
            )

            if result.reason == ResultReason.SynthesizingAudioCompleted: # Checks if synthesis completed successfully. # Prüft, ob Synthese erfolgreich abgeschlossen wurde.
                return os.path.basename(output_path) # Returns only filename without path. # Gibt nur Dateinamen ohne Pfad zurück.

            return None # Returns None if synthesis didn't complete successfully. # Gibt None zurück, wenn Synthese nicht erfolgreich abgeschlossen wurde.

        except Exception as e: # Catches any exceptions. # Fängt alle Ausnahmen ab.
            print(f"Exception in text_to_speech: {str(e)}") # Logs the error. # Protokolliert den Fehler.
            return None # Returns None on error. # Gibt None bei Fehler zurück.
        finally: # Finally block for cleanup regardless of success/failure. # Finally-Block für Bereinigung unabhängig von Erfolg/Fehlschlag.
            if synthesizer: # Checks if synthesizer was created. # Prüft, ob Synthesizer erstellt wurde.
                try: # Nested try for cleanup. # Verschachtelter Try für Bereinigung.
                    synthesizer.stop_speaking_async() # Stops any ongoing synthesis. # Stoppt laufende Synthese.
                except: # Ignores errors during cleanup. # Ignoriert Fehler während der Bereinigung.
                    pass # Does nothing if cleanup fails. # Tut nichts, wenn Bereinigung fehlschlägt.
