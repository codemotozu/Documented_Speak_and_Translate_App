/// PromptScreen State Management
/// 
/// A state management solution for handling user input and listening status in the prompt screen. // Eine Zustandsverwaltungslösung zur Handhabung von Benutzereingaben und Zuhörstatus auf dem Eingabebildschirm.
/// Uses Riverpod's StateNotifier pattern to manage and update UI state reactively. // Verwendet Riverpods StateNotifier-Muster, um UI-Zustände reaktiv zu verwalten und zu aktualisieren.
///
/// This implementation manages two key pieces of state: // Diese Implementierung verwaltet zwei wichtige Zustandselemente:
/// - The listening status (whether the app is currently recording audio) // - Den Zuhörstatus (ob die App gerade Audio aufnimmt)
/// - The current text input (from typing or speech recognition) // - Die aktuelle Texteingabe (durch Tippen oder Spracherkennung)
///
/// Usage:
/// ```dart
/// // Access the state in a widget // Zugriff auf den Zustand in einem Widget
/// final promptState = ref.watch(promptScreenProvider);
/// 
/// // Use the state values // Verwenden der Zustandswerte
/// Text(promptState.currentText);
/// Icon(promptState.isListening ? Icons.mic : Icons.mic_off);
/// 
/// // Update the state // Aktualisieren des Zustands
/// ref.read(promptScreenProvider.notifier).setListening(true);
/// ref.read(promptScreenProvider.notifier).updateText("Hello");
/// ref.read(promptScreenProvider.notifier).submitCommand("translate to German");
/// ```
///
/// EN: Implements state management for the prompt screen using Riverpod's StateNotifier pattern.
/// DE: Implementiert die Zustandsverwaltung für den Eingabebildschirm mit Riverpods StateNotifier-Muster.

import 'package:flutter_riverpod/flutter_riverpod.dart'; // Imports Riverpod for state management. // Importiert Riverpod für die Zustandsverwaltung.

final promptScreenProvider = StateNotifierProvider<PromptScreenNotifier, PromptScreenState>((ref) { // Defines a StateNotifierProvider that makes the state and notifier available to widgets. // Definiert einen StateNotifierProvider, der den Zustand und Notifier für Widgets verfügbar macht.
  return PromptScreenNotifier(); // Returns a new instance of the state notifier. // Gibt eine neue Instanz des Zustandsnotifiers zurück.
});

/// PromptScreenState
/// 
/// An immutable state class that holds the current state of the prompt screen. // Eine unveränderliche Zustandsklasse, die den aktuellen Zustand des Eingabebildschirms enthält.
/// Contains all the data needed to render the UI for text input and voice recording. // Enthält alle Daten, die zum Rendern der Benutzeroberfläche für Texteingabe und Sprachaufnahme benötigt werden.

class PromptScreenState { // Defines the state class for the prompt screen. // Definiert die Zustandsklasse für den Eingabebildschirm.
  final bool isListening; // Whether the app is currently recording audio input. // Ob die App derzeit Audioeingaben aufzeichnet.
  final String currentText; // The current text input, either typed or from speech recognition. // Die aktuelle Texteingabe, entweder getippt oder aus der Spracherkennung.

  PromptScreenState({this.isListening = false, this.currentText = ''}); // Constructor with default values for both fields. // Konstruktor mit Standardwerten für beide Felder.
}

/// PromptScreenNotifier
/// 
/// A state notifier that manages and updates the prompt screen state. // Ein Zustandsnotifier, der den Zustand des Eingabebildschirms verwaltet und aktualisiert.
/// Provides methods to modify the state while maintaining immutability. // Bietet Methoden zur Änderung des Zustands unter Beibehaltung der Unveränderlichkeit.

class PromptScreenNotifier extends StateNotifier<PromptScreenState> { // State notifier class that extends StateNotifier with PromptScreenState type. // Zustandsnotifier-Klasse, die StateNotifier mit dem Typ PromptScreenState erweitert.
  PromptScreenNotifier() : super(PromptScreenState()); // Constructor that initializes with default state. // Konstruktor, der mit dem Standardzustand initialisiert.

  void setListening(bool listening) { // Method to update the listening status. // Methode zur Aktualisierung des Zuhörstatus.
    state = PromptScreenState( // Creates a new state instance with updated values. // Erstellt eine neue Zustandsinstanz mit aktualisierten Werten.
      isListening: listening, // Sets the new listening status. // Setzt den neuen Zuhörstatus.
      currentText: state.currentText // Preserves the current text value. // Behält den aktuellen Textwert bei.
    );
  }

  void updateText(String text) { // Method to update the text input. // Methode zur Aktualisierung der Texteingabe.
    state = PromptScreenState( // Creates a new state instance with updated values. // Erstellt eine neue Zustandsinstanz mit aktualisierten Werten.
      isListening: state.isListening, // Preserves the current listening status. // Behält den aktuellen Zuhörstatus bei.
      currentText: text // Sets the new text value. // Setzt den neuen Textwert.
    );
  }

 void submitCommand(String command) { // Method to submit a completed command and stop listening. // Methode zum Übermitteln eines abgeschlossenen Befehls und Beenden des Zuhörens.
    state = PromptScreenState( // Creates a new state instance with updated values. // Erstellt eine neue Zustandsinstanz mit aktualisierten Werten.
      isListening: false, // Sets listening to false as the command is complete. // Setzt Zuhören auf falsch, da der Befehl abgeschlossen ist.
      currentText: command // Sets the command as the current text. // Setzt den Befehl als aktuellen Text.
    );
 }
}
