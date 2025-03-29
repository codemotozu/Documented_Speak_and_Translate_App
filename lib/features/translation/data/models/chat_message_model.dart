/// ChatMessage
///
/// A class that represents different types of messages in a chat interface. // Eine Klasse, die verschiedene Arten von Nachrichten in einer Chat-Oberfläche darstellt.
/// Handles different states of messages including user input, AI responses, loading states, and errors. // Behandelt verschiedene Zustände von Nachrichten, einschließlich Benutzereingaben, KI-Antworten, Ladezustände und Fehler.
///
/// Usage:
/// ```dart
/// // Create a user message // Erstellen einer Benutzernachricht
/// final userMessage = ChatMessage.user("Hello, how can I help you?");
///
/// // Create an AI message with translation // Erstellen einer KI-Nachricht mit Übersetzung
/// final aiMessage = ChatMessage.ai(translation: translationObject);
///
/// // Create a loading message while waiting for AI response // Erstellen einer Ladenachricht während des Wartens auf eine KI-Antwort
/// final loadingMessage = ChatMessage.aiLoading();
///
/// // Create an error message // Erstellen einer Fehlernachricht
/// final errorMessage = ChatMessage.aiError("Failed to get response");
/// ```
///
/// EN: Provides different constructors for various message types and states in a chat application.
/// DE: Bietet verschiedene Konstruktoren für verschiedene Nachrichtentypen und -zustände in einer Chat-Anwendung.

import '../../domain/entities/translation.dart'; // Imports the Translation entity from a relative path. // Importiert die Translation-Entität aus einem relativen Pfad.

enum MessageType { user, ai } // Defines an enumeration with two possible message types: user and AI. // Definiert eine Aufzählung mit zwei möglichen Nachrichtentypen: Benutzer und KI.

class ChatMessage { // Defines a class to represent messages in a chat interface. // Definiert eine Klasse zur Darstellung von Nachrichten in einer Chat-Oberfläche.
  final MessageType type; // The type of message (user or AI). // Der Typ der Nachricht (Benutzer oder KI).
  final String text; // The text content of the message. // Der Textinhalt der Nachricht.
  final Translation? translation; // Optional translation information, can be null. // Optionale Übersetzungsinformationen, kann null sein.
  final bool isLoading; // Flag to indicate if the message is in a loading state. // Kennzeichen, um anzuzeigen, ob sich die Nachricht in einem Ladezustand befindet.
  final String? error; // Optional error message, can be null. // Optionale Fehlermeldung, kann null sein.

  ChatMessage.user(this.text) // Named constructor for creating a user message. // Benannter Konstruktor zum Erstellen einer Benutzernachricht.
      : type = MessageType.user, // Sets the message type to user. // Setzt den Nachrichtentyp auf Benutzer.
        translation = null, // User messages don't have translations. // Benutzernachrichten haben keine Übersetzungen.
        isLoading = false, // User messages are never in loading state. // Benutzernachrichten sind nie im Ladezustand.
        error = null; // User messages don't have errors. // Benutzernachrichten haben keine Fehler.

  ChatMessage.ai({required Translation translation}) // Named constructor for creating a completed AI message with translation. // Benannter Konstruktor zum Erstellen einer fertigen KI-Nachricht mit Übersetzung.
      : type = MessageType.ai, // Sets the message type to AI. // Setzt den Nachrichtentyp auf KI.
        text = translation.translatedText, // Uses translated text as the message content. // Verwendet übersetzten Text als Nachrichteninhalt.
        translation = translation, // Stores the full translation object for reference. // Speichert das vollständige Übersetzungsobjekt zur Referenz.
        isLoading = false, // Completed AI messages are not in loading state. // Fertige KI-Nachrichten sind nicht im Ladezustand.
        error = null; // Completed AI messages don't have errors. // Fertige KI-Nachrichten haben keine Fehler.

  ChatMessage.aiLoading() // Named constructor for creating an AI message in loading state. // Benannter Konstruktor zum Erstellen einer KI-Nachricht im Ladezustand.
      : type = MessageType.ai, // Sets the message type to AI. // Setzt den Nachrichtentyp auf KI.
        text = '', // Empty text for loading messages. // Leerer Text für Ladenachrichten.
        translation = null, // Loading messages don't have translations yet. // Ladenachrichten haben noch keine Übersetzungen.
        isLoading = true, // Sets the loading flag to true. // Setzt das Lade-Flag auf wahr.
        error = null; // Loading messages don't have errors. // Ladenachrichten haben keine Fehler.

  ChatMessage.aiError(this.error) // Named constructor for creating an AI message with an error. // Benannter Konstruktor zum Erstellen einer KI-Nachricht mit einem Fehler.
      : type = MessageType.ai, // Sets the message type to AI. // Setzt den Nachrichtentyp auf KI.
        text = error ?? 'An error occurred', // Uses the error message as text or a default if null. // Verwendet die Fehlermeldung als Text oder einen Standardwert, wenn null.
        translation = null, // Error messages don't have translations. // Fehlermeldungen haben keine Übersetzungen.
        isLoading = false; // Error messages are not in loading state. // Fehlermeldungen sind nicht im Ladezustand.
}
