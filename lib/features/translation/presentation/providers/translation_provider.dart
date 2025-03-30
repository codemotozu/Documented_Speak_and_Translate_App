/// TranslationProvider and TranslationNotifier
/// 
/// A Flutter Riverpod implementation for managing translation conversations. // Eine Flutter Riverpod-Implementierung zur Verwaltung von Übersetzungsgesprächen.
/// Provides state management for chat history, translation requests, and audio playback. // Bietet Zustandsverwaltung für Chatverlauf, Übersetzungsanfragen und Audiowiedergabe.
/// 
/// Usage:
/// ```dart
/// final translationState = ref.watch(translationProvider);
/// final notifier = ref.read(translationProvider.notifier);
/// notifier.startConversation('Hello, how are you?');
/// ```
/// 
/// EN: Manages translation conversations with history pruning and audio playback capabilities.
/// DE: Verwaltet Übersetzungsgespräche mit Verlaufskürzung und Audiowiedergabefunktionen.

import 'package:flutter_riverpod/flutter_riverpod.dart'; // Imports the Riverpod package for state management. // Importiert das Riverpod-Paket für die Zustandsverwaltung.
import '../../data/models/chat_message_model.dart'; // Imports the chat message model class. // Importiert die Chat-Nachrichtenmodellklasse.
import '../../domain/repositories/translation_repository.dart'; // Imports the translation repository for API interactions. // Importiert das Übersetzungs-Repository für API-Interaktionen.
import 'speech_provider.dart'; // Imports the speech provider for audio playback controls. // Importiert den Speech-Provider für Audiowiedergabesteuerungen.

const _maxMessages = 50; // Maximum messages to keep in history. // Maximale Anzahl von Nachrichten, die im Verlauf gespeichert werden.
const _messagesToKeepWhenPruning = 40; // Number to keep when pruning. // Anzahl der Nachrichten, die beim Kürzen behalten werden.
const _initialMessagesToPreserve = 2; // Keep first N messages of conversation. // Behält die ersten N Nachrichten des Gesprächs.

class TranslationState { // Class that represents the state of translation. // Klasse, die den Zustand der Übersetzung repräsentiert.
  final bool isLoading; // Indicates if a translation is in progress. // Gibt an, ob eine Übersetzung im Gange ist.
  final List<ChatMessage> messages; // List of chat messages in the conversation. // Liste der Chat-Nachrichten im Gespräch.
  final String? error; // Optional error message if something goes wrong. // Optionale Fehlermeldung, wenn etwas schief geht.

  TranslationState({ // Constructor for the TranslationState class. // Konstruktor für die TranslationState-Klasse.
    required this.isLoading, // Required parameter for loading state. // Erforderlicher Parameter für den Ladezustand.
    required this.messages, // Required parameter for message list. // Erforderlicher Parameter für die Nachrichtenliste.
    this.error, // Optional parameter for error message. // Optionaler Parameter für die Fehlermeldung.
  });

  factory TranslationState.initial() => TranslationState( // Factory constructor to create initial state. // Factory-Konstruktor zum Erstellen des Anfangszustands.
        isLoading: false, // Initially not loading. // Initial nicht im Ladezustand.
        messages: [], // Empty messages list. // Leere Nachrichtenliste.
        error: null, // No error initially. // Anfänglich kein Fehler.
      );

  TranslationState copyWith({ // Method to create a copy with some fields changed. // Methode zum Erstellen einer Kopie mit einigen geänderten Feldern.
    bool? isLoading, // Optional new loading state. // Optionaler neuer Ladezustand.
    List<ChatMessage>? messages, // Optional new messages list. // Optionale neue Nachrichtenliste.
    String? error, // Optional new error message. // Optionale neue Fehlermeldung.
  }) {
    return TranslationState( // Returns a new TranslationState instance. // Gibt eine neue TranslationState-Instanz zurück.
      isLoading: isLoading ?? this.isLoading, // Uses provided value or keeps existing one. // Verwendet den bereitgestellten Wert oder behält den vorhandenen bei.
      messages: messages ?? this.messages, // Uses provided messages or keeps existing ones. // Verwendet die bereitgestellten Nachrichten oder behält die vorhandenen bei.
      error: error ?? this.error, // Uses provided error or keeps existing one. // Verwendet den bereitgestellten Fehler oder behält den vorhandenen bei.
    );
  }
}

class TranslationNotifier extends StateNotifier<TranslationState> { // Class to manage TranslationState and handle business logic. // Klasse zur Verwaltung von TranslationState und Behandlung der Geschäftslogik.
  final TranslationRepository _repository; // Reference to the translation repository. // Referenz auf das Übersetzungs-Repository.
  final Ref _ref; // Reference to the Riverpod container for accessing other providers. // Referenz auf den Riverpod-Container zum Zugriff auf andere Provider.
  bool _mounted = true; // Flag to track if this notifier is still active. // Flag zur Verfolgung, ob dieser Notifier noch aktiv ist.

  TranslationNotifier(this._repository, this._ref) // Constructor that accepts repository and ref. // Konstruktor, der Repository und Ref akzeptiert.
      : super(TranslationState.initial()); // Initializes the state with the initial state. // Initialisiert den Zustand mit dem Anfangszustand.

  Future<void> startConversation(String text) async { // Method to start or continue a conversation with a message. // Methode zum Starten oder Fortsetzen eines Gesprächs mit einer Nachricht.
    if (!_mounted || text.isEmpty) return; // Returns early if notifier is disposed or text is empty. // Kehrt frühzeitig zurück, wenn der Notifier entsorgt wurde oder der Text leer ist.

    try { // Tries to perform the translation. // Versucht, die Übersetzung durchzuführen.
      // Prune history before adding new messages. // Kürzt den Verlauf, bevor neue Nachrichten hinzugefügt werden.
      var updatedMessages = _pruneMessageHistory([ 
        ...state.messages, // Existing messages. // Vorhandene Nachrichten.
        ChatMessage.user(text), // Adds user message. // Fügt Benutzernachricht hinzu.
        ChatMessage.aiLoading(), // Adds loading indicator message. // Fügt Ladeindikator-Nachricht hinzu.
      ]);

      state = state.copyWith(messages: updatedMessages, isLoading: true); // Updates state with new messages and loading flag. // Aktualisiert den Zustand mit neuen Nachrichten und dem Ladeflag.
      await _repository.stopAudio(); // Stops any playing audio before starting new translation. // Stoppt jede laufende Audiowiedergabe, bevor eine neue Übersetzung gestartet wird.

      final translation = await _repository.getTranslation(text); // Gets translation from repository. // Holt die Übersetzung vom Repository.
      if (!_mounted) return; // Returns if notifier was disposed during async operation. // Kehrt zurück, wenn der Notifier während der asynchronen Operation entsorgt wurde.

      // Prune again after receiving response. // Kürzt erneut nach Erhalt der Antwort.
      final newMessages = _pruneMessageHistory(
        List<ChatMessage>.from(state.messages) // Creates a copy of current messages. // Erstellt eine Kopie der aktuellen Nachrichten.
          ..removeLast() // Removes the loading message. // Entfernt die Ladeindikator-Nachricht.
          ..add(ChatMessage.ai(translation: translation)), // Adds the AI response with translation. // Fügt die KI-Antwort mit der Übersetzung hinzu.
      );

      state = state.copyWith( // Updates the state with new data. // Aktualisiert den Zustand mit neuen Daten.
        isLoading: false, // No longer loading. // Nicht mehr im Ladezustand.
        messages: newMessages, // Updates with new message list. // Aktualisiert mit neuer Nachrichtenliste.
        error: null, // Clears any previous errors. // Löscht alle vorherigen Fehler.
      );

      final isHandsFree = _ref.read(speechProvider); // Checks if hands-free mode is enabled. // Prüft, ob der Freisprechmodus aktiviert ist.
      if (isHandsFree && translation.audioPath != null) { // If hands-free is on and audio is available. // Wenn Freisprechen aktiviert ist und Audio verfügbar ist.
        await _repository.playAudio(translation.audioPath!); // Plays the audio automatically. // Spielt das Audio automatisch ab.
      }
    } catch (e) { // Catches any errors during translation. // Fängt alle Fehler während der Übersetzung ab.
      if (!_mounted) return; // Returns if notifier was disposed during error handling. // Kehrt zurück, wenn der Notifier während der Fehlerbehandlung entsorgt wurde.
      
      final newMessages = _pruneMessageHistory( // Prunes history and adds error message. // Kürzt den Verlauf und fügt eine Fehlermeldung hinzu.
        List<ChatMessage>.from(state.messages) // Creates a copy of current messages. // Erstellt eine Kopie der aktuellen Nachrichten.
          ..removeLast() // Removes the loading message. // Entfernt die Ladeindikator-Nachricht.
          ..add(ChatMessage.aiError(e.toString())), // Adds an error message from the AI. // Fügt eine Fehlermeldung von der KI hinzu.
      );

      state = state.copyWith( // Updates state with error information. // Aktualisiert den Zustand mit Fehlerinformationen.
        isLoading: false, // No longer loading. // Nicht mehr im Ladezustand.
        messages: newMessages, // Updates with new message list including error. // Aktualisiert mit neuer Nachrichtenliste einschließlich Fehler.
        error: e.toString(), // Sets the error message. // Setzt die Fehlermeldung.
      );
    }
  }

  List<ChatMessage> _pruneMessageHistory(List<ChatMessage> messages) { // Helper method to limit message history size. // Hilfsmethode zur Begrenzung der Größe des Nachrichtenverlaufs.
    if (messages.length <= _maxMessages) return messages; // Returns unchanged if under limit. // Gibt unverändert zurück, wenn unter dem Limit.

    return [ // Returns pruned list of messages. // Gibt gekürzte Liste von Nachrichten zurück.
      // Preserve initial conversation context. // Bewahrt den anfänglichen Gesprächskontext.
      ...messages.take(_initialMessagesToPreserve), // Takes first N messages. // Nimmt die ersten N Nachrichten.
      // Keep most recent messages. // Behält die neuesten Nachrichten.
      ...messages.sublist( // Takes a slice of the messages list. // Nimmt einen Ausschnitt der Nachrichtenliste.
        messages.length - (_messagesToKeepWhenPruning - _initialMessagesToPreserve), // Calculates starting index. // Berechnet den Startindex.
      ),
    ];
  }

  Future<void> playAudio(String audioPath) async { // Method to play audio file at given path. // Methode zum Abspielen der Audiodatei am angegebenen Pfad.
    try { // Tries to play the audio. // Versucht, das Audio abzuspielen.
      await _repository.playAudio(audioPath); // Calls repository to play audio. // Ruft das Repository auf, um Audio abzuspielen.
    } catch (e) { // Catches any errors during playback. // Fängt alle Fehler während der Wiedergabe ab.
      if (_mounted) { // Checks if notifier is still active. // Prüft, ob der Notifier noch aktiv ist.
        state = state.copyWith(error: 'Audio playback failed: ${e.toString()}'); // Updates state with error message. // Aktualisiert den Zustand mit einer Fehlermeldung.
      }
    }
  }

  Future<void> stopAudio() async { // Method to stop current audio playback. // Methode zum Stoppen der aktuellen Audiowiedergabe.
    try { // Tries to stop the audio. // Versucht, das Audio zu stoppen.
      await _repository.stopAudio(); // Calls repository to stop audio. // Ruft das Repository auf, um Audio zu stoppen.
    } catch (e) { // Catches any errors while stopping. // Fängt alle Fehler beim Stoppen ab.
      if (_mounted) { // Checks if notifier is still active. // Prüft, ob der Notifier noch aktiv ist.
        state = state.copyWith(error: 'Error stopping audio: ${e.toString()}'); // Updates state with error message. // Aktualisiert den Zustand mit einer Fehlermeldung.
      }
    }
  }

  void clearConversation() { // Method to clear all conversation history. // Methode zum Löschen des gesamten Gesprächsverlaufs.
    if (_mounted) { // Checks if notifier is still active. // Prüft, ob der Notifier noch aktiv ist.
      state = TranslationState.initial(); // Resets state to initial empty state. // Setzt den Zustand auf den anfänglichen leeren Zustand zurück.
    }
  }

  @override
  void dispose() { // Overrides dispose method to clean up resources. // Überschreibt die dispose-Methode, um Ressourcen zu bereinigen.
    _mounted = false; // Marks notifier as no longer mounted. // Markiert den Notifier als nicht mehr montiert.
    _repository.dispose(); // Disposes the repository. // Entsorgt das Repository.
    super.dispose(); // Calls parent dispose method. // Ruft die übergeordnete dispose-Methode auf.
  }
}

final translationProvider = // Creates a Riverpod provider for translation state. // Erstellt einen Riverpod-Provider für den Übersetzungszustand.
    StateNotifierProvider<TranslationNotifier, TranslationState>((ref) { // Defines a state notifier provider. // Definiert einen State-Notifier-Provider.
  return TranslationNotifier( // Returns a new TranslationNotifier instance. // Gibt eine neue TranslationNotifier-Instanz zurück.
    ref.watch(translationRepositoryProvider), // Gets the translation repository. // Holt das Übersetzungs-Repository.
    ref, // Passes ref for accessing other providers. // Übergibt ref für den Zugriff auf andere Provider.
  );
});
