/// VoiceCommandProvider and VoiceCommandNotifier
/// 
/// A Flutter Riverpod implementation for managing voice commands and speech recognition. // Eine Flutter Riverpod-Implementierung zur Verwaltung von Sprachbefehlen und Spracherkennung.
/// Provides state management for voice recording, command processing, and interactions with other application features. // Bietet Zustandsverwaltung für Sprachaufnahme, Befehlsverarbeitung und Interaktionen mit anderen Anwendungsfunktionen.
/// 
/// Usage:
/// ```dart
/// final voiceState = ref.watch(voiceCommandProvider);
/// final notifier = ref.read(voiceCommandProvider.notifier);
/// notifier.processVoiceCommand('open');
/// ```
/// 
/// EN: Manages voice command processing with support for "open" and "stop" commands to control audio recording.
/// DE: Verwaltet die Verarbeitung von Sprachbefehlen mit Unterstützung für "open" und "stop" Befehle zur Steuerung der Audioaufnahme.

import 'package:flutter_riverpod/flutter_riverpod.dart'; // Imports the Riverpod package for state management. // Importiert das Riverpod-Paket für die Zustandsverwaltung.

import '../../domain/repositories/translation_repository.dart'; // Imports the translation repository for API interactions. // Importiert das Übersetzungs-Repository für API-Interaktionen.
import 'audio_recorder_provider.dart'; // Imports the audio recorder provider for recording functionality. // Importiert den Audio-Recorder-Provider für Aufnahmefunktionen.
import 'prompt_screen_provider.dart'; // Imports the prompt screen provider to update UI state. // Importiert den Prompt-Screen-Provider, um den UI-Zustand zu aktualisieren.

class VoiceCommandState { // Class that represents the state of voice commands. // Klasse, die den Zustand der Sprachbefehle repräsentiert.
  final bool isListening; // Indicates if the app is currently listening for voice input. // Gibt an, ob die App derzeit auf Spracheingaben hört.
  final String? lastCommand; // Stores the last recognized command or transcribed text. // Speichert den letzten erkannten Befehl oder transkribierten Text.
  final String? error; // Optional error message if something goes wrong. // Optionale Fehlermeldung, wenn etwas schief geht.
  final bool isProcessing; // Indicates if a command is currently being processed. // Gibt an, ob ein Befehl gerade verarbeitet wird.

  VoiceCommandState({ // Constructor for the VoiceCommandState class. // Konstruktor für die VoiceCommandState-Klasse.
    this.isListening = false, // Default to not listening. // Standardmäßig wird nicht zugehört.
    this.lastCommand, // No default command. // Kein Standardbefehl.
    this.error, // No default error. // Kein Standardfehler.
    this.isProcessing = false, // Default to not processing. // Standardmäßig wird nicht verarbeitet.
  });

  
  VoiceCommandState copyWith({ // Method to create a copy with some fields changed. // Methode zum Erstellen einer Kopie mit einigen geänderten Feldern.
    bool? isListening, // Optional new listening state. // Optionaler neuer Zuhörzustand.
    String? lastCommand, // Optional new command. // Optionaler neuer Befehl.
    String? error, // Optional new error message. // Optionale neue Fehlermeldung.
    bool? isProcessing, // Optional new processing state. // Optionaler neuer Verarbeitungszustand.
  }) {
    return VoiceCommandState( // Returns a new VoiceCommandState instance. // Gibt eine neue VoiceCommandState-Instanz zurück.
      isListening: isListening ?? this.isListening, // Uses provided value or keeps existing one. // Verwendet den bereitgestellten Wert oder behält den vorhandenen bei.
      lastCommand: lastCommand ?? this.lastCommand, // Uses provided command or keeps existing one. // Verwendet den bereitgestellten Befehl oder behält den vorhandenen bei.
      error: error ?? this.error, // Uses provided error or keeps existing one. // Verwendet den bereitgestellten Fehler oder behält den vorhandenen bei.
      isProcessing: isProcessing ?? this.isProcessing, // Uses provided processing state or keeps existing one. // Verwendet den bereitgestellten Verarbeitungszustand oder behält den vorhandenen bei.
    );
  }
}

class VoiceCommandNotifier extends StateNotifier<VoiceCommandState> { // Class to manage VoiceCommandState and handle business logic. // Klasse zur Verwaltung von VoiceCommandState und Behandlung der Geschäftslogik.
  final AudioRecorder _recorder; // Reference to the audio recorder service. // Referenz auf den Audio-Recorder-Dienst.
  final TranslationRepository _repository; // Reference to the translation repository. // Referenz auf das Übersetzungs-Repository.
  final Ref _ref; // Reference to the Riverpod container for accessing other providers. // Referenz auf den Riverpod-Container zum Zugriff auf andere Provider.

  VoiceCommandNotifier(this._recorder, this._repository, this._ref) // Constructor that accepts recorder, repository, and ref. // Konstruktor, der Recorder, Repository und Ref akzeptiert.
      : super(VoiceCommandState()); // Initializes the state with the default state. // Initialisiert den Zustand mit dem Standardzustand.

  Future<void> processVoiceCommand(String command) async { // Method to process voice commands like "open" or "stop". // Methode zur Verarbeitung von Sprachbefehlen wie "open" oder "stop".
    try { // Tries to process the command. // Versucht, den Befehl zu verarbeiten.
      final commandLower = command.toLowerCase(); // Converts command to lowercase for case-insensitive comparison. // Konvertiert den Befehl in Kleinbuchstaben für einen Vergleich ohne Berücksichtigung der Groß-/Kleinschreibung.
      
      if (commandLower == "open") { // If the command is "open". // Wenn der Befehl "open" ist.
        // First update prompt screen state. // Aktualisiert zuerst den Zustand des Prompt-Bildschirms.
        _ref.read(promptScreenProvider.notifier).setListening(true); // Updates the prompt screen to show listening state. // Aktualisiert den Prompt-Bildschirm, um den Zuhörzustand anzuzeigen.
        
        // Start recording first. // Startet zuerst die Aufnahme.
        try { // Tries to start audio recording. // Versucht, die Audioaufnahme zu starten.
          await _recorder.startListening(command); // Starts the audio recorder. // Startet den Audio-Recorder.
          // Only update state after successful start of listening. // Aktualisiert den Zustand erst nach erfolgreichem Start des Zuhörens.
          state = state.copyWith( 
            isListening: true, // Sets listening flag to true. // Setzt das Zuhören-Flag auf true.
            lastCommand: command, // Updates last command. // Aktualisiert den letzten Befehl.
            isProcessing: false // Not processing anymore. // Nicht mehr in Verarbeitung.
          );
        } catch (e) { // Catches any errors during recording start. // Fängt alle Fehler beim Aufnahmestart ab.
          // If recording fails, update both states accordingly. // Wenn die Aufnahme fehlschlägt, werden beide Zustände entsprechend aktualisiert.
          _ref.read(promptScreenProvider.notifier).setListening(false); // Updates prompt screen to not listening. // Aktualisiert den Prompt-Bildschirm auf "nicht zuhörend".
          state = state.copyWith(
            isListening: false, // Sets listening flag to false. // Setzt das Zuhören-Flag auf false.
            error: e.toString(), // Sets error message. // Setzt die Fehlermeldung.
            isProcessing: false // Not processing anymore. // Nicht mehr in Verarbeitung.
          );
          throw e; // Re-throw to be caught by outer try-catch. // Wirft erneut, um vom äußeren try-catch gefangen zu werden.
        }
      } else if (commandLower == "stop") { // If the command is "stop". // Wenn der Befehl "stop" ist.
        if (state.isListening) { // Only process if currently listening. // Verarbeitet nur, wenn derzeit zugehört wird.
          try { // Tries to stop recording. // Versucht, die Aufnahme zu stoppen.
            final audioPath = await _recorder.stopListening(); // Stops the audio recorder and gets the recording file path. // Stoppt den Audio-Recorder und erhält den Aufnahmedateipfad.
            _ref.read(promptScreenProvider.notifier).setListening(false); // Updates the prompt screen to not listening. // Aktualisiert den Prompt-Bildschirm auf "nicht zuhörend".
            
            if (audioPath != null) { // If an audio file was successfully recorded. // Wenn eine Audiodatei erfolgreich aufgenommen wurde.
              state = state.copyWith(isProcessing: true); // Set state to processing. // Setzt den Zustand auf "Verarbeitung".
              final text = await _repository.processAudioInput(audioPath); // Process the audio file to get the transcribed text. // Verarbeitet die Audiodatei, um den transkribierten Text zu erhalten.
              _ref.read(promptScreenProvider.notifier).updateText(text); // Updates the prompt screen with the transcribed text. // Aktualisiert den Prompt-Bildschirm mit dem transkribierten Text.
              
              state = state.copyWith(
                isListening: false, // No longer listening. // Nicht mehr im Zuhören.
                lastCommand: text, // Sets the transcribed text as last command. // Setzt den transkribierten Text als letzten Befehl.
                isProcessing: false // Not processing anymore. // Nicht mehr in Verarbeitung.
              );
            } else { // If no audio file was produced. // Wenn keine Audiodatei erzeugt wurde.
              state = state.copyWith(
                isListening: false, // No longer listening. // Nicht mehr im Zuhören.
                error: "Failed to get audio path", // Sets error message. // Setzt die Fehlermeldung.
                isProcessing: false // Not processing anymore. // Nicht mehr in Verarbeitung.
              );
            }
          } catch (e) { // Catches errors during stop recording or processing. // Fängt Fehler beim Stoppen der Aufnahme oder Verarbeitung ab.
            state = state.copyWith(
              isListening: false, // No longer listening. // Nicht mehr im Zuhören.
              error: e.toString(), // Sets error message. // Setzt die Fehlermeldung.
              isProcessing: false // Not processing anymore. // Nicht mehr in Verarbeitung.
            );
          }
        }
      }
    } catch (e) { // Catches any outer errors during command processing. // Fängt alle äußeren Fehler bei der Befehlsverarbeitung ab.
      state = state.copyWith(
        isListening: false, // No longer listening. // Nicht mehr im Zuhören.
        error: e.toString(), // Sets error message. // Setzt die Fehlermeldung.
        isProcessing: false // Not processing anymore. // Nicht mehr in Verarbeitung.
      );
    }
  }

  Future<void> handleSpeechRecognition(String audioPath) async { // Method to process audio files for speech recognition. // Methode zur Verarbeitung von Audiodateien für die Spracherkennung.
    try { // Tries to process the audio. // Versucht, das Audio zu verarbeiten.
      final text = await _repository.processAudioInput(audioPath); // Gets transcribed text from audio file. // Erhält transkribierten Text aus der Audiodatei.
      if (text.toLowerCase() == "open") { // If the transcribed text is "open". // Wenn der transkribierte Text "open" ist.
        await processVoiceCommand("open"); // Process the "open" command. // Verarbeitet den "open"-Befehl.
      } else if (text.toLowerCase() == "stop") { // If the transcribed text is "stop". // Wenn der transkribierte Text "stop" ist.
        await processVoiceCommand("stop"); // Process the "stop" command. // Verarbeitet den "stop"-Befehl.
      }
    } catch (e) { // Catches any errors during speech recognition. // Fängt alle Fehler bei der Spracherkennung ab.
      state = state.copyWith(
        isListening: false, // No longer listening. // Nicht mehr im Zuhören.
        error: e.toString(), // Sets error message. // Setzt die Fehlermeldung.
        isProcessing: false // Not processing anymore. // Nicht mehr in Verarbeitung.
      );
    }
  }
}

final voiceCommandProvider = StateNotifierProvider<VoiceCommandNotifier, VoiceCommandState>((ref) { // Creates a Riverpod provider for voice command state. // Erstellt einen Riverpod-Provider für den Sprachbefehlszustand.
  return VoiceCommandNotifier( // Returns a new VoiceCommandNotifier instance. // Gibt eine neue VoiceCommandNotifier-Instanz zurück.
    ref.watch(audioRecorderProvider), // Gets the audio recorder service. // Holt den Audio-Recorder-Dienst.
    ref.watch(translationRepositoryProvider), // Gets the translation repository. // Holt das Übersetzungs-Repository.
    ref, // Passes ref for accessing other providers. // Übergibt ref für den Zugriff auf andere Provider.
  );
});
