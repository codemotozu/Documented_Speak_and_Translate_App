/// ConversationScreen
/// 
/// A Flutter widget that displays an AI conversation interface with text and audio capabilities. // Ein Flutter-Widget, das eine KI-Konversationsoberfläche mit Text- und Audiofunktionen anzeigt.
/// Manages message display, audio playback, and interaction with translation services. // Verwaltet die Nachrichtenanzeige, Audiowiedergabe und Interaktion mit Übersetzungsdiensten.
/// 
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => ConversationScreen(prompt: userInput),
///   ),
/// );
/// ```
/// 
/// EN: Displays a conversation interface between user and AI with support for text display and audio playback.
/// DE: Zeigt eine Konversationsoberfläche zwischen Benutzer und KI mit Unterstützung für Textanzeige und Audiowiedergabe an.

import 'dart:async'; // Imports async utilities for asynchronous operations. // Importiert asynchrone Hilfsmittel für asynchrone Operationen.
import 'package:flutter/material.dart'; // Imports core Flutter Material Design widgets. // Importiert Flutter Material Design-Widgets.
import 'package:flutter_markdown/flutter_markdown.dart'; // Imports Markdown rendering support. // Importiert Unterstützung für Markdown-Rendering.
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Imports Riverpod for state management. // Importiert Riverpod für die Zustandsverwaltung.
import '../../data/models/chat_message_model.dart'; // Imports chat message data model. // Importiert das Datenmodell für Chatnachrichten.
import '../../domain/repositories/translation_repository.dart'; // Imports the translation repository. // Importiert das Übersetzungs-Repository.
import '../providers/speech_provider.dart'; // Imports the speech provider for audio playback. // Importiert den Sprachprovider für die Audiowiedergabe.
import '../providers/translation_provider.dart'; // Imports the translation provider for message handling. // Importiert den Übersetzungsprovider für die Nachrichtenbehandlung.

class ConversationScreen extends ConsumerStatefulWidget { // Defines a stateful widget with Riverpod integration. // Definiert ein Stateful-Widget mit Riverpod-Integration.
  final String prompt; // The initial text prompt to start the conversation. // Der anfängliche Textprompt, um das Gespräch zu beginnen.

  const ConversationScreen({ // Constructor for the ConversationScreen. // Konstruktor für den ConversationScreen.
    super.key, // Passes the key to the parent class. // Übergibt den Schlüssel an die Elternklasse.
    required this.prompt, // Requires the prompt parameter. // Erfordert den Prompt-Parameter.
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState(); // Creates the state object for this widget. // Erstellt das State-Objekt für dieses Widget.
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> { // The state class for ConversationScreen. // Die State-Klasse für ConversationScreen.
  final ScrollController _scrollController = ScrollController(); // Controller for managing the scroll position. // Controller zur Verwaltung der Scrollposition.

  @override
  void initState() { // Initializes the state when the widget is created. // Initialisiert den State, wenn das Widget erstellt wird.
    super.initState(); // Calls the parent class initState. // Ruft initState der Elternklasse auf.
    WidgetsBinding.instance.addPostFrameCallback((_) { // Schedules a callback after the first frame renders. // Plant einen Callback nach dem Rendern des ersten Frames.
      if (widget.prompt.isNotEmpty) { // Checks if the prompt is not empty. // Prüft, ob der Prompt nicht leer ist.
        ref.read(translationProvider.notifier).startConversation(widget.prompt); // Starts a conversation with the prompt. // Startet ein Gespräch mit dem Prompt.
      }
    });
  }

  void _scrollToBottom() { // Method to scroll the conversation to the bottom. // Methode, um das Gespräch nach unten zu scrollen.
    WidgetsBinding.instance.addPostFrameCallback((_) { // Schedules the scroll after the frame renders. // Plant das Scrollen nach dem Rendern des Frames.
      if (_scrollController.hasClients) { // Checks if the scroll controller is attached to a scrollable. // Prüft, ob der Scroll-Controller an ein scrollbares Element angehängt ist.
        _scrollController.animateTo( // Animates to a specific position. // Animiert zu einer bestimmten Position.
          _scrollController.position.maxScrollExtent, // Scrolls to the bottom of the list. // Scrollt zum Ende der Liste.
          duration: const Duration(milliseconds: 300), // Animation duration. // Animationsdauer.
          curve: Curves.easeOut, // Animation curve for smooth motion. // Animationskurve für flüssige Bewegung.
        );
      }
    });
  }

@override
void dispose() { // Cleans up resources when the widget is removed. // Bereinigt Ressourcen, wenn das Widget entfernt wird.
  _scrollController.dispose(); // Disposes the scroll controller. // Entsorgt den Scroll-Controller.
  
  final shouldStopSpeech = mounted; // Checks if the widget is still mounted. // Prüft, ob das Widget noch eingefügt ist.
  WidgetsBinding.instance.addPostFrameCallback((_) { // Schedules a callback after the frame. // Plant einen Callback nach dem Frame.
    if (shouldStopSpeech && mounted) { // Double-checks that widget is still mounted. // Prüft nochmals, ob das Widget noch eingefügt ist.
      try {
        ref.read(speechProvider.notifier).stop(); // Stops any playing audio. // Stoppt alle abspielenden Audios.
      } catch (e) {
        print('Safe disposal error: $e'); // Logs any errors during disposal. // Protokolliert alle Fehler während der Entsorgung.
      }
    }
  });
  
  super.dispose(); // Calls the parent class dispose. // Ruft dispose der Elternklasse auf.
}



  @override
  Widget build(BuildContext context) { // Builds the widget tree for this screen. // Erstellt den Widget-Baum für diesen Bildschirm.
    final translationState = ref.watch(translationProvider); // Watches the translation state. // Beobachtet den Übersetzungszustand.
    final speechState = ref.watch(speechProvider); // Watches the speech state (audio playback). // Beobachtet den Sprachzustand (Audiowiedergabe).

    return Scaffold( // Creates a basic Material Design layout. // Erstellt ein grundlegendes Material Design-Layout.
      backgroundColor: const Color(0xFF000000), // Sets black background color. // Setzt schwarze Hintergrundfarbe.
      appBar: AppBar( // Creates an app bar at the top. // Erstellt eine App-Leiste oben.
        centerTitle: true, // Centers the title in the app bar. // Zentriert den Titel in der App-Leiste.
        backgroundColor: const Color(0xFF1C1C1E), // Sets dark gray app bar color. // Setzt dunkelgraue App-Leisten-Farbe.
        title: const Text('AI Conversation', // Title text for the app bar. // Titeltext für die App-Leiste.
            style: TextStyle(color: Colors.white)), // White text color. // Weiße Textfarbe.
        actions: [ // Action buttons in the app bar. // Aktionsschaltflächen in der App-Leiste.
          IconButton( // Creates a clickable icon. // Erstellt ein anklickbares Symbol.
            icon: const Icon(Icons.delete, color: Colors.white), // Trash icon for clearing history. // Papierkorbsymbol zum Löschen des Verlaufs.
            onPressed: () =>
                ref.read(translationProvider.notifier).clearConversation(), // Clears conversation history. // Löscht den Gesprächsverlauf.
            tooltip: 'Clear history', // Tooltip text for the button. // Tooltip-Text für die Schaltfläche.
          ),
          IconButton( // Another action button. // Eine weitere Aktionsschaltfläche.
            icon: Icon( // Dynamic icon based on speech state. // Dynamisches Symbol basierend auf dem Sprachzustand.
              speechState ? Icons.volume_up : Icons.volume_off, // Shows volume up or off based on state. // Zeigt Lautstärke an oder aus, basierend auf dem Zustand.
              color: speechState ? Colors.white : Colors.grey, // Color changes based on state. // Farbe ändert sich basierend auf dem Zustand.
            ),
            onPressed: () =>
                ref.read(speechProvider.notifier).toggleHandsFreeMode(), // Toggles hands-free mode. // Schaltet den Freisprechmodus um.
            tooltip: speechState ? 'Disable audio' : 'Enable audio', // Dynamic tooltip. // Dynamischer Tooltip.
          ),
        ],
      ),
      body: Column( // Main layout column. // Hauptlayout-Spalte.
        children: [
          Expanded( // Expands to fill available space. // Erweitert sich, um verfügbaren Platz zu füllen.
            child: ListView.builder( // Creates a scrollable list of messages. // Erstellt eine scrollbare Liste von Nachrichten.
              controller: _scrollController, // Attaches the scroll controller. // Fügt den Scroll-Controller hinzu.
              padding: const EdgeInsets.all(16), // Adds padding around the list. // Fügt Polsterung um die Liste hinzu.
              itemCount: translationState.messages.length, // Number of messages to display. // Anzahl der anzuzeigenden Nachrichten.
              itemBuilder: (context, index) { // Builder function for each message. // Erstellungsfunktion für jede Nachricht.
                final message = translationState.messages[index]; // Gets the message for this index. // Holt die Nachricht für diesen Index.
                return _buildMessageWidget(message, speechState); // Builds the appropriate message widget. // Erstellt das entsprechende Nachrichten-Widget.
              },
            ),
          ),
      
        ],
      ),
    );
  }

  Widget _buildMessageWidget(ChatMessage message, bool speechState) { // Helper method to build a message widget. // Hilfsmethode zum Erstellen eines Nachrichten-Widgets.
    switch (message.type) { // Switch based on message type. // Switch basierend auf dem Nachrichtentyp.
      case MessageType.user: // For user messages. // Für Benutzernachrichten.
        return _buildUserMessage(message); // Builds a user message bubble. // Erstellt eine Benutzernachrichtenblase.
      case MessageType.ai: // For AI messages. // Für KI-Nachrichten.
        if (message.isLoading) return _buildLoadingMessage(); // Shows loading indicator if needed. // Zeigt Ladeindikator, wenn nötig.
        if (message.error != null) return _buildErrorMessage(message.error!); // Shows error if present. // Zeigt Fehler, wenn vorhanden.
        return _buildAiMessage(message, speechState); // Builds the AI message with audio controls. // Erstellt die KI-Nachricht mit Audiosteuerungen.
    }
  }

  Widget _buildUserMessage(ChatMessage message) { // Builds a user message bubble. // Erstellt eine Benutzernachrichtenblase.
    return Container( // Creates a container for the message. // Erstellt einen Container für die Nachricht.
      padding: const EdgeInsets.all(12), // Inner padding. // Innere Polsterung.
      margin: const EdgeInsets.only(bottom: 16), // Bottom margin for spacing. // Unterer Rand für Abstand.
      decoration: BoxDecoration( // Visual styling for the container. // Visuelle Gestaltung für den Container.
        color: Colors.grey[900], // Dark gray background. // Dunkelgrauer Hintergrund.
        borderRadius: BorderRadius.circular(8), // Rounded corners. // Abgerundete Ecken.
      ),
      child: Row( // Row layout for avatar and text. // Zeilenaufbau für Avatar und Text.
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns items to the top. // Richtet Elemente oben aus.
        children: [
          CircleAvatar( // User avatar. // Benutzer-Avatar.
            backgroundColor: Colors.orange[100], // Light orange background. // Hellgelber Hintergrund.
            child: const Icon(Icons.person, color: Colors.black), // Person icon. // Personensymbol.
          ),
          const SizedBox(width: 12), // Horizontal spacing. // Horizontaler Abstand.
          Expanded( // Expands to fill available width. // Erweitert sich, um verfügbare Breite zu füllen.
            child: Text( // Message text. // Nachrichtentext.
              message.text, // The message content. // Der Nachrichteninhalt.
              style: TextStyle( // Text styling. // Textstil.
                fontSize: 16, // Font size. // Schriftgröße.
                fontWeight: FontWeight.w500, // Medium font weight. // Mittlere Schriftstärke.
                color: Colors.orange[700], // Orange text color. // Orange Textfarbe.
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessage(ChatMessage message, bool speechState) { // Builds an AI message bubble. // Erstellt eine KI-Nachrichtenblase.
    final translation = message.translation!; // Gets the translation data. // Holt die Übersetzungsdaten.

    if (speechState && translation.audioPath != null) { // If hands-free mode is on and audio is available. // Wenn der Freisprechmodus aktiviert ist und Audio verfügbar ist.
      WidgetsBinding.instance.addPostFrameCallback((_) async { // Schedules after frame renders. // Plant nach dem Rendern des Frames.
        try {
          await ref
              .read(speechProvider.notifier)
              .playAudio(translation.audioPath); // Plays the audio automatically. // Spielt das Audio automatisch ab.
          ref.read(translationProvider.notifier).clearConversation(); // Clears the conversation. // Löscht das Gespräch.

          if (mounted) { // Checks if widget is still mounted. // Prüft, ob das Widget noch eingefügt ist.
            Navigator.pop(context); // Navigates back to previous screen. // Navigiert zurück zum vorherigen Bildschirm.
            // Add this to ensure sound plays after navigation animation completes. // Fügt dies hinzu, um sicherzustellen, dass der Ton nach Abschluss der Navigationsanimation abgespielt wird.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(translationRepositoryProvider).playCompletionSound(); // Plays completion sound effect. // Spielt Abschluss-Soundeffekt.
            });
          }
        } catch (e) {
          print('Error handling audio completion: $e'); // Logs any errors. // Protokolliert alle Fehler.
        }
      });
    }

    return Container( // Creates a container for the message. // Erstellt einen Container für die Nachricht.
      padding: const EdgeInsets.all(12), // Inner padding. // Innere Polsterung.
      margin: const EdgeInsets.only(bottom: 16), // Bottom margin for spacing. // Unterer Rand für Abstand.
      decoration: BoxDecoration( // Visual styling. // Visuelle Gestaltung.
        color: Colors.grey[900], // Dark gray background. // Dunkelgrauer Hintergrund.
        borderRadius: BorderRadius.circular(8), // Rounded corners. // Abgerundete Ecken.
      ),
      child: Row( // Row layout for avatar and content. // Zeilenaufbau für Avatar und Inhalt.
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns items to the top. // Richtet Elemente oben aus.
        children: [
          CircleAvatar( // AI avatar. // KI-Avatar.
            backgroundColor: Colors.blue[100], // Light blue background. // Hellblauer Hintergrund.
            child: const Icon(Icons.smart_toy), // Robot icon. // Robotersymbol.
          ),
          const SizedBox(width: 12), // Horizontal spacing. // Horizontaler Abstand.
          Expanded( // Expands to fill available width. // Erweitert sich, um verfügbare Breite zu füllen.
            child: Column( // Column layout for text and controls. // Spaltenaufbau für Text und Steuerelemente.
              crossAxisAlignment: CrossAxisAlignment.start, // Aligns items to the left. // Richtet Elemente links aus.
              children: [
                MarkdownBody( // Renders markdown formatted text. // Rendert Markdown-formatierten Text.
                  data: translation.translatedText, // The translated text content. // Der übersetzte Textinhalt.
                  styleSheet: MarkdownStyleSheet( // Styling for markdown elements. // Stil für Markdown-Elemente.
                    p: const TextStyle(fontSize: 16, color: Colors.white), // Paragraph style. // Absatzstil.
                    h1: const TextStyle(fontSize: 24, color: Colors.orange), // Heading 1 style. // Überschrift-1-Stil.
                    h2: const TextStyle(fontSize: 22, color: Colors.orange), // Heading 2 style. // Überschrift-2-Stil.
                    h3: const TextStyle(fontSize: 20, color: Colors.orange), // Heading 3 style. // Überschrift-3-Stil.
                    code: const TextStyle( // Code block style. // Codeblock-Stil.
                      backgroundColor: Colors.orange, // Orange background for code. // Oranger Hintergrund für Code.
                      fontFamily: 'monospace', // Monospace font for code. // Monospace-Schrift für Code.
                    ),
                    listBullet: TextStyle(color: Colors.orange[800]), // Bullet point style. // Aufzählungszeichenstil.
                  ),
                ),
                if (translation.audioPath != null) // Conditional audio controls. // Bedingte Audiosteuerungen.
                  Padding( // Adds padding around controls. // Fügt Polsterung um Steuerelemente hinzu.
                    padding: const EdgeInsets.only(top: 8.0), // Top padding. // Obere Polsterung.
                    child: Row( // Row layout for audio controls. // Zeilenaufbau für Audiosteuerungen.
                      mainAxisSize: MainAxisSize.min, // Minimizes row width. // Minimiert die Zeilenbreite.
                      children: [
                        IconButton( // Play/pause button. // Wiedergabe/Pause-Schaltfläche.
                          icon: Icon( // Dynamic icon based on state. // Dynamisches Symbol basierend auf dem Zustand.
                            speechState
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill, // Play or pause icon. // Wiedergabe- oder Pause-Symbol.
                            color: Colors.orange[800], // Orange icon color. // Orange Symbolfarbe.
                          ),
                          onPressed: () { // Button press handler. // Behandlung des Tastendrucks.
                            if (speechState) { // If audio is playing. // Wenn Audio abgespielt wird.
                              ref.read(speechProvider.notifier).stop(); // Stop playback. // Stoppt die Wiedergabe.
                            } else { // If audio is not playing. // Wenn Audio nicht abgespielt wird.
                              ref
                                  .read(speechProvider.notifier)
                                  .playAudio(translation.audioPath); // Start playback. // Startet die Wiedergabe.
                            }
                          },
                        ),
                        Text( // Label for button. // Bezeichnung für die Schaltfläche.
                          speechState ? 'Pause' : 'Play', // Dynamic text based on state. // Dynamischer Text basierend auf dem Zustand.
                          style: TextStyle(color: Colors.orange[800]), // Orange text color. // Orange Textfarbe.
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() { // Builds a loading indicator. // Erstellt einen Ladeindikator.
    return const Padding( // Adds padding around indicator. // Fügt Polsterung um den Indikator hinzu.
      padding: EdgeInsets.symmetric(vertical: 16.0), // Vertical padding. // Vertikale Polsterung.
      child: Center( // Centers the content. // Zentriert den Inhalt.
        child: Column( // Column layout for spinner and text. // Spaltenaufbau für Spinner und Text.
          children: [
            CircularProgressIndicator(), // Loading spinner. // Lade-Spinner.
            SizedBox(height: 8), // Vertical spacing. // Vertikaler Abstand.
            Text('Thinking...', style: TextStyle(color: Colors.white)), // Loading text. // Ladetext.
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) { // Builds an error message. // Erstellt eine Fehlermeldung.
    return Padding( // Adds padding around error. // Fügt Polsterung um den Fehler hinzu.
      padding: const EdgeInsets.symmetric(vertical: 16.0), // Vertical padding. // Vertikale Polsterung.
      child: Container( // Container for error message. // Container für Fehlermeldung.
        padding: const EdgeInsets.all(16), // Inner padding. // Innere Polsterung.
        decoration: BoxDecoration( // Visual styling. // Visuelle Gestaltung.
          color: Colors.red[900]!.withOpacity(0.3), // Transparent red background. // Transparenter roter Hintergrund.
          borderRadius: BorderRadius.circular(8), // Rounded corners. // Abgerundete Ecken.
        ),
        child: Row( // Row layout for icon and text. // Zeilenaufbau für Symbol und Text.
          children: [
            const Icon(Icons.error_outline, color: Colors.red), // Error icon. // Fehlersymbol.
            const SizedBox(width: 12), // Horizontal spacing. // Horizontaler Abstand.
            Expanded( // Expands to fill available width. // Erweitert sich, um verfügbare Breite zu füllen.
              child: Text( // Error text. // Fehlertext.
                'Error: $error', // Error message content. // Fehlermeldungsinhalt.
                style: const TextStyle(color: Colors.red), // Red text color. // Rote Textfarbe.
              ),
            ),
          ],
        ),
      ),
    );
  }
}
