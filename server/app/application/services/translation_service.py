# TranslationService
#
# A service class that provides AI-powered translation between languages with various formality levels. # Eine Service-Klasse, die KI-gestützte Übersetzungen zwischen Sprachen mit verschiedenen Formalitätsstufen bietet.
# Features text translation, word-by-word mapping, and text-to-speech audio generation. # Bietet Textübersetzung, Wort-für-Wort-Zuordnung und Text-zu-Sprache Audiogenerierung.
#
# Usage:
# service = TranslationService() # Creates a new translation service instance. # Erstellt eine neue Übersetzungsdienst-Instanz.
# translation = await service.process_prompt("Hello world", "en", "de") # Translates text from English to German with full details. # Übersetzt Text von Englisch nach Deutsch mit vollständigen Details.
#
# EN: Leverages Google's Gemini AI model to provide multi-level translations with educational word mappings.
# DE: Nutzt Googles Gemini-KI-Modell, um mehrstufige Übersetzungen mit lehrreichen Wortzuordnungen bereitzustellen.

from google.generativeai import GenerativeModel # Imports Google's Generative AI model class. # Importiert Googles Generative-KI-Modellklasse.
import google.generativeai as genai # Imports the Google Generative AI library. # Importiert die Google Generative-KI-Bibliothek.
import os # Imports operating system functionality for environment variables. # Importiert Betriebssystemfunktionalität für Umgebungsvariablen.
from dotenv import load_dotenv # Imports load_dotenv to read environment variables from .env file. # Importiert load_dotenv zum Lesen von Umgebungsvariablen aus der .env-Datei.
from ...domain.entities.translation import Translation # Imports the Translation entity from domain layer. # Importiert die Translation-Entität aus der Domain-Schicht.
from spellchecker import SpellChecker # Imports SpellChecker for fixing spelling errors. # Importiert SpellChecker zum Beheben von Rechtschreibfehlern.
import unicodedata # Imports unicodedata for handling text normalization. # Importiert unicodedata zur Textbereinigung.
import regex as re # Imports regex for advanced pattern matching. # Importiert regex für erweiterte Mustererkennung.
from .tts_service import EnhancedTTSService # Imports the text-to-speech service. # Importiert den Text-zu-Sprache-Dienst.
import tempfile # Imports tempfile for creating temporary files. # Importiert tempfile zum Erstellen temporärer Dateien.
from typing import Optional # Imports Optional for type hinting. # Importiert Optional für Typenhinweise.


class TranslationService: # Defines the TranslationService class. # Definiert die TranslationService-Klasse.
    def __init__(self): # Initializes the TranslationService. # Initialisiert den TranslationService.
        load_dotenv() # Loads environment variables from .env file. # Lädt Umgebungsvariablen aus der .env-Datei.
        api_key = os.getenv("GEMINI_API_KEY") # Gets the Gemini API key from environment variables. # Holt den Gemini-API-Schlüssel aus den Umgebungsvariablen.
        if not api_key: # Checks if the API key is missing. # Prüft, ob der API-Schlüssel fehlt.
            raise ValueError("GEMINI_API_KEY not found in environment variables") # Raises an error if API key is missing. # Löst einen Fehler aus, wenn der API-Schlüssel fehlt.

        genai.configure(api_key=api_key) # Configures the Generative AI library with the API key. # Konfiguriert die Generative-KI-Bibliothek mit dem API-Schlüssel.

        self.spell = SpellChecker() # Creates a spell checker instance. # Erstellt eine Rechtschreibprüfungs-Instanz.

        self.generation_config = { # Configures parameters for the AI model generation. # Konfiguriert Parameter für die KI-Modellerzeugung.
            "temperature": 1, # Sets creativity level (higher = more creative). # Setzt die Kreativitätsstufe (höher = kreativer).
            "top_p": 0.95, # Sets probability threshold for token selection. # Setzt die Wahrscheinlichkeitsschwelle für die Token-Auswahl.
            "top_k": 40, # Sets the number of highest probability tokens to consider. # Setzt die Anzahl der zu berücksichtigenden Token mit höchster Wahrscheinlichkeit.
            "max_output_tokens": 8192, # Sets maximum response length. # Setzt die maximale Antwortlänge.
            # "response_mime_type": "text/plain", # Commented out MIME type specification. # Auskommentierte MIME-Typ-Spezifikation.
        }

        self.model = GenerativeModel( # Creates the Generative AI model instance. # Erstellt die Generative-KI-Modellinstanz.
            model_name="gemini-2.0-flash-exp", generation_config=self.generation_config # Uses Gemini 2.0 Flash experimental model with custom config. # Verwendet Gemini 2.0 Flash-Experimentalmodell mit benutzerdefinierter Konfiguration.
        )

        self.tts_service = EnhancedTTSService() # Creates an enhanced text-to-speech service instance. # Erstellt eine erweiterte Text-zu-Sprache-Dienstinstanz.

        self.chat_session = self.model.start_chat( # Initializes a chat session with the AI model. # Initialisiert eine Chat-Sitzung mit dem KI-Modell.
            history=[ # Sets initial chat history with prompting instructions. # Setzt die anfängliche Chat-Historie mit Anweisungen.
                {
                    "role": "user", # Sets the role as user for the initial message. # Setzt die Rolle als Benutzer für die erste Nachricht.
                    "parts": [ # Contains the prompt parts. # Enthält die Aufforderungsteile.
                        """Text  
(Could be any phrase or word)  
<example to follow>  

Important: When translating phrasal verbs or idioms (e.g., 'wank off', 'come up with'), group them as single units in the word-by-word sections. 


German Translation:  
* Conversational-native:  
"Ich suche einen Job, damit ich finanziell unabhängig sein kann."  
* word by word Conversational-native German-Spanish:  
"Ich (Yo) suche (busco) einen (un) Job (trabajo), damit (para que) ich (yo) finanziell (económicamente) unabhängig (independiente) sein (ser) kann (pueda)."  

* Conversational-colloquial:  
"Ich suche einen Job, um finanziell auf eigenen Beinen zu stehen."  
* word by word Conversational-colloquial German-Spanish:  
"Ich (Yo) suche (busco) einen (un) Job (trabajo), um (para) finanziell (económicamente) auf (sobre) eigenen (propios) Beinen (pies) zu stehen (estar de pie)."  

* Conversational-informal:
"Ich suche 'nen Job, um finanziell unabhängig zu sein."
* word by word Conversational-informal German-Spanish:
"Ich (Yo) suche ('nen) Job (trabajo), um (para) finanziell (económicamente) unabhängig (independiente) zu sein (ser)."

* conversational-formal:
"Ich suche eine Anstellung, um finanziell unabhängig zu sein."
* word by word Conversational-formal German-Spanish:
"Ich (Yo) suche (busco) eine (una) Anstellung (empleo), um (para) finanziell (económicamente) unabhängig (independiente) zu sein (ser)."

English Translation:  
* Conversational-native:  
"I'm looking for a job so I can be financially independent."  
* word by word Conversational-native English-Spanish:  
"I'm (Yo estoy) looking for (buscando) a job (un trabajo) so (para que) I (yo) can be (pueda ser) financially (económicamente) independent (independiente)."  

* Conversational-colloquial:  
"I'm looking for a job to stand on my own two feet financially."  
* word by word Conversational-colloquial English-Spanish:  
"I'm (Yo estoy) looking for (buscando) a job (un trabajo) to (para) stand on my own two feet (sobre mis propios pies) financially (económicamente)."  

* Conversational-informal:
"I'm looking for a job to be financially independent."
* word by word Conversational-informal English-Spanish:
"I'm (Yo estoy) looking for (buscando) a job (un trabajo) to (para) be (ser) financially (económicamente) independent (independiente)."

* conversational-formal:
"I'm looking for a position to be financially independent."
* word by word Conversational-formal English-Spanish:
"I'm (Yo estoy) looking for (buscando) a position (una posición) to (para) be (ser) financially (económicamente) independent (independiente)."


</example to follow>  
"""
                    ],
                }
            ]
        )

    def _normalize_text(self, text: str) -> str: # Defines method to normalize Unicode text to ASCII. # Definiert eine Methode zur Normalisierung von Unicode-Text in ASCII.
        normalized = unicodedata.normalize("NFKD", text) # Normalizes text by decomposing characters. # Normalisiert Text durch Zerlegung von Zeichen.
        ascii_text = normalized.encode("ascii", "ignore").decode("ascii") # Converts to ASCII by removing non-ASCII characters. # Konvertiert zu ASCII durch Entfernen von Nicht-ASCII-Zeichen.
        return ascii_text # Returns the normalized ASCII text. # Gibt den normalisierten ASCII-Text zurück.

    def _restore_accents(self, text: str) -> str: # Defines method to restore accents in text. # Definiert eine Methode zur Wiederherstellung von Akzenten im Text.
        accent_map = { # Maps basic characters to their accented versions. # Ordnet grundlegende Zeichen ihren akzentuierten Versionen zu.
            "a": "á",
            "e": "é",
            "i": "í",
            "o": "ó",
            "u": "ú",
            "n": "ñ",
            "A": "Á",
            "E": "É",
            "I": "Í",
            "O": "Ó",
            "U": "Ú",
            "N": "Ñ",
        }

        patterns = { # Defines patterns to match accent placeholder notations. # Definiert Muster, um Akzent-Platzhalternotationen zu erkennen.
            r"([aeiou])´": lambda m: accent_map[m.group(1)], # Pattern for vowel followed by acute accent. # Muster für Vokal gefolgt von Akut-Akzent.
            r"([AEIOU])´": lambda m: accent_map[m.group(1)], # Pattern for uppercase vowel followed by acute accent. # Muster für Großbuchstaben-Vokal gefolgt von Akut-Akzent.
            r"n~": "ñ", # Pattern for Spanish eñe placeholder. # Muster für spanischen Eñe-Platzhalter.
            r"N~": "Ñ", # Pattern for uppercase Spanish eñe placeholder. # Muster für großgeschriebenen spanischen Eñe-Platzhalter.
        }

        for pattern, replacement in patterns.items(): # Iterates through each pattern-replacement pair. # Iteriert durch jedes Muster-Ersetzungs-Paar.
            if callable(replacement): # Checks if replacement is a function. # Prüft, ob die Ersetzung eine Funktion ist.
                text = re.sub(pattern, replacement, text) # Applies functional replacement. # Wendet funktionale Ersetzung an.
            else:
                text = re.sub(pattern, replacement, text) # Applies string replacement. # Wendet Zeichenkettenersetzung an.

        return text # Returns text with restored accents. # Gibt Text mit wiederhergestellten Akzenten zurück.

    def _ensure_unicode(self, text: str) -> str: # Defines method to ensure text is in Unicode format. # Definiert eine Methode, um sicherzustellen, dass Text im Unicode-Format ist.
        if isinstance(text, bytes): # Checks if text is in bytes format. # Prüft, ob Text im Bytes-Format ist.
            text = text.decode("utf-8") # Decodes bytes to UTF-8 string. # Dekodiert Bytes in UTF-8-Zeichenkette.
        return unicodedata.normalize("NFKC", text) # Normalizes to composed form (combines characters). # Normalisiert zur zusammengesetzten Form (kombiniert Zeichen).

    def _extract_word_pairs(self, text: str) -> list[tuple[str, str]]: # Defines method to extract word pairs from translation text. # Definiert eine Methode zum Extrahieren von Wortpaaren aus Übersetzungstext.
        word_pairs = [] # Initializes empty list for word pairs. # Initialisiert leere Liste für Wortpaare.
        word_by_word_pattern = r'\* word by word.*?\n"([^"]+)"' # Regex pattern to find word-by-word translation sections. # Regex-Muster zum Finden von Wort-für-Wort-Übersetzungsabschnitten.
        word_by_word_match = re.search(word_by_word_pattern, text, re.DOTALL) # Searches for word-by-word pattern in text. # Sucht nach Wort-für-Wort-Muster im Text.

        if word_by_word_match: # If a word-by-word section is found. # Wenn ein Wort-für-Wort-Abschnitt gefunden wird.
            word_by_word_text = word_by_word_match.group(1) # Extracts the word-by-word text. # Extrahiert den Wort-für-Wort-Text.
            # Improved regex to capture multi-word phrases including those with apostrophes
            parts = re.findall(r"([^()]+?)\s*\(([^)]+)\)", word_by_word_text) # Finds all source-target word pairs. # Findet alle Quell-Ziel-Wortpaare.
            for source, target in parts: # Iterates through each source-target pair. # Iteriert durch jedes Quell-Ziel-Paar.
                # Clean and normalize both phrases
                source = re.sub(r"\s+", " ", source.strip().replace("'", "")) # Normalizes source word spacing and removes apostrophes. # Normalisiert Quellwort-Leerzeichen und entfernt Apostrophe.
                target = target.strip() # Removes leading/trailing whitespace from target word. # Entfernt führende/nachfolgende Leerzeichen vom Zielwort.
                if source and target: # If both source and target are non-empty. # Wenn sowohl Quelle als auch Ziel nicht leer sind.
                    word_pairs.append((source, target)) # Adds the pair to the result list. # Fügt das Paar zur Ergebnisliste hinzu.
        return word_pairs # Returns the list of word pairs. # Gibt die Liste der Wortpaare zurück.

    def _format_for_tts(
        self, word_pairs: list[tuple[str, str]], source_lang: str, target_lang: str
    ) -> str: # Defines method to format word pairs as SSML for text-to-speech. # Definiert eine Methode zur Formatierung von Wortpaaren als SSML für Text-zu-Sprache.
        lang_map = {"en": "en-US", "de": "de-DE", "es": "es-ES"} # Maps language codes to TTS language codes. # Ordnet Sprachcodes den TTS-Sprachcodes zu.

        # Make sure to use the correct source language code for each word
        ssml = """<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
        <voice name="en-US-JennyMultilingualNeural">""" # Starts the SSML document with a multilingual voice. # Beginnt das SSML-Dokument mit einer mehrsprachigen Stimme.

        for source_word, target_word in word_pairs: # Iterates through each source-target word pair. # Iteriert durch jedes Quell-Ziel-Wortpaar.
            source_word = source_word.strip() # Trims the source word. # Trimmt das Quellwort.
            target_word = target_word.strip() # Trims the target word. # Trimmt das Zielwort.

            # Use the correct source language code based on the source_lang parameter
            source_lang_code = lang_map.get(source_lang, "en-US") # Gets the source language code or defaults to en-US. # Holt den Quellsprachcode oder setzt Standard auf en-US.
            target_lang_code = lang_map.get(target_lang, "es-ES") # Gets the target language code or defaults to es-ES. # Holt den Zielsprachcode oder setzt Standard auf es-ES.

            ssml += f"""
            <lang xml:lang="{source_lang_code}">{source_word}</lang>
            <break time="500ms"/>
            <lang xml:lang="{target_lang_code}">{target_word}</lang>
            <break time="500ms"/>""" # Adds each word pair to SSML with language tags and pauses. # Fügt jedes Wortpaar mit Sprachtags und Pausen zum SSML hinzu.

        ssml += """
        </voice>
    </speak>""" # Closes the SSML tags. # Schließt die SSML-Tags.
        return ssml # Returns the complete SSML document. # Gibt das vollständige SSML-Dokument zurück.

    async def process_prompt(
        self, text: str, source_lang: str, target_lang: str
    ) -> Translation: # Defines the main method to process a translation request. # Definiert die Hauptmethode zur Verarbeitung einer Übersetzungsanfrage.

        try: # Begins error handling block. # Beginnt einen Fehlerbehandlungsblock.

            response = self.chat_session.send_message(text) # Sends text to AI model for translation. # Sendet Text zur Übersetzung an das KI-Modell.
            generated_text = response.text # Gets the generated translation text. # Holt den generierten Übersetzungstext.

            print(f"Generated text from Gemini: {generated_text[:100]}...") # Logs the first 100 characters of the generated text. # Protokolliert die ersten 100 Zeichen des generierten Textes.

            translations, word_pairs = self._extract_text_and_pairs(generated_text) # Extracts translations and word pairs from AI response. # Extrahiert Übersetzungen und Wortpaare aus der KI-Antwort.

            audio_filename = None # Initializes audio filename to None. # Initialisiert den Audio-Dateinamen auf None.

            if translations and word_pairs: # If both translations and word pairs are available. # Wenn sowohl Übersetzungen als auch Wortpaare verfügbar sind.

                audio_filename = await self.tts_service.text_to_speech_word_pairs( # Generates audio from word pairs. # Erzeugt Audio aus Wortpaaren.
                    word_pairs=word_pairs,
                    source_lang=source_lang,
                    target_lang=target_lang,
                    complete_text="\n".join(translations),
                )
            elif translations: # If only translations are available (no word pairs). # Wenn nur Übersetzungen verfügbar sind (keine Wortpaare).

                formatted_ssml = self.tts_service.generate_enhanced_ssml( # Generates enhanced SSML for translations. # Erzeugt erweitertes SSML für Übersetzungen.
                    text="\n".join(translations),
                    source_lang=source_lang,
                    target_lang=target_lang,
                )
                audio_filename = await self.tts_service.text_to_speech(formatted_ssml) # Converts SSML to speech. # Konvertiert SSML zu Sprache.

            if audio_filename: # If audio was successfully generated. # Wenn Audio erfolgreich erzeugt wurde.

                print(f"Successfully generated audio: {audio_filename}") # Logs successful audio generation. # Protokolliert erfolgreiche Audioerzeugung.
            else: # If audio generation failed. # Wenn die Audioerzeugung fehlgeschlagen ist.

                print("Audio generation failed") # Logs audio generation failure. # Protokolliert Fehler bei der Audioerzeugung.

            return Translation( # Creates and returns a Translation object with all results. # Erstellt und gibt ein Übersetzungsobjekt mit allen Ergebnissen zurück.
                original_text=text,
                translated_text=generated_text,
                source_language=source_lang,
                target_language=target_lang,
                audio_path=audio_filename if audio_filename else None,
                translations={
                    "main": translations[0] if translations else generated_text
                },
                word_by_word=self._generate_word_by_word(text, generated_text),
                grammar_explanations=self._generate_grammar_explanations(
                    generated_text
                ),
            )

        except Exception as e: # Catches any exceptions during processing. # Fängt alle Ausnahmen während der Verarbeitung ab.

            print(f"Error in process_prompt: {str(e)}") # Logs the error message. # Protokolliert die Fehlermeldung.
            raise Exception(f"Translation processing failed: {str(e)}") # Re-raises exception with context. # Wirft Ausnahme mit Kontext erneut.

    def _extract_text_and_pairs(
        self, generated_text: str
    ) -> tuple[list[str], list[tuple[str, str, bool]]]: # Defines method to extract translations and word pairs with language flag. # Definiert eine Methode zum Extrahieren von Übersetzungen und Wortpaaren mit Sprachflagge.
        """
        Extract both native, colloquial, informal, and formal texts and word pairs from generated text.
        Returns: tuple of ([texts], [(source_word, target_word, is_german)])
        """
        translations = [] # Initializes empty list for translations. # Initialisiert leere Liste für Übersetzungen.
        word_pairs = [] # Initializes empty list for word pairs. # Initialisiert leere Liste für Wortpaare.

        # Patterns for German translations
        german_patterns = [ # Defines patterns to extract German translations of different styles. # Definiert Muster zur Extraktion deutscher Übersetzungen verschiedener Stile.
            {
                "text_pattern": r'German Translation:.*?\* Conversational-native:\s*"([^"]+)"', # Pattern for native German. # Muster für muttersprachliches Deutsch.
                "pairs_pattern": r'\* word by word Conversational-native German-Spanish:\s*"([^"]+)"', # Pattern for native German word pairs. # Muster für muttersprachliche deutsche Wortpaare.
                "is_german": True, # Flags as German translation. # Kennzeichnet als deutsche Übersetzung.
            },
            {
                "text_pattern": r'\* Conversational-colloquial:\s*"([^"]+)"', # Pattern for colloquial German. # Muster für umgangssprachliches Deutsch.
                "pairs_pattern": r'\* word by word Conversational-colloquial German-Spanish:\s*"([^"]+)"', # Pattern for colloquial German word pairs. # Muster für umgangssprachliche deutsche Wortpaare.
                "is_german": True, # Flags as German translation. # Kennzeichnet als deutsche Übersetzung.
            },
            {
                "text_pattern": r'\* Conversational-informal:\s*"([^"]+)"', # Pattern for informal German. # Muster für informelles Deutsch.
                "pairs_pattern": r'\* word by word Conversational-informal German-Spanish:\s*"([^"]+)"', # Pattern for informal German word pairs. # Muster für informelle deutsche Wortpaare.
                "is_german": True, # Flags as German translation. # Kennzeichnet als deutsche Übersetzung.
            },
            {
                "text_pattern": r'\* Conversational-formal:\s*"([^"]+)"', # Pattern for formal German. # Muster für formelles Deutsch.
                "pairs_pattern": r'\* word by word Conversational-formal German-Spanish:\s*"([^"]+)"', # Pattern for formal German word pairs. # Muster für formelle deutsche Wortpaare.
                "is_german": True, # Flags as German translation. # Kennzeichnet als deutsche Übersetzung.
            },
        ]

        # Patterns for English translations
        english_patterns = [ # Defines patterns to extract English translations of different styles. # Definiert Muster zur Extraktion englischer Übersetzungen verschiedener Stile.
            {
                "text_pattern": r'English Translation:.*?\* Conversational-native:\s*"([^"]+)"', # Pattern for native English. # Muster für muttersprachliches Englisch.
                "pairs_pattern": r'\* word by word Conversational-native English-Spanish:\s*"([^"]+)"', # Pattern for native English word pairs. # Muster für muttersprachliche englische Wortpaare.
                "is_german": False, # Flags as English translation. # Kennzeichnet als englische Übersetzung.
            },
            {
                "text_pattern": r'English Translation:.*?\* Conversational-colloquial:\s*"([^"]+)"', # Pattern for colloquial English. # Muster für umgangssprachliches Englisch.
                "pairs_pattern": r'\* word by word Conversational-colloquial English-Spanish:\s*"([^"]+)"', # Pattern for colloquial English word pairs. # Muster für umgangssprachliche englische Wortpaare.
                "is_german": False, # Flags as English translation. # Kennzeichnet als englische Übersetzung.
            },
            {
                "text_pattern": r'English Translation:.*?\* Conversational-informal:\s*"([^"]+)"', # Pattern for informal English. # Muster für informelles Englisch.
                "pairs_pattern": r'\* word by word Conversational-informal English-Spanish:\s*"([^"]+)"', # Pattern for informal English word pairs. # Muster für informelle englische Wortpaare.
                "is_german": False, # Flags as English translation. # Kennzeichnet als englische Übersetzung.
            },
            {
                "text_pattern": r'English Translation:.*?\* Conversational-formal:\s*"([^"]+)"', # Pattern for formal English. # Muster für formelles Englisch.
                "pairs_pattern": r'\* word by word Conversational-formal English-Spanish:\s*"([^"]+)"', # Pattern for formal English word pairs. # Muster für formelle englische Wortpaare.
                "is_german": False, # Flags as English translation. # Kennzeichnet als englische Übersetzung.
            },
        ]

        # Combine patterns
        all_patterns = german_patterns + english_patterns # Combines German and English patterns. # Kombiniert deutsche und englische Muster.

        # Extract translations and word pairs
        for pattern_set in all_patterns: # Iterates through each pattern set. # Iteriert durch jedes Mustersatz.
            # Extract text
            text_match = re.search(
                pattern_set["text_pattern"], generated_text, re.DOTALL | re.IGNORECASE
            ) # Searches for translation text using pattern. # Sucht nach Übersetzungstext mit Muster.
            if text_match: # If matching text is found. # Wenn übereinstimmender Text gefunden wird.
                translations.append(text_match.group(1).strip()) # Adds the matched translation to the list. # Fügt die gefundene Übersetzung zur Liste hinzu.

            # Extract word pairs
            pairs_match = re.search(
                pattern_set["pairs_pattern"], generated_text, re.IGNORECASE
            ) # Searches for word pairs using pattern. # Sucht nach Wortpaaren mit Muster.
            if pairs_match: # If matching pairs are found. # Wenn übereinstimmende Paare gefunden werden.
                pairs_text = pairs_match.group(1) # Gets the matched pairs text. # Holt den gefundenen Paartext.
                # More robust word pair extraction
                pair_matches = re.findall(r"(\S+)\s*\(([^)]+)\)", pairs_text) # Extracts individual word pairs. # Extrahiert einzelne Wortpaare.
                for source, target in pair_matches: # Iterates through each source-target pair. # Iteriert durch jedes Quell-Ziel-Paar.
                    source = source.strip() # Trims the source word. # Trimmt das Quellwort.
                    target = target.strip() # Trims the target word. # Trimmt das Zielwort.
                    if source and target: # If both source and target are non-empty. # Wenn sowohl Quelle als auch Ziel nicht leer sind.
                        word_pairs.append((source, target, pattern_set["is_german"])) # Adds the pair with language flag to result list. # Fügt das Paar mit Sprachflagge zur Ergebnisliste hinzu.

        # Remove duplicates while preserving order
        seen_pairs = set() # Creates a set to track seen pairs. # Erstellt ein Set zum Verfolgen gesehener Paare.
        unique_pairs = [] # Initializes list for unique pairs. # Initialisiert Liste für eindeutige Paare.
        for pair in word_pairs: # Iterates through each word pair. # Iteriert durch jedes Wortpaar.
            pair_tuple = (pair[0], pair[1], pair[2]) # Creates a tuple from the pair. # Erstellt ein Tupel aus dem Paar.
            if pair_tuple not in seen_pairs: # If this pair hasn't been seen before. # Wenn dieses Paar noch nicht gesehen wurde.
                seen_pairs.add(pair_tuple) # Adds pair to seen set. # Fügt Paar zum gesehenen Set hinzu.
                unique_pairs.append(pair) # Adds pair to unique result list. # Fügt Paar zur eindeutigen Ergebnisliste hinzu.

        return translations, unique_pairs # Returns translations and unique word pairs. # Gibt Übersetzungen und eindeutige Wortpaare zurück.

    def _extract_native_translation(self, text: str) -> Optional[str]: # Defines method to extract native translation. # Definiert eine Methode zum Extrahieren der muttersprachlichen Übersetzung.
        """Extract the native translation from the generated text."""

        native_pattern = r'\* Conversational-native:\s*"([^"]+)"' # Pattern to find native translation. # Muster zum Finden der muttersprachlichen Übersetzung.
        match = re.search(native_pattern, text) # Searches for the pattern. # Sucht nach dem Muster.
        if match: # If a match is found. # Wenn eine Übereinstimmung gefunden wird.
            return match.group(1) # Returns the matched translation. # Gibt die gefundene Übersetzung zurück.
        return None # Returns None if no match found. # Gibt None zurück, wenn keine Übereinstimmung gefunden wurde.

    def _extract_colloquial_translation(self, text: str) -> Optional[str]: # Defines method to extract colloquial translation. # Definiert eine Methode zum Extrahieren der umgangssprachlichen Übersetzung.
        """Extract the colloquial translation from the generated text."""

        colloquial_pattern = r'\* Conversational-colloquial:\s*"([^"]+)"' # Pattern to find colloquial translation. # Muster zum Finden der umgangssprachlichen Übersetzung.
        match = re.search(colloquial_pattern, text) # Searches for the pattern. # Sucht nach dem Muster.
        if match: # If a match is found. # Wenn eine Übereinstimmung gefunden wird.
            return match.group(1) # Returns the matched translation. # Gibt die gefundene Übersetzung zurück.
        return None # Returns None if no match found. # Gibt None zurück, wenn keine Übereinstimmung gefunden wurde.

    def _extract_informal_translation(self, text: str) -> Optional[str]: # Defines method to extract informal translation. # Definiert eine Methode zum Extrahieren der informellen Übersetzung.
        """Extract the informal translation from the generated text."""

        informal_pattern = r'\* Conversational-informal:\s*"([^"]+)"' # Pattern to find informal translation. # Muster zum Finden der informellen Übersetzung.
        match = re.search(informal_pattern, text) # Searches for the pattern. # Sucht nach dem Muster.
        if match: # If a match is found. # Wenn eine Übereinstimmung gefunden wird.
            return match.group(1) # Returns the matched translation. # Gibt die gefundene Übersetzung zurück.
        return None # Returns None if no match found. # Gibt None zurück, wenn keine Übereinstimmung gefunden wurde.

    def _extract_formal_translation(self, text: str) -> Optional[str]: # Defines method to extract formal translation. # Definiert eine Methode zum Extrahieren der formellen Übersetzung.
        """Extract the formal translation from the generated text."""

        formal_pattern = r'\* Conversational-formal:\s*"([^"]+)"' # Pattern to find formal translation. # Muster zum Finden der formellen Übersetzung.
        match = re.search(formal_pattern, text) # Searches for the pattern. # Sucht nach dem Muster.
        if match: # If a match is found. # Wenn eine Übereinstimmung gefunden wird.
            return match.group(1) # Returns the matched translation. # Gibt die gefundene Übersetzung zurück.
        return None # Returns None if no match found. # Gibt None zurück, wenn keine Übereinstimmung gefunden wurde.

    def _get_temp_directory(self) -> str: # Defines method to get temporary directory path. # Definiert eine Methode zum Abrufen des temporären Verzeichnispfads.
        """Get the appropriate temporary directory based on the operating system."""
        if os.name == "nt": # Checks if running on Windows. # Prüft, ob auf Windows ausgeführt wird.
            temp_dir = os.environ.get("TEMP") or os.environ.get("TMP") # Gets Windows temp directory from environment. # Holt Windows-Temp-Verzeichnis aus der Umgebung.
        else: # If not Windows (Linux/Mac). # Wenn nicht Windows (Linux/Mac).
            temp_dir = "/tmp" # Uses standard Unix temp directory. # Verwendet Standard-Unix-Temp-Verzeichnis.

        os.makedirs(temp_dir, exist_ok=True) # Creates the directory if it doesn't exist. # Erstellt das Verzeichnis, falls es nicht existiert.
        return temp_dir # Returns the temporary directory path. # Gibt den temporären Verzeichnispfad zurück.

    def _generate_word_by_word(
        self, original: str, translated: str
    ) -> dict[str, dict[str, str]]: # Defines method to generate word-by-word mapping. # Definiert eine Methode zur Generierung einer Wort-für-Wort-Zuordnung.
        """Generate word-by-word translation mapping."""
        result = {} # Initializes empty result dictionary. # Initialisiert leeres Ergebniswörterbuch.
        original_words = original.split() # Splits original text into words. # Teilt Originaltext in Wörter auf.
        translated_words = translated.split() # Splits translated text into words. # Teilt übersetzten Text in Wörter auf.

        for i, word in enumerate(original_words): # Iterates through each word in original text with index. # Iteriert durch jedes Wort im Originaltext mit Index.
            if i < len(translated_words): # If there's a corresponding word in translation. # Wenn es ein entsprechendes Wort in der Übersetzung gibt.
                result[word] = { # Creates mapping for this word. # Erstellt Zuordnung für dieses Wort.
                    "translation": translated_words[i], # Maps to the corresponding translated word. # Ordnet dem entsprechenden übersetzten Wort zu.
                    "pos": "unknown", # Sets part of speech to unknown. # Setzt Wortart auf unbekannt.
                }
        return result # Returns the word-by-word mapping. # Gibt die Wort-für-Wort-Zuordnung zurück.

    def _generate_grammar_explanations(self, text: str) -> dict[str, str]: # Defines method to generate grammar explanations. # Definiert eine Methode zur Generierung von Grammatikerklärungen.
        """Generate grammar explanations for the translation."""
        return { # Returns placeholder grammar explanations. # Gibt Platzhalter-Grammatikerklärungen zurück.
            "structure": "Basic sentence structure explanation", # Placeholder for sentence structure explanation. # Platzhalter für Satzstrukturerklärung.
            "tense": "Tense usage explanation", # Placeholder for tense explanation. # Platzhalter für Zeitformenerklärung.
        }

    def _auto_fix_spelling(self, text: str) -> str: # Defines method to automatically fix spelling errors. # Definiert eine Methode zur automatischen Behebung von Rechtschreibfehlern.
        """Fix spelling in the given text."""
        words = re.findall(r"\b\w+\b|[^\w\s]", text) # Splits text into words and punctuation. # Teilt Text in Wörter und Interpunktion auf.
        corrected_words = [] # Initializes list for corrected words. # Initialisiert Liste für korrigierte Wörter.

        for word in words: # Iterates through each word. # Iteriert durch jedes Wort.
            if not re.match(r"\w+", word): # If not a word (punctuation). # Wenn kein Wort (Interpunktion).
                corrected_words.append(word) # Adds unchanged to result. # Fügt unverändert zum Ergebnis hinzu.
                continue # Skips to next word. # Springt zum nächsten Wort.

            if self.spell.unknown([word]): # If word is not in dictionary. # Wenn Wort nicht im Wörterbuch ist.
                correction = self.spell.correction(word) # Gets spelling correction. # Holt Rechtschreibkorrektur.
                if correction: # If correction is available. # Wenn Korrektur verfügbar ist.
                    if word.isupper(): # If word is all uppercase. # Wenn Wort in Großbuchstaben ist.
                        correction = correction.upper() # Makes correction uppercase. # Macht Korrektur in Großbuchstaben.
                    elif word[0].isupper(): # If word is capitalized. # Wenn Wort großgeschrieben ist.
                        correction = correction.capitalize() # Capitalizes correction. # Schreibt Korrektur groß.
                    word = correction # Replaces word with correction. # Ersetzt Wort durch Korrektur.

            corrected_words.append(word) # Adds word to result list. # Fügt Wort zur Ergebnisliste hinzu.

        return " ".join(corrected_words) # Joins corrected words into text. # Verbindet korrigierte Wörter zu Text.
