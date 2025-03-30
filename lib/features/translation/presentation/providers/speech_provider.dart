/// SpeechProvider and SpeechNotifier
/// 
/// A Flutter Riverpod implementation for managing audio playback functionality. // Eine Flutter Riverpod-Implementierung zur Verwaltung der Audiowiedergabefunktionalität.
/// Provides state management for audio playback and hands-free mode features. // Bietet Zustandsverwaltung für Audiowiedergabe und Freisprechfunktionen.
/// 
/// Usage:
/// ```dart
/// final isHandsFree = ref.watch(speechProvider);
/// final notifier = ref.read(speechProvider.notifier);
/// notifier.playAudio(audioPath);
/// ```
/// 
/// EN: Manages audio playback state and hands-free mode through a Riverpod provider.
/// DE: Verwaltet den Audiowiedergabezustand und den Freisprechmodus über einen Riverpod-Provider.

import 'package:flutter_riverpod/flutter_riverpod.dart'; // Imports the Riverpod package for state management. // Importiert das Riverpod-Paket für die Zustandsverwaltung.
import '../../domain/repositories/translation_repository.dart'; // Imports the translation repository that handles audio playback. // Importiert das Übersetzungs-Repository, das die Audiowiedergabe verwaltet.

final speechProvider = StateNotifierProvider<SpeechNotifier, bool>((ref) { // Defines a Riverpod provider that manages a boolean state using SpeechNotifier. // Definiert einen Riverpod-Provider, der einen booleschen Zustand mit SpeechNotifier verwaltet.
  final repository = ref.watch(translationRepositoryProvider); // Gets an instance of the translation repository from another provider. // Holt eine Instanz des Übersetzungs-Repositories von einem anderen Provider.
  return SpeechNotifier(repository); // Returns a new SpeechNotifier with the repository. // Gibt einen neuen SpeechNotifier mit dem Repository zurück.
});

class SpeechNotifier extends StateNotifier<bool> { // Creates a state notifier class that extends StateNotifier with a boolean state. // Erstellt eine Zustandsbenachrichtigungsklasse, die StateNotifier mit einem booleschen Zustand erweitert.
  final TranslationRepository _repository; // Private field to store the translation repository. // Privates Feld zur Speicherung des Übersetzungs-Repositories.
  bool _isPlaying = false; // Tracks whether audio is currently playing. // Verfolgt, ob Audio gerade abgespielt wird.

  SpeechNotifier(this._repository) : super(true); // Constructor that initializes the state to true (hands-free mode enabled). // Konstruktor, der den Zustand auf true initialisiert (Freisprechmodus aktiviert).
  bool get isPlaying => _isPlaying; // Getter that returns whether audio is playing. // Getter, der zurückgibt, ob Audio abgespielt wird.
  bool get isHandsFreeMode => state; // Getter that returns the current state (whether hands-free mode is enabled). // Getter, der den aktuellen Zustand zurückgibt (ob der Freisprechmodus aktiviert ist).

  void toggleHandsFreeMode() { // Method to toggle the hands-free mode on and off. // Methode zum Ein- und Ausschalten des Freisprechmodus.
    state = !state; // Inverts the current state value. // Kehrt den aktuellen Zustandswert um.
  }

  Future<void> playAudio(String? audioPath) async { // Asynchronous method to play audio from a given path. // Asynchrone Methode zum Abspielen von Audio von einem angegebenen Pfad.
    if (audioPath == null) return; // Returns early if the audio path is null. // Kehrt frühzeitig zurück, wenn der Audiopfad null ist.
    
    try { // Tries to execute the audio playback code. // Versucht, den Audiowiedergabecode auszuführen.
      _isPlaying = true; // Sets the playing state to true. // Setzt den Wiedergabestatus auf true.
      await _repository.playAudio(audioPath); // Calls the repository to play the audio and waits for completion. // Ruft das Repository auf, um das Audio abzuspielen, und wartet auf den Abschluss.
      _isPlaying = false; // Resets the playing state to false after playback is complete. // Setzt den Wiedergabestatus nach Abschluss der Wiedergabe auf false zurück.
    } catch (e) { // Catches any errors that occur during playback. // Fängt alle Fehler ab, die während der Wiedergabe auftreten.
      _isPlaying = false; // Resets the playing state even if an error occurs. // Setzt den Wiedergabestatus zurück, auch wenn ein Fehler auftritt.
      print('Error playing audio: $e'); // Prints the error message to the console. // Gibt die Fehlermeldung in der Konsole aus.
      rethrow; // Rethrows the error to be handled by the caller. // Wirft den Fehler erneut, damit er vom Aufrufer behandelt werden kann.
    }
  }

  Future<void> stop() async { // Asynchronous method to stop audio playback. // Asynchrone Methode zum Stoppen der Audiowiedergabe.
    try { // Tries to execute the stop audio code. // Versucht, den Code zum Stoppen des Audios auszuführen.
      await _repository.stopAudio(); // Calls the repository to stop audio playback and waits for completion. // Ruft das Repository auf, um die Audiowiedergabe zu stoppen, und wartet auf den Abschluss.
      _isPlaying = false; // Sets the playing state to false. // Setzt den Wiedergabestatus auf false.
    } catch (e) { // Catches any errors that occur while stopping playback. // Fängt alle Fehler ab, die beim Stoppen der Wiedergabe auftreten.
      print('Error stopping audio: $e'); // Prints the error message to the console. // Gibt die Fehlermeldung in der Konsole aus.
    }
  }

  @override
  void dispose() { // Overrides the dispose method from the parent class. // Überschreibt die dispose-Methode der Elternklasse.
    _repository.dispose(); // Calls dispose on the repository to clean up resources. // Ruft dispose im Repository auf, um Ressourcen zu bereinigen.
    super.dispose(); // Calls the parent class dispose method. // Ruft die dispose-Methode der Elternklasse auf.
  }
}
