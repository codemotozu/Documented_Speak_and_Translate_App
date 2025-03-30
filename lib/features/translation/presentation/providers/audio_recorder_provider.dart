/// AudioRecorder
/// 
/// A utility class that manages microphone access and audio recording functionality. // Eine Hilfsklasse, die den Mikrofonzugriff und die Audioaufnahmefunktionalität verwaltet.
/// Handles requesting permissions, initializing the recorder, starting/stopping recordings, and managing recording state. // Verwaltet das Anfordern von Berechtigungen, die Initialisierung des Rekorders, das Starten/Stoppen von Aufnahmen und den Aufnahmezustand.
///
/// The class works with Riverpod to provide state management for the recording status: // Die Klasse arbeitet mit Riverpod, um die Zustandsverwaltung für den Aufnahmestatus bereitzustellen:
/// - Tracks whether recording is active via isListeningProvider // - Verfolgt, ob die Aufnahme über isListeningProvider aktiv ist
/// - Provides access to the recorder via audioRecorderProvider // - Bietet Zugriff auf den Rekorder über audioRecorderProvider
///
/// Usage:
/// ```dart
/// // Access the recorder in a widget // Zugriff auf den Rekorder in einem Widget
/// final recorder = ref.watch(audioRecorderProvider);
/// 
/// // Initialize the recorder // Initialisieren des Rekorders
/// await recorder.init();
/// 
/// // Start recording // Aufnahme starten
/// await recorder.start();
/// 
/// // Stop recording and get the file path // Aufnahme stoppen und Dateipfad erhalten
/// final audioPath = await recorder.stop();
/// 
/// // Check recording status // Aufnahmestatus prüfen
/// final isRecording = await recorder.isRecording();
/// 
/// // Release resources when done // Ressourcen freigeben, wenn fertig
/// await recorder.dispose();
/// ```
///
/// EN: Provides audio recording functionality with permission handling and state management using Riverpod.
/// DE: Bietet Audioaufnahmefunktionalität mit Berechtigungsverwaltung und Zustandsverwaltung unter Verwendung von Riverpod.

import 'package:flutter/material.dart'; // Imports core Flutter UI elements and utilities. // Importiert Flutter-UI-Kernelemente und Hilfsprogramme.
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Imports Riverpod for state management. // Importiert Riverpod für die Zustandsverwaltung.
import 'package:flutter_sound/flutter_sound.dart'; // Imports the audio recording and playback library. // Importiert die Audioaufnahme- und Wiedergabebibliothek.
import 'package:path_provider/path_provider.dart'; // Imports utilities for accessing device directories. // Importiert Hilfsprogramme für den Zugriff auf Geräteverzeichnisse.
import 'package:permission_handler/permission_handler.dart'; // Imports utilities for handling runtime permissions. // Importiert Hilfsprogramme zur Verwaltung von Laufzeitberechtigungen.

// Add state provider for listening state
final isListeningProvider = StateProvider<bool>((ref) => false); // Defines a Riverpod state provider to track recording status. // Definiert einen Riverpod-State-Provider, um den Aufnahmestatus zu verfolgen.

final audioRecorderProvider = Provider<AudioRecorder>((ref) => AudioRecorder(ref)); // Defines a Riverpod provider that creates and provides an AudioRecorder instance. // Definiert einen Riverpod-Provider, der eine AudioRecorder-Instanz erstellt und bereitstellt.

/// AudioRecorder
///
/// A class that handles audio recording functionality with proper permission management. // Eine Klasse, die Audioaufnahmefunktionen mit ordnungsgemäßer Berechtigungsverwaltung verarbeitet.
/// It encapsulates the FlutterSoundRecorder and provides a simplified API for recording. // Sie kapselt den FlutterSoundRecorder und bietet eine vereinfachte API für die Aufnahme.

class AudioRecorder { // Defines the audio recorder class. // Definiert die Audiorekorderklasse.
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder(); // Creates a FlutterSoundRecorder instance to handle the actual recording. // Erstellt eine FlutterSoundRecorder-Instanz zur Verwaltung der eigentlichen Aufnahme.
  bool _isInitialized = false; // Flag to track if the recorder has been initialized. // Flag, um zu verfolgen, ob der Rekorder initialisiert wurde.
  String? _path; // Stores the path to the recorded audio file. // Speichert den Pfad zur aufgenommenen Audiodatei.
  final Ref _ref; // Reference to the Riverpod container for state management. // Referenz auf den Riverpod-Container für die Zustandsverwaltung.

  AudioRecorder(this._ref); // Constructor that takes a Riverpod ref. // Konstruktor, der eine Riverpod-Referenz übernimmt.

  bool get isListening => _ref.read(isListeningProvider); // Getter to check if recording is active via the Riverpod provider. // Getter zum Überprüfen, ob die Aufnahme über den Riverpod-Provider aktiv ist.

  Future<void> init() async { // Method to initialize the recorder and request permissions. // Methode zur Initialisierung des Rekorders und Anforderung von Berechtigungen.
    if (!_isInitialized) { // Only initialize if not already initialized. // Nur initialisieren, wenn noch nicht initialisiert.
      final status = await Permission.microphone.request(); // Request microphone permission from the user. // Fordert Mikrofonberechtigung vom Benutzer an.
      if (status != PermissionStatus.granted) { // Check if permission was granted. // Prüft, ob die Berechtigung erteilt wurde.
        throw RecordingPermissionException('Microphone permission not granted'); // Throw an exception if permission was denied. // Wirft eine Ausnahme, wenn die Berechtigung verweigert wurde.
      }
      await _recorder.openRecorder(); // Initialize the recorder. // Initialisiert den Rekorder.
      _isInitialized = true; // Mark as initialized. // Als initialisiert markieren.
    }
  }

  Future<void> startListening(String command) async { // Method to start recording based on a voice command. // Methode zum Starten der Aufnahme basierend auf einem Sprachbefehl.
    if (!_isInitialized) await init(); // Initialize if not already done. // Initialisieren, wenn noch nicht geschehen.
    
    if (command.toLowerCase() == "open") { // Check if the command is "open". // Prüft, ob der Befehl "open" ist.
      try {
        final dir = await getTemporaryDirectory(); // Get the temporary directory for storing the recording. // Holt das temporäre Verzeichnis zum Speichern der Aufnahme.
        _path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac'; // Generate a unique filename with timestamp. // Generiert einen eindeutigen Dateinamen mit Zeitstempel.
        await _recorder.startRecorder( // Start the recorder. // Startet den Rekorder.
          toFile: _path, // Set the output file path. // Setzt den Ausgabedateipfad.
          codec: Codec.aacADTS, // Set the audio codec to AAC. // Setzt den Audiocodec auf AAC.
        );
        _ref.read(isListeningProvider.notifier).state = true; // Update the recording state to true. // Aktualisiert den Aufnahmezustand auf true.
      } catch (e) {
        debugPrint('Error starting recording: $e'); // Log any errors that occur during recording start. // Protokolliert alle Fehler, die beim Aufnahmestart auftreten.
      }
    }
  }

  Future<String?> stopListening() async { // Method to stop recording that was started with voice command. // Methode zum Stoppen der Aufnahme, die mit Sprachbefehl gestartet wurde.
    try {
      if (_recorder.isRecording) { // Check if the recorder is currently recording. // Prüft, ob der Rekorder gerade aufnimmt.
        await _recorder.stopRecorder(); // Stop the recorder. // Stoppt den Rekorder.
        _ref.read(isListeningProvider.notifier).state = false; // Update the recording state to false. // Aktualisiert den Aufnahmezustand auf false.
        return _path; // Return the path to the recorded audio file. // Gibt den Pfad zur aufgenommenen Audiodatei zurück.
      }
      return null; // Return null if not recording. // Gibt null zurück, wenn keine Aufnahme läuft.
    } catch (e) {
      debugPrint('Error stopping recording: $e'); // Log any errors that occur during recording stop. // Protokolliert alle Fehler, die beim Aufnahmestopp auftreten.
      return null; // Return null on error. // Gibt bei Fehler null zurück.
    }
  }

  Future<void> start() async { // Method to start recording without a voice command. // Methode zum Starten der Aufnahme ohne Sprachbefehl.
    if (!_isInitialized) await init(); // Initialize if not already done. // Initialisieren, wenn noch nicht geschehen.
    try {
      final dir = await getTemporaryDirectory(); // Get the temporary directory for storing the recording. // Holt das temporäre Verzeichnis zum Speichern der Aufnahme.
      _path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac'; // Generate a unique filename with timestamp. // Generiert einen eindeutigen Dateinamen mit Zeitstempel.
      await _recorder.startRecorder( // Start the recorder. // Startet den Rekorder.
        toFile: _path, // Set the output file path. // Setzt den Ausgabedateipfad.
        codec: Codec.aacADTS, // Set the audio codec to AAC. // Setzt den Audiocodec auf AAC.
      );
      _ref.read(isListeningProvider.notifier).state = true; // Update the recording state to true. // Aktualisiert den Aufnahmezustand auf true.
    } catch (e) {
      debugPrint('Error recording audio: $e'); // Log any errors that occur during recording. // Protokolliert alle Fehler, die während der Aufnahme auftreten.
    }
  }

  Future<String?> stop() async { // Method to stop recording. // Methode zum Stoppen der Aufnahme.
    try {
      if (_recorder.isRecording) { // Check if the recorder is currently recording. // Prüft, ob der Rekorder gerade aufnimmt.
        await _recorder.stopRecorder(); // Stop the recorder. // Stoppt den Rekorder.
        _ref.read(isListeningProvider.notifier).state = false; // Update the recording state to false. // Aktualisiert den Aufnahmezustand auf false.
        return _path; // Return the path to the recorded audio file. // Gibt den Pfad zur aufgenommenen Audiodatei zurück.
      }
      return null; // Return null if not recording. // Gibt null zurück, wenn keine Aufnahme läuft.
    } catch (e) {
      debugPrint('Error stopping recording: $e'); // Log any errors that occur during recording stop. // Protokolliert alle Fehler, die beim Aufnahmestopp auftreten.
      return null; // Return null on error. // Gibt bei Fehler null zurück.
    }
  }

  Future<bool> isRecording() async { // Method to check if recording is active. // Methode zum Überprüfen, ob die Aufnahme aktiv ist.
    return _recorder.isRecording; // Return the recording status from the recorder. // Gibt den Aufnahmestatus vom Rekorder zurück.
  }

  Future<void> dispose() async { // Method to clean up resources when the recorder is no longer needed. // Methode zum Bereinigen von Ressourcen, wenn der Rekorder nicht mehr benötigt wird.
    if (_isInitialized) { // Only clean up if initialized. // Nur bereinigen, wenn initialisiert.
      await _recorder.closeRecorder(); // Close the recorder and release resources. // Schließt den Rekorder und gibt Ressourcen frei.
      _isInitialized = false; // Mark as not initialized. // Als nicht initialisiert markieren.
    }
  }
}
