/// TranslationRepository & Provider
/// 
/// A clean architecture interface that defines translation functionality and audio handling. // Eine Clean-Architecture-Schnittstelle, die Übersetzungsfunktionalität und Audiobehandlung definiert.
/// Acts as a contract between domain and data layers, decoupling implementation details. // Fungiert als Vertrag zwischen Domain- und Datenschichten und entkoppelt Implementierungsdetails.
///
/// This file provides: // Diese Datei bietet:
/// - An abstract interface defining translation operations // - Eine abstrakte Schnittstelle, die Übersetzungsoperationen definiert
/// - A Riverpod provider for dependency injection // - Einen Riverpod-Provider für Dependency Injection
///
/// Usage:
/// ```dart
/// // Access the translation repository in a widget // Zugriff auf das Übersetzungs-Repository in einem Widget
/// final translationRepo = ref.watch(translationRepositoryProvider);
/// 
/// // Get a translation of text // Eine Textübersetzung abrufen
/// final translation = await translationRepo.getTranslation("Hello");
/// 
/// // Process speech to text // Sprache zu Text verarbeiten
/// final text = await translationRepo.processAudioInput("/path/to/audio.wav");
/// ```
///
/// EN: Defines the contract for translation services and provides dependency injection through Riverpod.
/// DE: Definiert den Vertrag für Übersetzungsdienste und ermöglicht Dependency Injection durch Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart'; // Imports Riverpod for dependency injection and state management. // Importiert Riverpod für Dependency Injection und Zustandsverwaltung.
import '../../data/repositories/translation_repository_impl.dart'; // Imports the concrete implementation of the repository. // Importiert die konkrete Implementierung des Repositorys.
import '../entities/translation.dart'; // Imports the Translation entity model. // Importiert das Translation-Entitätsmodell.

final translationRepositoryProvider = Provider<TranslationRepository>((ref) { // Defines a Riverpod provider that creates and provides a TranslationRepository instance. // Definiert einen Riverpod-Provider, der eine TranslationRepository-Instanz erstellt und bereitstellt.
  return TranslationRepositoryImpl(); // Returns a new instance of the concrete implementation. // Gibt eine neue Instanz der konkreten Implementierung zurück.
});


/// TranslationRepository
///
/// An abstract class defining the contract for translation services. // Eine abstrakte Klasse, die den Vertrag für Übersetzungsdienste definiert.
/// Provides methods for text translation, speech-to-text, and audio playback. // Bietet Methoden für Textübersetzung, Sprache-zu-Text und Audiowiedergabe.
///
/// EN: Using the repository pattern to separate the interface from implementation details.
/// DE: Verwendet das Repository-Muster, um die Schnittstelle von Implementierungsdetails zu trennen.

abstract class TranslationRepository { // Defines an abstract class that can't be instantiated directly. // Definiert eine abstrakte Klasse, die nicht direkt instanziiert werden kann.
  Future<Translation> getTranslation(String text); // Method to translate text and return a Translation object. // Methode zum Übersetzen von Text und Rückgabe eines Translation-Objekts.
  Future<String> processAudioInput(String audioPath); // Method to convert speech audio to text (speech recognition). // Methode zur Umwandlung von Sprachaudio in Text (Spracherkennung).
  Future<void> playAudio(String audioPath); // Method to play audio from a specified file path. // Methode zum Abspielen von Audio von einem angegebenen Dateipfad.
  Future<void> stopAudio(); // Method to stop any currently playing audio. // Methode zum Stoppen von derzeit abgespieltem Audio.
  Future<void> playCompletionSound(); // Method to play a notification sound when an operation completes. // Methode zum Abspielen eines Benachrichtigungstons, wenn ein Vorgang abgeschlossen ist.
  Future<void> playUISound(String soundType); // Method to play UI interaction sounds of different types. // Methode zum Abspielen von UI-Interaktionsgeräuschen verschiedener Typen.
  void dispose(); // Method to clean up resources when the repository is no longer needed. // Methode zum Bereinigen von Ressourcen, wenn das Repository nicht mehr benötigt wird.
}
