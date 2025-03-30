# Translation
#
# A data model for storing comprehensive translation results with metadata. # Ein Datenmodell zur Speicherung umfassender Übersetzungsergebnisse mit Metadaten.
# Used in the domain layer of the application to represent translation outputs. # Wird in der Domain-Schicht der Anwendung verwendet, um Übersetzungsergebnisse darzustellen.
#
# Usage:
# translation = Translation(
#     original_text="Hello world",
#     translated_text="Hallo Welt",
#     source_language="en",
#     target_language="de"
# )
#
# EN: Defines the structure for translation data with optional educational features like word mapping and grammar notes.
# DE: Definiert die Struktur für Übersetzungsdaten mit optionalen Lernfunktionen wie Wortzuordnung und Grammatikhinweisen.

from typing import Dict, Optional # Imports type annotation tools for better code clarity. # Importiert Typannotationswerkzeuge für bessere Codeklarheit.
from pydantic import BaseModel, Field # Imports Pydantic for data validation and serialization. # Importiert Pydantic für Datenvalidierung und Serialisierung.
from datetime import datetime # Imports datetime module for timestamp handling. # Importiert das Datetime-Modul zur Verarbeitung von Zeitstempeln.

class Translation(BaseModel): # Defines a Translation class that inherits from Pydantic's BaseModel. # Definiert eine Translation-Klasse, die von Pydantics BaseModel erbt.
    original_text: str # The source text to be translated (required). # Der zu übersetzende Quelltext (erforderlich).
    translated_text: str # The complete translated text result (required). # Das vollständige übersetzte Textergebnis (erforderlich).
    source_language: str # The language code of the original text (required). # Der Sprachcode des Originaltextes (erforderlich).
    target_language: str # The language code of the translated text (required). # Der Sprachcode des übersetzten Textes (erforderlich).
    audio_path: Optional[str] = None # Optional path to an audio file of the pronunciation. # Optionaler Pfad zu einer Audiodatei der Aussprache.
    translations: Optional[Dict[str, str]] = None # Optional dictionary of alternative translations with different formality levels. # Optionales Wörterbuch alternativer Übersetzungen mit verschiedenen Formalitätsstufen.
    word_by_word: Optional[Dict[str, Dict[str, str]]] = None # Optional dictionary mapping each word to its translation and part of speech. # Optionales Wörterbuch, das jedes Wort seiner Übersetzung und Wortart zuordnet.
    grammar_explanations: Optional[Dict[str, str]] = None # Optional dictionary of grammar explanations for the translation. # Optionales Wörterbuch mit Grammatikerklärungen für die Übersetzung.
    created_at: datetime = Field(default_factory=datetime.now) # Timestamp when the translation was created, defaults to current time. # Zeitstempel, wann die Übersetzung erstellt wurde, standardmäßig die aktuelle Zeit.
