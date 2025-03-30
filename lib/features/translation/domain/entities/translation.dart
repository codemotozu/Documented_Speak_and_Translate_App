/// Translation
/// 
/// A data model class that represents a translation with metadata. // Eine Datenmodellklasse, die eine Übersetzung mit Metadaten darstellt.
/// Stores both the original and translated text along with additional language information. // Speichert sowohl den Original- als auch den übersetzten Text zusammen mit zusätzlichen Sprachinformationen.
///
/// The class supports advanced features including: // Die Klasse unterstützt erweiterte Funktionen, darunter:
/// - Audio pronunciation paths // - Pfade zur Audioaussprache
/// - Multiple translation variants // - Mehrere Übersetzungsvarianten
/// - Word-by-word translations // - Wort-für-Wort-Übersetzungen
/// - Grammatical explanations // - Grammatikalische Erklärungen
///
/// Usage:
/// ```dart
/// // Create a basic translation // Erstellen einer einfachen Übersetzung
/// final translation = Translation(
///   originalText: "Hello world",
///   translatedText: "Hallo Welt",
///   sourceLanguage: "en",
///   targetLanguage: "de"
/// );
///
/// // Parse from JSON data // Aus JSON-Daten parsen
/// final jsonData = {
///   'original_text': 'Hello',
///   'translated_text': 'Hola',
///   'source_language': 'en',
///   'target_language': 'es'
/// };
/// final translationFromJson = Translation.fromJson(jsonData);
/// ```
///
/// EN: Models translation data with support for rich metadata and language learning features.
/// DE: Modelliert Übersetzungsdaten mit Unterstützung für umfangreiche Metadaten und Sprachlernfunktionen.

class Translation { // Defines a class to represent a translation with metadata. // Definiert eine Klasse zur Darstellung einer Übersetzung mit Metadaten.
  final String originalText; // The original text before translation. // Der Originaltext vor der Übersetzung.
  final String translatedText; // The translated version of the text. // Die übersetzte Version des Textes.
  final String sourceLanguage; // The language code of the original text. // Der Sprachcode des Originaltextes.
  final String targetLanguage; // The language code of the translated text. // Der Sprachcode des übersetzten Textes.
  final String? audioPath; // Optional path to an audio file of the translation. // Optionaler Pfad zu einer Audiodatei der Übersetzung.
  final Map<String, String>? translations; // Optional map of additional translations or variants. // Optionale Zuordnung zusätzlicher Übersetzungen oder Varianten.
  final Map<String, Map<String, String>>? wordByWord; // Optional detailed word-by-word translations. // Optionale detaillierte Wort-für-Wort-Übersetzungen.
  final Map<String, String>? grammarExplanations; // Optional grammatical explanations for the translation. // Optionale grammatikalische Erklärungen für die Übersetzung.

  Translation({ // Constructor for creating a Translation object. // Konstruktor zum Erstellen eines Translation-Objekts.
    required this.originalText, // Required parameter for original text. // Erforderlicher Parameter für den Originaltext.
    required this.translatedText, // Required parameter for translated text. // Erforderlicher Parameter für den übersetzten Text.
    required this.sourceLanguage, // Required parameter for source language. // Erforderlicher Parameter für die Ausgangssprache.
    required this.targetLanguage, // Required parameter for target language. // Erforderlicher Parameter für die Zielsprache.
    this.audioPath, // Optional parameter for audio file path. // Optionaler Parameter für den Audiodateipfad.
    this.translations, // Optional parameter for additional translations. // Optionaler Parameter für zusätzliche Übersetzungen.
    this.wordByWord, // Optional parameter for word-by-word translations. // Optionaler Parameter für Wort-für-Wort-Übersetzungen.
    this.grammarExplanations, // Optional parameter for grammar explanations. // Optionaler Parameter für grammatikalische Erklärungen.
  });

  factory Translation.fromJson(Map<String, dynamic> json) { // Factory constructor to create a Translation from JSON data. // Factory-Konstruktor zum Erstellen einer Übersetzung aus JSON-Daten.
    return Translation( // Returns a new Translation instance. // Gibt eine neue Translation-Instanz zurück.
      originalText: json['original_text'] as String, // Extracts original text from JSON. // Extrahiert den Originaltext aus JSON.
      translatedText: json['translated_text'] as String, // Extracts translated text from JSON. // Extrahiert den übersetzten Text aus JSON.
      sourceLanguage: json['source_language'] as String, // Extracts source language from JSON. // Extrahiert die Ausgangssprache aus JSON.
      targetLanguage: json['target_language'] as String, // Extracts target language from JSON. // Extrahiert die Zielsprache aus JSON.
      audioPath: json['audio_path'] as String?, // Extracts optional audio path from JSON. // Extrahiert den optionalen Audiodateipfad aus JSON.
      translations: json['translations'] != null // Conditional processing for translations map. // Bedingte Verarbeitung für die Übersetzungszuordnung.
          ? Map<String, String>.from(json['translations'] as Map) // Converts JSON map to String-String map if not null. // Konvertiert JSON-Map zu String-String-Map, wenn nicht null.
          : null, // Returns null if translations data is missing. // Gibt null zurück, wenn Übersetzungsdaten fehlen.
      wordByWord: json['word_by_word'] != null // Conditional processing for word-by-word translations. // Bedingte Verarbeitung für Wort-für-Wort-Übersetzungen.
          ? Map<String, Map<String, String>>.from( // Creates a nested map from JSON data. // Erstellt eine verschachtelte Map aus JSON-Daten.
              (json['word_by_word'] as Map).map( // Maps each entry in the outer map. // Bildet jeden Eintrag in der äußeren Map ab.
                (key, value) => MapEntry( // Creates a new map entry for each key-value pair. // Erstellt einen neuen Map-Eintrag für jedes Schlüssel-Wert-Paar.
                  key as String, // Converts the key to String. // Konvertiert den Schlüssel zu String.
                  Map<String, String>.from(value as Map), // Converts inner map values to String-String map. // Konvertiert innere Map-Werte zu String-String-Map.
                ),
              ),
            )
          : null, // Returns null if word-by-word data is missing. // Gibt null zurück, wenn Wort-für-Wort-Daten fehlen.
      grammarExplanations: json['grammar_explanations'] != null // Conditional processing for grammar explanations. // Bedingte Verarbeitung für grammatikalische Erklärungen.
          ? Map<String, String>.from(json['grammar_explanations'] as Map) // Converts JSON map to String-String map if not null. // Konvertiert JSON-Map zu String-String-Map, wenn nicht null.
          : null, // Returns null if grammar explanation data is missing. // Gibt null zurück, wenn grammatikalische Erklärungsdaten fehlen.
    );
  }
}
