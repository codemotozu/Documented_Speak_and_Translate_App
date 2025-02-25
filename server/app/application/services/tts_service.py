
from azure.cognitiveservices.speech import (
    SpeechConfig,
    SpeechSynthesizer,
    SpeechSynthesisOutputFormat,
    ResultReason,
    CancellationReason,
)
from azure.cognitiveservices.speech.audio import AudioOutputConfig
import os
from typing import Optional
from datetime import datetime
import asyncio
import re

from asyncio import Semaphore
import time


class EnhancedTTSService:
    def __init__(self):
        # Initialize Speech Config
        self.subscription_key = os.getenv("AZURE_SPEECH_KEY")
        self.region = os.getenv("AZURE_SPEECH_REGION")

        if not self.subscription_key or not self.region:
            raise ValueError(
                "Azure Speech credentials not found in environment variables"
            )

        # Add this before creating SpeechConfig
        os.environ["SPEECH_CONTAINER_OPTION"] = "1"  # Explicit container mode
        os.environ["SPEECH_SYNTHESIS_PLATFORM_CONFIG"] = "container"
        
        # # Create speech config
        # self.speech_config = SpeechConfig(
        #     subscription=self.subscription_key, region=self.region
        # )
        
        # Create speech config with endpoint (important for containers)
        self.speech_host = f"wss://{self.region}.tts.speech.microsoft.com/cognitiveservices/websocket/v1"
        self.speech_config = SpeechConfig(
            subscription=self.subscription_key,
            # region=self.region,
            endpoint=self.speech_host
        )
        
        self.speech_config.set_speech_synthesis_output_format(
            SpeechSynthesisOutputFormat.Audio16Khz32KBitRateMonoMp3
        )

        # Force CPU usage in container environment
        tts_device = os.getenv("TTS_DEVICE", "cpu").lower()
        # In container environments, always use CPU regardless of what is set
        if os.getenv("CONTAINER_ENV", "false").lower() == "true":
            tts_device = "cpu"
            
        print(f"Using TTS device: {tts_device}")

        # Voice mapping with specific styles and roles
        self.voice_mapping = {
            "en": "en-US-JennyMultilingualNeural",
            "es": "es-ES-ArabellaMultilingualNeural",
            "de": "de-DE-SeraphinaMultilingualNeural",
        }

    async def _execute_speech_synthesis(
        self, ssml: str, output_path: Optional[str] = None
    ) -> Optional[str]:
        """Execute the speech synthesis with proper resource cleanup"""
        synthesizer = None
        try:
            if not output_path:
                temp_dir = self._get_temp_directory()
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                output_path = os.path.join(temp_dir, f"speech_{timestamp}.mp3")

            audio_config = AudioOutputConfig(filename=output_path)
            synthesizer = SpeechSynthesizer(
                speech_config=self.speech_config, audio_config=audio_config
            )

            result = await asyncio.get_event_loop().run_in_executor(
                None, lambda: synthesizer.speak_ssml_async(ssml).get()
            )

            if result.reason == ResultReason.SynthesizingAudioCompleted:
                return os.path.basename(output_path)

            if result.reason == ResultReason.Canceled:
                cancellation_details = result.cancellation_details
                error_message = (
                    f"Speech synthesis canceled: {cancellation_details.reason}"
                )
                if cancellation_details.reason == CancellationReason.Error:
                    error_message += (
                        f"\nError details: {cancellation_details.error_details}"
                    )
                raise Exception(error_message)

            return None

        finally:
            if synthesizer:
                try:
                    synthesizer.stop_speaking_async()
                except:
                    pass

    def _get_temp_directory(self) -> str:
        """Create and return the temporary directory path"""
        if os.name == "nt":  # Windows
            temp_dir = os.path.join(os.environ.get("TEMP", ""), "tts_audio")
        else:  # Unix/Linux
            temp_dir = "/tmp/tts_audio"
        os.makedirs(temp_dir, exist_ok=True)
        return temp_dir

    def _detect_language(self, text: str) -> str:
        """Detect the primary language of the text"""
        # Simple language detection based on character patterns
        if re.search(r"[äöüßÄÖÜ]", text):
            return "de"
        elif re.search(r"[áéíóúñ¿¡]", text):
            return "es"
        return "en"

    def _is_german_word(self, word: str) -> bool:
        # List of common German words that might appear in the English section
        german_words = {
            "dir",
            "ich",
            "du",
            "sie",
            "er",
            "es",
            "wir",
            "ihr",
            "ist",
            "sind",
            "haben",
            "sein",
            "werden",
            "kann",
            "könnte",
            "möchte",
            "muss",
            "darf",
            "soll",
        }
        return word.lower() in german_words

    def _is_english_word(self, word: str) -> bool:
        # List of common English words to verify
        english_words = {"the", "a", "an", "in", "on", "at", "to", "for", "with", "by"}
        return word.lower() in english_words

    def generate_german_spanish_wordforword_ssml(
        self,
        word_pairs: list[tuple[str, str]],
    ) -> str:
        """Generate SSML specifically for German-Spanish word-by-word translations"""
        ssml = """
        <voice name="en-US-JennyMultilingualNeural">
            <prosody rate="0.8">"""

        for source_word, target_word in word_pairs:
            source_word = source_word.strip().replace("&", "&amp;")
            target_word = target_word.strip().replace("&", "&amp;")

            ssml += f"""
                <lang xml:lang="de-DE">{source_word}</lang>
                <break time="300ms"/>
                <lang xml:lang="es-ES">{target_word}</lang>
                <break time="500ms"/>"""

        ssml += """
                <break time="1000ms"/>
            </prosody>
        </voice>"""

        return ssml

    def generate_english_spanish_wordforword_ssml(
        self,
        word_pairs: list[tuple[str, str]],
    ) -> str:
        """Generate SSML specifically for English-Spanish word-by-word translations"""
        ssml = """
        <voice name="en-US-JennyMultilingualNeural">
            <prosody rate="0.8">"""

        for source_word, target_word in word_pairs:
            source_word = source_word.strip().replace("&", "&amp;")
            target_word = target_word.strip().replace("&", "&amp;")

            ssml += f"""
                <lang xml:lang="en-US">{source_word}</lang>
                <break time="300ms"/>
                <lang xml:lang="es-ES">{target_word}</lang>
                <break time="500ms"/>"""

        ssml += """
                <break time="1000ms"/>
            </prosody>
        </voice>"""

        return ssml

    def generate_enhanced_ssml(
        self,
        text: Optional[str] = None,
        word_pairs: Optional[list[tuple[str, str, bool]]] = None,
        source_lang: str = "de",
        target_lang: str = "es",
    ) -> str:
        """Generate SSML with proper phrase handling for both German and English"""
        ssml = """<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">"""

        if text:
            # Split text into lines and pad to 8 elements
            sentences = (text.split("\n") + [""] * 8)[:8]
            sentences = [
                t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                for t in sentences
            ]

            # Destructure sentences
            (
                german_native,
                german_colloquial,
                german_informal,
                german_formal,
                english_native,
                english_colloquial,
                english_informal,
                english_formal,
            ) = sentences

            if word_pairs:
                # Separate pairs with language flag
                german_pairs = [
                    (src, tgt) for src, tgt, is_german in word_pairs if is_german
                ]
                english_pairs = [
                    (src, tgt) for src, tgt, is_german in word_pairs if not is_german
                ]

                # German Sections
                if german_native:
                    ssml += self._generate_language_section(
                        german_native,
                        german_pairs,
                        voice="de-DE-SeraphinaMultilingualNeural",
                        lang="de-DE",
                    )

                if german_colloquial:
                    ssml += self._generate_language_section(
                        german_colloquial,
                        german_pairs,
                        voice="de-DE-SeraphinaMultilingualNeural",
                        lang="de-DE",
                    )

                if german_informal:
                    ssml += self._generate_language_section(
                        german_informal,
                        german_pairs,
                        voice="de-DE-KatjaNeural",
                        lang="de-DE",
                    )

                if german_formal:
                    ssml += self._generate_language_section(
                        german_formal,
                        german_pairs,
                        voice="de-DE-SeraphinaMultilingualNeural",
                        lang="de-DE",
                    )

                # English Sections
                if english_native:
                    ssml += self._generate_language_section(
                        english_native,
                        english_pairs,
                        voice="en-US-JennyMultilingualNeural",
                        lang="en-US",
                    )

                if english_colloquial:
                    ssml += self._generate_language_section(
                        english_colloquial,
                        english_pairs,
                        voice="en-US-JennyMultilingualNeural",
                        lang="en-US",
                    )

                if english_informal:
                    ssml += self._generate_language_section(
                        english_informal,
                        english_pairs,
                        voice="en-US-JennyNeural",
                        lang="en-US",
                    )

                if english_formal:
                    ssml += self._generate_language_section(
                        english_formal,
                        english_pairs,
                        voice="en-US-JennyMultilingualNeural",
                        lang="en-US",
                    )

        # Final cleanup of SSML
        ssml = re.sub(r'(<break time="500ms"\s*/>\s*)+', '<break time="500ms"/>', ssml)
        ssml += "</speak>"
        return ssml

    def _generate_language_section(
        self, sentence: str, word_pairs: list[tuple[str, str]], voice: str, lang: str
    ) -> str:
        """Generate complete language section with phrase handling"""
        section = f"""
        <voice name="{voice}">
            <prosody rate="1.0">
                <lang xml:lang="{lang}">{sentence}</lang>
                <break time="1000ms"/>
            </prosody>
        </voice>"""

        if word_pairs:
            section += """
        <voice name="en-US-JennyMultilingualNeural">
            <prosody rate="0.8">"""

            # Create phrase map and sort by phrase length
            phrase_map = {src.lower(): (src, tgt) for src, tgt in word_pairs}
            phrases = sorted(
                phrase_map.keys(), key=lambda x: len(x.split()), reverse=True
            )
            words = sentence.split()
            index = 0

            while index < len(words):
                matched = False

                # Try to match multi-word phrases first
                for phrase_key in phrases:
                    phrase_words = phrase_key.split()
                    if index + len(phrase_words) > len(words):
                        continue

                    candidate = " ".join(
                        words[index : index + len(phrase_words)]
                    ).lower()
                    if candidate == phrase_key:
                        original_phrase, translation = phrase_map[phrase_key]
                        section += f"""
            <lang xml:lang="{lang}">{original_phrase}</lang>
            <break time="300ms"/>
            <lang xml:lang="es-ES">{translation}</lang>
            <break time="500ms"/>"""
                        index += len(phrase_words)
                        matched = True
                        break

                # Single word fallback
                if not matched:
                    word = words[index].strip(".,!?")
                    translation = next(
                        (tgt for src, tgt in word_pairs if src.lower() == word.lower()),
                        None,
                    )
                    section += f"""
            <lang xml:lang="{lang}">{word}</lang>
            <break time="300ms"/>"""
                    if translation:
                        section += f"""
            <lang xml:lang="es-ES">{translation}</lang>
            <break time="500ms"/>"""
                    else:
                        section += """<break time="500ms"/>"""
                    index += 1

            section += """
            <break time="1000ms"/>
            </prosody>
        </voice>"""

        return section

    def _generate_sentence_section(
        self,
        sentence: str,
        word_pairs: list[tuple[str, str]],
        voice: str,
        lang: str,
    ) -> str:
        if not sentence:
            return ""

        # Generate the main sentence SSML
        ssml = f"""
            <voice name="{voice}">
                <prosody rate="1.0">
                    <lang xml:lang="{lang}">{sentence}</lang>
                    <break time="1000ms"/>
                </prosody>
            </voice>"""

        if word_pairs:
            ssml += """
                <voice name="en-US-JennyMultilingualNeural">
                    <prosody rate="0.8">"""

            # Create phrase map and sort by phrase length (longest first)
            phrase_map = {src.lower(): (src, tgt) for src, tgt in word_pairs}
            phrases = sorted(
                phrase_map.keys(), key=lambda x: len(x.split()), reverse=True
            )
            words = sentence.split()
            index = 0

            while index < len(words):
                matched = False

                # Try to match multi-word phrases first
                for phrase_key in phrases:
                    phrase_words = phrase_key.split()
                    phrase_len = len(phrase_words)

                    if index + phrase_len <= len(words):
                        current_phrase = " ".join(
                            words[index : index + phrase_len]
                        ).lower()
                        if current_phrase == phrase_key:
                            original_phrase, translation = phrase_map[phrase_key]
                            ssml += f"""
                                <lang xml:lang="{lang}">{original_phrase}</lang>
                                <break time="300ms"/>
                                <lang xml:lang="es-ES">{translation}</lang>
                                <break time="500ms"/>"""
                            index += phrase_len
                            matched = True
                            break

                # Fallback to single-word matching
                if not matched:
                    current_word = words[index].strip(".,!?").lower()
                    original_word = words[index]
                    translation = next(
                        (tgt for src, tgt in word_pairs if src.lower() == current_word),
                        None,
                    )

                    ssml += f"""
                        <lang xml:lang="{lang}">{original_word}</lang>
                        <break time="300ms"/>"""
                    if translation:
                        ssml += f"""
                            <lang xml:lang="es-ES">{translation}</lang>
                            <break time="500ms"/>"""
                    else:
                        ssml += """<break time="500ms"/>"""

                    index += 1

            ssml += """
                        <break time="1000ms"/>
                    </prosody>
                </voice>"""

        return ssml

    async def text_to_speech_word_pairs(
        self,
        word_pairs: list[tuple[str, str]],
        source_lang: str,
        target_lang: str,
        output_path: Optional[str] = None,
        complete_text: Optional[str] = None,  # New parameter
    ) -> Optional[str]:
        try:
            if not output_path:
                temp_dir = self._get_temp_directory()
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                output_path = os.path.join(temp_dir, f"speech_{timestamp}.mp3")
                print(f"Output path: {output_path}")

            audio_config = AudioOutputConfig(filename=output_path)
            speech_config = SpeechConfig(
                subscription=self.subscription_key, region=self.region
            )
            speech_config.set_speech_synthesis_output_format(
                SpeechSynthesisOutputFormat.Audio16Khz32KBitRateMonoMp3
            )

            synthesizer = SpeechSynthesizer(
                speech_config=speech_config, audio_config=audio_config
            )

            # Use the new combined SSML generator
            ssml = self.generate_enhanced_ssml(
                text=complete_text,
                word_pairs=word_pairs,
                source_lang=source_lang,
                target_lang=target_lang,
            )
            print(f"Generated SSML:\n{ssml}")  # Debug output

            result = await asyncio.get_event_loop().run_in_executor(
                None, lambda: synthesizer.speak_ssml_async(ssml).get()
            )

            if result.reason == ResultReason.SynthesizingAudioCompleted:
                return os.path.basename(output_path)

            if result.reason == ResultReason.Canceled:
                cancellation_details = result.cancellation_details
                print(f"Speech synthesis canceled: {cancellation_details.reason}")
                if cancellation_details.reason == CancellationReason.Error:
                    print(f"Error details: {cancellation_details.error_details}")

            return None
        except Exception as e:
            print(f"Error in text_to_speech_word_pairs: {str(e)}")
            return None

    # async def text_to_speech(
    #     self, ssml: str, output_path: Optional[str] = None
    # ) -> Optional[str]:
    async def text_to_speech(
        self, ssml: str, output_path: Optional[str] = None
    ) -> Optional[str]:
        """Convert SSML to speech with proper language handling"""
        synthesizer = None
        try:
            if not output_path:
                temp_dir = self._get_temp_directory()
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                output_path = os.path.join(temp_dir, f"speech_{timestamp}.mp3")
                print(f"Output path: {output_path}")

            audio_config = AudioOutputConfig(filename=output_path)
            synthesizer = SpeechSynthesizer(
                speech_config=self.speech_config, audio_config=audio_config
            )

            result = await asyncio.get_event_loop().run_in_executor(
                None, lambda: synthesizer.speak_ssml_async(ssml).get()
            )

            if result.reason == ResultReason.SynthesizingAudioCompleted:
                return os.path.basename(output_path)

            return None

        except Exception as e:
            print(f"Exception in text_to_speech: {str(e)}")
            return None
        finally:
            if synthesizer:
                try:
                    synthesizer.stop_speaking_async()
                except:
                    pass

