
from google.generativeai import GenerativeModel
import google.generativeai as genai
import os
from dotenv import load_dotenv
from ...domain.entities.translation import Translation
from spellchecker import SpellChecker
import unicodedata
import regex as re
from .tts_service import EnhancedTTSService
import tempfile
from typing import Optional


class TranslationService:
    def __init__(self):
        load_dotenv()
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY not found in environment variables")

        genai.configure(api_key=api_key)

        self.spell = SpellChecker()

        self.generation_config = {
            "temperature": 1,
            "top_p": 0.95,
            "top_k": 40,
            "max_output_tokens": 8192,
            # "response_mime_type": "text/plain",
        }

        self.model = GenerativeModel(
            model_name="gemini-2.0-flash-exp", generation_config=self.generation_config
        )

        self.tts_service = EnhancedTTSService()

        self.chat_session = self.model.start_chat(
            history=[
                {
                    "role": "user",
                    "parts": [
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

    def _normalize_text(self, text: str) -> str:
        normalized = unicodedata.normalize("NFKD", text)
        ascii_text = normalized.encode("ascii", "ignore").decode("ascii")
        return ascii_text

    def _restore_accents(self, text: str) -> str:
        accent_map = {
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

        patterns = {
            r"([aeiou])´": lambda m: accent_map[m.group(1)],
            r"([AEIOU])´": lambda m: accent_map[m.group(1)],
            r"n~": "ñ",
            r"N~": "Ñ",
        }

        for pattern, replacement in patterns.items():
            if callable(replacement):
                text = re.sub(pattern, replacement, text)
            else:
                text = re.sub(pattern, replacement, text)

        return text

    def _ensure_unicode(self, text: str) -> str:
        if isinstance(text, bytes):
            text = text.decode("utf-8")
        return unicodedata.normalize("NFKC", text)

    def _extract_word_pairs(self, text: str) -> list[tuple[str, str]]:
        word_pairs = []
        word_by_word_pattern = r'\* word by word.*?\n"([^"]+)"'
        word_by_word_match = re.search(word_by_word_pattern, text, re.DOTALL)

        if word_by_word_match:
            word_by_word_text = word_by_word_match.group(1)
            # Improved regex to capture multi-word phrases including those with apostrophes
            parts = re.findall(r"([^()]+?)\s*\(([^)]+)\)", word_by_word_text)
            for source, target in parts:
                # Clean and normalize both phrases
                source = re.sub(r"\s+", " ", source.strip().replace("'", ""))
                target = target.strip()
                if source and target:
                    word_pairs.append((source, target))
        return word_pairs

    def _format_for_tts(
        self, word_pairs: list[tuple[str, str]], source_lang: str, target_lang: str
    ) -> str:
        lang_map = {"en": "en-US", "de": "de-DE", "es": "es-ES"}

        # Make sure to use the correct source language code for each word
        ssml = """<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
        <voice name="en-US-JennyMultilingualNeural">"""

        for source_word, target_word in word_pairs:
            source_word = source_word.strip()
            target_word = target_word.strip()

            # Use the correct source language code based on the source_lang parameter
            source_lang_code = lang_map.get(source_lang, "en-US")
            target_lang_code = lang_map.get(target_lang, "es-ES")

            ssml += f"""
            <lang xml:lang="{source_lang_code}">{source_word}</lang>
            <break time="500ms"/>
            <lang xml:lang="{target_lang_code}">{target_word}</lang>
            <break time="500ms"/>"""

        ssml += """
        </voice>
    </speak>"""
        return ssml

    async def process_prompt(
        self, text: str, source_lang: str, target_lang: str
    ) -> Translation:

        try:

            response = self.chat_session.send_message(text)
            generated_text = response.text

            print(f"Generated text from Gemini: {generated_text[:100]}...")

            translations, word_pairs = self._extract_text_and_pairs(generated_text)

            audio_filename = None

            if translations and word_pairs:

                audio_filename = await self.tts_service.text_to_speech_word_pairs(
                    word_pairs=word_pairs,
                    source_lang=source_lang,
                    target_lang=target_lang,
                    complete_text="\n".join(translations),
                )
            elif translations:

                formatted_ssml = self.tts_service.generate_enhanced_ssml(
                    text="\n".join(translations),
                    source_lang=source_lang,
                    target_lang=target_lang,
                )
                audio_filename = await self.tts_service.text_to_speech(formatted_ssml)

            if audio_filename:

                print(f"Successfully generated audio: {audio_filename}")
            else:

                print("Audio generation failed")

            return Translation(
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

        except Exception as e:

            print(f"Error in process_prompt: {str(e)}")
            raise Exception(f"Translation processing failed: {str(e)}")

    def _extract_text_and_pairs(
        self, generated_text: str
    ) -> tuple[list[str], list[tuple[str, str, bool]]]:
        """
        Extract both native, colloquial, informal, and formal texts and word pairs from generated text.
        Returns: tuple of ([texts], [(source_word, target_word, is_german)])
        """
        translations = []
        word_pairs = []

        # Patterns for German translations
        german_patterns = [
            {
                "text_pattern": r'German Translation:.*?\* Conversational-native:\s*"([^"]+)"',
                "pairs_pattern": r'\* word by word Conversational-native German-Spanish:\s*"([^"]+)"',
                "is_german": True,
            },
            {
                "text_pattern": r'\* Conversational-colloquial:\s*"([^"]+)"',
                "pairs_pattern": r'\* word by word Conversational-colloquial German-Spanish:\s*"([^"]+)"',
                "is_german": True,
            },
            {
                "text_pattern": r'\* Conversational-informal:\s*"([^"]+)"',
                "pairs_pattern": r'\* word by word Conversational-informal German-Spanish:\s*"([^"]+)"',
                "is_german": True,
            },
            {
                "text_pattern": r'\* Conversational-formal:\s*"([^"]+)"',
                "pairs_pattern": r'\* word by word Conversational-formal German-Spanish:\s*"([^"]+)"',
                "is_german": True,
            },
        ]

        # Patterns for English translations
        english_patterns = [
            {
                "text_pattern": r'English Translation:.*?\* Conversational-native:\s*"([^"]+)"',
                "pairs_pattern": r'\* word by word Conversational-native English-Spanish:\s*"([^"]+)"',
                "is_german": False,
            },
            {
                "text_pattern": r'English Translation:.*?\* Conversational-colloquial:\s*"([^"]+)"',
                "pairs_pattern": r'\* word by word Conversational-colloquial English-Spanish:\s*"([^"]+)"',
                "is_german": False,
            },
            {
                "text_pattern": r'English Translation:.*?\* Conversational-informal:\s*"([^"]+)"',
                "pairs_pattern": r'\* word by word Conversational-informal English-Spanish:\s*"([^"]+)"',
                "is_german": False,
            },
            {
                "text_pattern": r'English Translation:.*?\* Conversational-formal:\s*"([^"]+)"',
                "pairs_pattern": r'\* word by word Conversational-formal English-Spanish:\s*"([^"]+)"',
                "is_german": False,
            },
        ]

        # Combine patterns
        all_patterns = german_patterns + english_patterns

        # Extract translations and word pairs
        for pattern_set in all_patterns:
            # Extract text
            text_match = re.search(
                pattern_set["text_pattern"], generated_text, re.DOTALL | re.IGNORECASE
            )
            if text_match:
                translations.append(text_match.group(1).strip())

            # Extract word pairs
            pairs_match = re.search(
                pattern_set["pairs_pattern"], generated_text, re.IGNORECASE
            )
            if pairs_match:
                pairs_text = pairs_match.group(1)
                # More robust word pair extraction
                pair_matches = re.findall(r"(\S+)\s*\(([^)]+)\)", pairs_text)
                for source, target in pair_matches:
                    source = source.strip()
                    target = target.strip()
                    if source and target:
                        word_pairs.append((source, target, pattern_set["is_german"]))

        # Remove duplicates while preserving order
        seen_pairs = set()
        unique_pairs = []
        for pair in word_pairs:
            pair_tuple = (pair[0], pair[1], pair[2])
            if pair_tuple not in seen_pairs:
                seen_pairs.add(pair_tuple)
                unique_pairs.append(pair)

        return translations, unique_pairs

    def _extract_native_translation(self, text: str) -> Optional[str]:
        """Extract the native translation from the generated text."""

        native_pattern = r'\* Conversational-native:\s*"([^"]+)"'
        match = re.search(native_pattern, text)
        if match:
            return match.group(1)
        return None

    def _extract_colloquial_translation(self, text: str) -> Optional[str]:
        """Extract the colloquial translation from the generated text."""

        colloquial_pattern = r'\* Conversational-colloquial:\s*"([^"]+)"'
        match = re.search(colloquial_pattern, text)
        if match:
            return match.group(1)
        return None

    def _extract_informal_translation(self, text: str) -> Optional[str]:
        """Extract the informal translation from the generated text."""

        informal_pattern = r'\* Conversational-informal:\s*"([^"]+)"'
        match = re.search(informal_pattern, text)
        if match:
            return match.group(1)
        return None

    def _extract_formal_translation(self, text: str) -> Optional[str]:
        """Extract the formal translation from the generated text."""

        formal_pattern = r'\* Conversational-formal:\s*"([^"]+)"'
        match = re.search(formal_pattern, text)
        if match:
            return match.group(1)
        return None

    def _get_temp_directory(self) -> str:
        """Get the appropriate temporary directory based on the operating system."""
        if os.name == "nt":
            temp_dir = os.environ.get("TEMP") or os.environ.get("TMP")
        else:
            temp_dir = "/tmp"

        os.makedirs(temp_dir, exist_ok=True)
        return temp_dir

    def _generate_word_by_word(
        self, original: str, translated: str
    ) -> dict[str, dict[str, str]]:
        """Generate word-by-word translation mapping."""
        result = {}
        original_words = original.split()
        translated_words = translated.split()

        for i, word in enumerate(original_words):
            if i < len(translated_words):
                result[word] = {
                    "translation": translated_words[i],
                    "pos": "unknown",
                }
        return result

    def _generate_grammar_explanations(self, text: str) -> dict[str, str]:
        """Generate grammar explanations for the translation."""
        return {
            "structure": "Basic sentence structure explanation",
            "tense": "Tense usage explanation",
        }

    def _auto_fix_spelling(self, text: str) -> str:
        """Fix spelling in the given text."""
        words = re.findall(r"\b\w+\b|[^\w\s]", text)
        corrected_words = []

        for word in words:
            if not re.match(r"\w+", word):
                corrected_words.append(word)
                continue

            if self.spell.unknown([word]):
                correction = self.spell.correction(word)
                if correction:
                    if word.isupper():
                        correction = correction.upper()
                    elif word[0].isupper():
                        correction = correction.capitalize()
                    word = correction

            corrected_words.append(word)

        return " ".join(corrected_words)

