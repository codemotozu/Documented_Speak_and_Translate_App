/// PromptScreen
/// 
/// A voice-controlled chat assistant app that uses wake words and speech-to-text functionality. // Eine sprachgesteuerte Chat-Assistent-App, die Aktivierungswörter und Sprache-zu-Text-Funktionalität verwendet.
/// The app listens for wake words "Jarvis" to start recording and "Alexa" to stop. // Die App hört auf die Aktivierungswörter "Jarvis" zum Starten der Aufnahme und "Alexa" zum Stoppen.
/// 
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const PromptScreen()),
/// );
/// ```
/// 
/// EN: Implements a voice-controlled interface for an AI chat assistant with wake word detection.
/// DE: Implementiert eine sprachgesteuerte Schnittstelle für einen KI-Chat-Assistenten mit Erkennung von Aktivierungswörtern.

import 'package:flutter/cupertino.dart'; // Imports Cupertino (iOS-style) widgets from Flutter. // Importiert Cupertino-Widgets (iOS-Stil) aus Flutter.
import 'package:flutter/material.dart'; // Imports Material Design (Android-style) widgets from Flutter. // Importiert Material Design-Widgets (Android-Stil) aus Flutter.
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Imports Riverpod for state management. // Importiert Riverpod für die Zustandsverwaltung.
import 'package:porcupine_flutter/porcupine.dart'; // Imports Porcupine wake word detection package. // Importiert das Porcupine-Paket zur Erkennung von Aktivierungswörtern.
import 'package:porcupine_flutter/porcupine_error.dart'; // Imports Porcupine error handling. // Importiert die Porcupine-Fehlerbehandlung.
import 'package:porcupine_flutter/porcupine_manager.dart'; // Imports Porcupine manager for wake word detection. // Importiert den Porcupine-Manager für die Erkennung von Aktivierungswörtern.
import 'package:speech_to_text/speech_to_text.dart' as stt; // Imports speech-to-text package with an alias. // Importiert das Spracherkennung-Paket mit einem Alias.
import '../../domain/repositories/translation_repository.dart'; // Imports the translation repository from the domain layer. // Importiert das Übersetzungs-Repository aus der Domain-Schicht.
import '../providers/audio_recorder_provider.dart'; // Imports the audio recorder provider. // Importiert den Audio-Recorder-Provider.
import '../providers/voice_command_provider.dart'; // Imports the voice command provider. // Importiert den Sprachbefehl-Provider.
import '../widgets/voice_command_status_inficator.dart'; // Imports the voice command status indicator widget. // Importiert das Widget für die Statusanzeige von Sprachbefehlen.

final isListeningProvider = StateProvider<bool>((ref) => false); // Creates a state provider that tracks if the app is listening. // Erstellt einen State-Provider, der verfolgt, ob die App zuhört.

class PromptScreen extends ConsumerStatefulWidget { // Defines a stateful widget that can access Riverpod providers. // Definiert ein Stateful-Widget, das auf Riverpod-Provider zugreifen kann.
  const PromptScreen({super.key}); // Constructor that accepts a key parameter. // Konstruktor, der einen Key-Parameter akzeptiert.

  @override
  ConsumerState<PromptScreen> createState() => _PromptScreenState(); // Creates the mutable state for this widget. // Erstellt den veränderbaren Zustand für dieses Widget.
}

class _PromptScreenState extends ConsumerState<PromptScreen> { // Defines the state class for the PromptScreen. // Definiert die Zustandsklasse für den PromptScreen.
  late final TextEditingController _textController; // Declares a text controller that will be initialized later. // Deklariert einen Textcontroller, der später initialisiert wird.
  late final AudioRecorder _recorder; // Declares an audio recorder that will be initialized later. // Deklariert einen Audio-Recorder, der später initialisiert wird.
  late PorcupineManager _porcupineManager; // Declares a Porcupine manager for wake word detection. // Deklariert einen Porcupine-Manager für die Erkennung von Aktivierungswörtern.
  late stt.SpeechToText _speech; // Declares a speech-to-text instance. // Deklariert eine Instanz von Sprache-zu-Text.
  bool _isWakeWordMode = true; // Tracks if the app is in wake word detection mode. // Verfolgt, ob die App im Modus zur Erkennung von Aktivierungswörtern ist.

  @override
  void initState() { // Initializes the state when the widget is inserted into the tree. // Initialisiert den Zustand, wenn das Widget in den Baum eingefügt wird.
    super.initState(); // Calls the parent class initState method. // Ruft die initState-Methode der Elternklasse auf.
    _textController = TextEditingController(); // Initializes the text controller. // Initialisiert den Textcontroller.
    _recorder = ref.read(audioRecorderProvider); // Gets the audio recorder from the provider. // Holt den Audio-Recorder vom Provider.
    _speech = stt.SpeechToText(); // Initializes the speech-to-text instance. // Initialisiert die Sprache-zu-Text-Instanz.

    _initializeRecorder(); // Calls the method to initialize the recorder. // Ruft die Methode zur Initialisierung des Recorders auf.
    _initPorcupine(); // Calls the method to initialize Porcupine wake word detection. // Ruft die Methode zur Initialisierung der Porcupine-Aktivierungswort-Erkennung auf.
  }

  Future<void> _initializeRecorder() async { // Defines an async method to initialize the recorder. // Definiert eine asynchrone Methode zur Initialisierung des Recorders.
    try { // Starts a try block for error handling. // Beginnt einen Try-Block für die Fehlerbehandlung.
      await _recorder.init(); // Initializes the recorder asynchronously. // Initialisiert den Recorder asynchron.
    } catch (e) { // Catches any errors during initialization. // Fängt alle Fehler während der Initialisierung ab.
      debugPrint('Recorder init error: $e'); // Prints the error to the debug console. // Gibt den Fehler in der Debug-Konsole aus.
    }
  }

  void _initPorcupine() async { // Defines an async method to initialize Porcupine. // Definiert eine asynchrone Methode zur Initialisierung von Porcupine.
    try { // Starts a try block for error handling. // Beginnt einen Try-Block für die Fehlerbehandlung.
      _porcupineManager = await PorcupineManager.fromBuiltInKeywords( // Initializes Porcupine manager with built-in keywords. // Initialisiert den Porcupine-Manager mit eingebauten Schlüsselwörtern.
         'PICOVOICE_API_KEY', // The API key for Picovoice services. // Der API-Schlüssel für Picovoice-Dienste.
        [BuiltInKeyword.JARVIS, BuiltInKeyword.ALEXA], // Sets "Jarvis" and "Alexa" as wake words. // Legt "Jarvis" und "Alexa" als Aktivierungswörter fest.
        _wakeWordCallback, // Provides a callback function for wake word detection. // Stellt eine Callback-Funktion für die Erkennung von Aktivierungswörtern bereit.
      );
      await _porcupineManager.start(); // Starts the Porcupine manager to listen for wake words. // Startet den Porcupine-Manager, um auf Aktivierungswörter zu hören.
      debugPrint("Porcupine initialized successfully"); // Logs successful initialization. // Protokolliert erfolgreiche Initialisierung.
    } on PorcupineException catch (err) { // Catches Porcupine-specific exceptions. // Fängt Porcupine-spezifische Ausnahmen ab.
      debugPrint("Failed to initialize Porcupine: ${err.message}"); // Logs the error message. // Protokolliert die Fehlermeldung.
    }
  }

  Future<void> _startConversation() async { // Defines a method to start a conversation with the AI. // Definiert eine Methode zum Starten einer Konversation mit der KI.
    if (_textController.text.isNotEmpty) { // Checks if there is text to send. // Prüft, ob Text zum Senden vorhanden ist.
      await ref.read(translationRepositoryProvider).playUISound('start_conversation'); // Plays a UI sound to indicate conversation start. // Spielt einen UI-Sound ab, um den Gesprächsstart anzuzeigen.

      if (mounted) { // Checks if the widget is still in the tree. // Prüft, ob das Widget noch im Baum ist.
        Navigator.pushNamed( // Navigates to a new screen. // Navigiert zu einem neuen Bildschirm.
          context,
          '/conversation', // The route name for the conversation screen. // Der Routenname für den Konversationsbildschirm.
          arguments: _textController.text, // Passes the text as an argument. // Übergibt den Text als Argument.
        ).then((_) => _textController.clear()); // Clears the text field after navigation. // Löscht das Textfeld nach der Navigation.
      }
    }
  }

  void _wakeWordCallback(int keywordIndex) async { // Callback function triggered when a wake word is detected. // Callback-Funktion, die ausgelöst wird, wenn ein Aktivierungswort erkannt wird.
    if (!mounted) return; // Returns if the widget is no longer in the tree. // Kehrt zurück, wenn das Widget nicht mehr im Baum ist.

    // JARVIS detected
    if (keywordIndex == 0 && _isWakeWordMode) { // Checks if "Jarvis" was detected and app is in wake word mode. // Prüft, ob "Jarvis" erkannt wurde und die App im Aktivierungswort-Modus ist.
      await _startVoiceRecording(); // Starts voice recording. // Startet die Sprachaufnahme.
      _isWakeWordMode = false; // Sets wake word mode to false. // Setzt den Aktivierungswort-Modus auf falsch.
    }
    // ALEXA detected
    else if (keywordIndex == 1 && !_isWakeWordMode) { // Checks if "Alexa" was detected and app is not in wake word mode. // Prüft, ob "Alexa" erkannt wurde und die App nicht im Aktivierungswort-Modus ist.
      await _stopVoiceRecording(); // Stops voice recording. // Stoppt die Sprachaufnahme.
      _isWakeWordMode = true; // Sets wake word mode to true. // Setzt den Aktivierungswort-Modus auf wahr.
      
      // Automatically start conversation after stopping recording
      if (_textController.text.isNotEmpty) { // Checks if there is text to send. // Prüft, ob Text zum Senden vorhanden ist.
        await _startConversation(); // Starts a conversation with the AI. // Startet eine Konversation mit der KI.
      }
    }
  }

  void _handleVoiceCommand(VoiceCommandState state) { // Handles changes in voice command state. // Behandelt Änderungen im Zustand des Sprachbefehls.
    if (!mounted) return; // Returns if the widget is no longer in the tree. // Kehrt zurück, wenn das Widget nicht mehr im Baum ist.
    setState(() {}); // Triggers a UI update. // Löst eine UI-Aktualisierung aus.

    if (state.error != null) { // Checks if there is an error in the voice command state. // Prüft, ob ein Fehler im Zustand des Sprachbefehls vorliegt.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.error!))); // Shows an error message as a snack bar. // Zeigt eine Fehlermeldung als Snack-Bar an.
    }
  }

  Future<void> _startVoiceRecording() async { // Defines a method to start voice recording. // Definiert eine Methode zum Starten der Sprachaufnahme.
    try { // Starts a try block for error handling. // Beginnt einen Try-Block für die Fehlerbehandlung.
      await ref.read(translationRepositoryProvider).playUISound('mic_on'); // Plays a sound to indicate microphone activation. // Spielt einen Sound ab, um die Mikrofonaktivierung anzuzeigen.
      await _recorder.startListening("open"); // Starts the audio recorder. // Startet den Audio-Recorder.
      ref.read(isListeningProvider.notifier).state = true; // Updates the listening state to true. // Aktualisiert den Hörzustand auf wahr.
      final currentState = ref.read(voiceCommandProvider); // Gets the current voice command state. // Holt den aktuellen Zustand des Sprachbefehls.
      ref.read(voiceCommandProvider.notifier).state =
          currentState.copyWith(isListening: true); // Updates the voice command state to indicate listening. // Aktualisiert den Zustand des Sprachbefehls, um das Hören anzuzeigen.
    } catch (e) { // Catches any errors. // Fängt alle Fehler ab.
      debugPrint('Recording start error: $e'); // Logs the error. // Protokolliert den Fehler.
    }
  }

  Future<void> _stopVoiceRecording() async { // Defines a method to stop voice recording. // Definiert eine Methode zum Stoppen der Sprachaufnahme.
    try { // Starts a try block for error handling. // Beginnt einen Try-Block für die Fehlerbehandlung.
      await ref.read(translationRepositoryProvider).playUISound('mic_off'); // Plays a sound to indicate microphone deactivation. // Spielt einen Sound ab, um die Mikrofondeaktivierung anzuzeigen.
      final path = await _recorder.stopListening(); // Stops the audio recorder and gets the recording path. // Stoppt den Audio-Recorder und erhält den Aufnahmepfad.
      if (path != null) { // Checks if a recording path was returned. // Prüft, ob ein Aufnahmepfad zurückgegeben wurde.
        var text = await ref
            .read(translationRepositoryProvider)
            .processAudioInput(path); // Processes the audio to convert it to text. // Verarbeitet das Audio, um es in Text umzuwandeln.

        // Filter out wake words from the recognized text
        text = text.replaceAll(RegExp(r'\b(?:jarvis|alexa)\b', caseSensitive: false), '').trim(); // Removes wake words from the text. // Entfernt Aktivierungswörter aus dem Text.

        // Only update text if there's actual content after filtering
        if (text.isNotEmpty) { // Checks if there is text after filtering. // Prüft, ob nach dem Filtern Text vorhanden ist.
          _textController.text = text; // Updates the text field with the recognized text. // Aktualisiert das Textfeld mit dem erkannten Text.
        }
      }
    } catch (e) { // Catches any errors. // Fängt alle Fehler ab.
      debugPrint('Recording stop error: $e'); // Logs the error. // Protokolliert den Fehler.
    } finally { // Executes regardless of success or failure. // Wird unabhängig von Erfolg oder Misserfolg ausgeführt.
      ref.read(isListeningProvider.notifier).state = false; // Updates the listening state to false. // Aktualisiert den Hörzustand auf falsch.
      final currentState = ref.read(voiceCommandProvider); // Gets the current voice command state. // Holt den aktuellen Zustand des Sprachbefehls.
      ref.read(voiceCommandProvider.notifier).state =
          currentState.copyWith(isListening: false); // Updates the voice command state to indicate not listening. // Aktualisiert den Zustand des Sprachbefehls, um das Nicht-Hören anzuzeigen.
    }
  }

  @override
  void dispose() { // Cleanup method called when the widget is removed from the tree. // Aufräummethode, die aufgerufen wird, wenn das Widget aus dem Baum entfernt wird.
    _porcupineManager.delete(); // Deletes the Porcupine manager to release resources. // Löscht den Porcupine-Manager, um Ressourcen freizugeben.
    _recorder.dispose(); // Disposes the audio recorder. // Entsorgt den Audio-Recorder.
    _textController.dispose(); // Disposes the text controller. // Entsorgt den Textcontroller.
    super.dispose(); // Calls the parent class dispose method. // Ruft die dispose-Methode der Elternklasse auf.
  }

  @override
  Widget build(BuildContext context) { // Builds the UI for this widget. // Erstellt die Benutzeroberfläche für dieses Widget.
    final voiceState = ref.watch(voiceCommandProvider); // Watches the voice command state for changes. // Beobachtet den Zustand des Sprachbefehls auf Änderungen.

    ref.listen<VoiceCommandState>(voiceCommandProvider, (_, state) { // Sets up a listener for voice command state changes. // Richtet einen Listener für Änderungen des Sprachbefehlszustands ein.
      if (!mounted) return; // Returns if the widget is no longer in the tree. // Kehrt zurück, wenn das Widget nicht mehr im Baum ist.
      _handleVoiceCommand(state); // Handles the voice command state change. // Behandelt die Änderung des Sprachbefehlszustands.
    });

    return Scaffold( // Returns a scaffold widget that implements the basic material design layout. // Gibt ein Scaffold-Widget zurück, das das grundlegende Material-Design-Layout implementiert.
      backgroundColor: const Color(0xFF000000), // Sets the background color to black. // Setzt die Hintergrundfarbe auf Schwarz.
      appBar: CupertinoNavigationBar( // Uses a Cupertino-style navigation bar. // Verwendet eine Navigationsleiste im Cupertino-Stil.
        backgroundColor: const Color(0xFF1C1C1E), // Sets the app bar background color. // Setzt die Hintergrundfarbe der App-Leiste.
        border: null, // Removes the border from the app bar. // Entfernt den Rand von der App-Leiste.
        middle: const Text('AI Chat Assistant', // Sets the title text. // Setzt den Titeltext.
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600)), // Styles the title text. // Stylt den Titeltext.
        trailing: CupertinoButton( // Adds a button to the right side of the app bar. // Fügt eine Schaltfläche auf der rechten Seite der App-Leiste hinzu.
          padding: EdgeInsets.zero, // Removes padding from the button. // Entfernt das Padding von der Schaltfläche.
          child: const Icon(CupertinoIcons.gear,
              color: CupertinoColors.systemGrey, size: 28), // Uses a gear icon for settings. // Verwendet ein Zahnrad-Symbol für Einstellungen.
          onPressed: () => Navigator.pushNamed(context, '/settings'), // Navigates to settings screen when pressed. // Navigiert zum Einstellungsbildschirm, wenn gedrückt.
        ),
      ),
      body: Padding( // Adds padding around the body content. // Fügt Polsterung um den Körperinhalt hinzu.
        padding: const EdgeInsets.all(16.0), // Sets 16 pixels of padding on all sides. // Setzt 16 Pixel Polsterung auf allen Seiten.
        child: Column( // Arranges children in a vertical column. // Ordnet Kinder in einer vertikalen Spalte an.
          children: [
            VoiceCommandStatusIndicator( // Displays the voice command status. // Zeigt den Status des Sprachbefehls an.
              isListening: voiceState.isListening, // Passes the listening state to the indicator. // Übergibt den Hörzustand an die Anzeige.
            ),
            Text( // Displays instructional text based on current mode. // Zeigt Anweisungstext basierend auf dem aktuellen Modus an.
              _isWakeWordMode 
                ? 'Say "Jarvis" to start listening' // Text when in wake word mode. // Text im Aktivierungswort-Modus.
                : 'Say "Alexa" to stop listening and start conversation', // Text when recording. // Text bei Aufnahme.
              style: const TextStyle(color: Colors.white, fontSize: 14), // Styles the text. // Stylt den Text.
            ),
            const SizedBox(height: 12), // Adds vertical spacing. // Fügt vertikalen Abstand hinzu.
            Expanded( // Expands to fill available space. // Erweitert sich, um den verfügbaren Platz zu füllen.
              child: Align( // Aligns its child within itself. // Richtet sein Kind innerhalb von sich selbst aus.
                alignment: Alignment.topLeft, // Aligns to the top left. // Richtet sich oben links aus.
                child: CupertinoTextField( // Creates an iOS-style text field. // Erstellt ein Textfeld im iOS-Stil.
                  controller: _textController, // Connects the text controller. // Verbindet den Textcontroller.
                  maxLines: null, // Allows unlimited lines of text. // Erlaubt unbegrenzte Textzeilen.
                  style: const TextStyle(color: Colors.white, fontSize: 17), // Styles the input text. // Stylt den Eingabetext.
                  placeholder: 'write your prompt here', // Sets placeholder text. // Legt Platzhaltertext fest.
                  placeholderStyle: const TextStyle(
                      color: CupertinoColors.placeholderText, fontSize: 17), // Styles the placeholder text. // Stylt den Platzhaltertext.
                  decoration: BoxDecoration( // Sets the decoration of the text field. // Legt die Dekoration des Textfeldes fest.
                    color: const Color(0xFF2C2C2E), // Sets the background color. // Setzt die Hintergrundfarbe.
                    borderRadius: BorderRadius.circular(12), // Rounds the corners. // Rundet die Ecken ab.
                    border: Border.all( // Adds a border. // Fügt einen Rand hinzu.
                      color: const Color(0xFF3A3A3C), // Sets the border color. // Setzt die Randfarbe.
                      width: 0.5, // Sets the border width. // Setzt die Randbreite.
                    ),
                  ),
                  padding: const EdgeInsets.all(16), // Adds internal padding. // Fügt interne Polsterung hinzu.
                ),
              ),
            ),
            const SizedBox(height: 20), // Adds vertical spacing. // Fügt vertikalen Abstand hinzu.
            Row( // Arranges children in a horizontal row. // Ordnet Kinder in einer horizontalen Reihe an.
              children: [
                Expanded( // Expands to fill available horizontal space. // Erweitert sich, um den verfügbaren horizontalen Platz zu füllen.
                  child: ElevatedButton( // Creates a Material Design elevated button. // Erstellt eine erhöhte Schaltfläche im Material-Design.
                    onPressed: _startConversation, // Sets the action when pressed. // Legt die Aktion beim Drücken fest.
                    style: ElevatedButton.styleFrom( // Styles the button. // Stylt die Schaltfläche.
                      backgroundColor: const Color.fromARGB(255, 61, 62, 63), // Sets the button color. // Setzt die Schaltflächenfarbe.
                      minimumSize: const Size(double.infinity, 50), // Sets the minimum button size. // Legt die Mindestgröße der Schaltfläche fest.
                    ),
                    child: const Text('start conversation',
                        style: TextStyle(color: Colors.white)), // Sets the button text and style. // Legt den Schaltflächentext und -stil fest.
                  ),
                ),
                const SizedBox(width: 16), // Adds horizontal spacing. // Fügt horizontalen Abstand hinzu.
                Consumer( // Creates a widget that consumes a provider. // Erstellt ein Widget, das einen Provider verbraucht.
                  builder: (context, ref, child) { // Builder function for the Consumer. // Builder-Funktion für den Consumer.
                    final voiceState = ref.watch(voiceCommandProvider); // Watches the voice command state. // Beobachtet den Zustand des Sprachbefehls.
                    return ElevatedButton( // Creates a microphone button. // Erstellt eine Mikrofonschaltfläche.
                      onPressed: () => _toggleRecording(voiceState.isListening), // Toggles recording when pressed. // Schaltet die Aufnahme um, wenn gedrückt.
                      style: ElevatedButton.styleFrom( // Styles the button. // Stylt die Schaltfläche.
                        backgroundColor:
                            voiceState.isListening ? Colors.red : Colors.white, // Changes color based on recording state. // Ändert die Farbe basierend auf dem Aufnahmezustand.
                        shape: const CircleBorder(), // Makes the button circular. // Macht die Schaltfläche kreisförmig.
                        padding: const EdgeInsets.all(16), // Adds padding. // Fügt Polsterung hinzu.
                      ),
                      child: const Icon(Icons.mic, size: 28, color: Colors.black,), // Uses a microphone icon. // Verwendet ein Mikrofonsymbol.
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRecording(bool isCurrentlyListening) async { // Method to toggle recording state. // Methode zum Umschalten des Aufnahmezustands.
    if (isCurrentlyListening) { // Checks if currently listening. // Prüft, ob derzeit gehört wird.
      await _stopVoiceRecording(); // Stops recording if already listening. // Stoppt die Aufnahme, wenn bereits gehört wird.
      _isWakeWordMode = true; // Sets back to wake word mode. // Setzt zurück in den Aktivierungswort-Modus.
    } else { // If not currently listening. // Wenn nicht derzeit gehört wird.
      await _startVoiceRecording(); // Starts recording. // Startet die Aufnahme.
      _isWakeWordMode = false; // Exits wake word mode. // Verlässt den Aktivierungswort-Modus.
    }
  }
}
