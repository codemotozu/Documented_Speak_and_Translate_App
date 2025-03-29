import 'package:audio_session/audio_session.dart'; // Imports package for managing audio sessions. // Importiert ein Paket zur Verwaltung von Audiositzungen.
import 'package:http/http.dart' as http; // Imports HTTP client for API requests. // Importiert HTTP-Client für API-Anfragen.
import 'package:http/io_client.dart'; // Imports IO client for customized HTTP connections. // Importiert IO-Client für angepasste HTTP-Verbindungen.
import 'dart:convert'; // Imports utilities for encoding and decoding JSON. // Importiert Hilfsprogramme zum Kodieren und Dekodieren von JSON.
import 'dart:io'; // Imports file system access and networking capabilities. // Importiert Dateisystemzugriff und Netzwerkfunktionen.
import 'package:path/path.dart' as path; // Imports utilities for file path manipulation. // Importiert Hilfsprogramme zur Manipulation von Dateipfaden.
import '../../domain/entities/translation.dart'; // Imports the Translation entity model. // Importiert das Translation-Entitätsmodell.
import '../../domain/repositories/translation_repository.dart'; // Imports the repository interface that this class implements. // Importiert die Repository-Schnittstelle, die diese Klasse implementiert.
import 'package:just_audio/just_audio.dart'; // Imports audio playback capabilities. // Importiert Audiowiedergabefunktionen.
import 'package:http_parser/http_parser.dart'; // Imports HTTP content-type parsing utilities. // Importiert HTTP-Content-Type-Parsing-Hilfsprogramme.


class AudioMetadata { // Defines a class for storing audio file metadata. // Definiert eine Klasse zur Speicherung von Audiodatei-Metadaten.
  final String album; // The album name for the audio. // Der Albumname für das Audio.
  final String title; // The title of the audio. // Der Titel des Audios.
  final Uri artwork; // The URI for the album artwork image. // Die URI für das Albumcover-Bild.

  const AudioMetadata({ // Constructor for creating immutable AudioMetadata instances. // Konstruktor zum Erstellen unveränderlicher AudioMetadata-Instanzen.
    required this.album, // Required album name parameter. // Erforderlicher Albumname-Parameter.
    required this.title, // Required title parameter. // Erforderlicher Titel-Parameter.
    required this.artwork, // Required artwork URI parameter. // Erforderlicher Artwork-URI-Parameter.
  });
}

class TranslationRepositoryImpl implements TranslationRepository { // Implementation of the TranslationRepository interface. // Implementierung der TranslationRepository-Schnittstelle.
  // final String baseUrl = 'http://10.0.2.2:8000'; // here you can hear the translaion in my local machine dont forget to update main.py // Kommentierter Code für lokale Entwicklung.
  final String baseUrl = 'https://docker-and-azure.redpebble-xxxxxxxxxx.xxxxxx.azurecontainerapps.io'; // Production API endpoint URL. // Produktions-API-Endpunkt-URL.
  static const timeoutDuration = Duration(seconds: 240); // Timeout duration for API requests (4 minutes). // Timeout-Dauer für API-Anfragen (4 Minuten).
  final AudioPlayer _audioPlayer = AudioPlayer(); // Player for translated audio content. // Player für übersetzte Audioinhalte.
  final AudioPlayer _soundPlayer = AudioPlayer(); // Player for notification sounds. // Player für Benachrichtigungstöne.
  final HttpClient _httpClient = HttpClient() // Custom HTTP client that accepts all SSL certificates. // Benutzerdefinierter HTTP-Client, der alle SSL-Zertifikate akzeptiert.
    ..badCertificateCallback = (cert, host, port) => true; // Accepts all SSL certificates (not secure for production). // Akzeptiert alle SSL-Zertifikate (nicht sicher für die Produktion).
  late final http.Client _client; // HTTP client initialized in constructor. // HTTP-Client, der im Konstruktor initialisiert wird.
  final AudioPlayer _uiSoundPlayer = AudioPlayer(); // Player for UI interaction sounds. // Player für UI-Interaktionsgeräusche.

  TranslationRepositoryImpl() { // Constructor for the repository implementation. // Konstruktor für die Repository-Implementierung.
    _client = IOClient(_httpClient); // Initialize HTTP client with custom settings. // Initialisiert HTTP-Client mit benutzerdefinierten Einstellungen.
  }

  String _getAudioUrl(String audioPath) { // Helper method to construct the full URL for audio files. // Hilfsmethode zum Erstellen der vollständigen URL für Audiodateien.
    final filename = path.basename(audioPath); // Extracts the filename from the path. // Extrahiert den Dateinamen aus dem Pfad.
    final encodedFilename = Uri.encodeComponent(filename); // URL encodes the filename for safe use in URLs. // URL-codiert den Dateinamen zur sicheren Verwendung in URLs.
    return '$baseUrl/api/audio/$encodedFilename'; // Returns the complete API URL for the audio file. // Gibt die vollständige API-URL für die Audiodatei zurück.
  }


 @override
  Future<void> playUISound(String soundType) async { // Method to play UI interaction sounds. // Methode zum Abspielen von UI-Interaktionsgeräuschen.
    try {
      String soundPath; // Variable to hold the path to the sound file. // Variable zum Speichern des Pfads zur Sounddatei.
      switch (soundType) { // Switch statement to select the correct sound file based on the interaction type. // Switch-Anweisung zur Auswahl der richtigen Sounddatei basierend auf dem Interaktionstyp.
        case 'mic_on': // Case for microphone activation sound. // Fall für Mikrofonaktivierungston.
          soundPath = 'assets/sounds/open.wav'; // Path to the microphone on sound. // Pfad zum Mikrofon-Ein-Ton.
          break;
        case 'mic_off': // Case for microphone deactivation sound. // Fall für Mikrofondeaktivierungston.
          soundPath = 'assets/sounds/close.wav'; // Path to the microphone off sound. // Pfad zum Mikrofon-Aus-Ton.
          break;
        case 'start_conversation': // Case for starting a new conversation sound. // Fall für den Ton zum Starten eines neuen Gesprächs.
          soundPath = 'assets/sounds/send.wav'; // Path to the send message sound. // Pfad zum Senden-Nachricht-Ton.
          break;
        default: // Default case if an unknown sound type is requested. // Standardfall, wenn ein unbekannter Soundtyp angefordert wird.
          return; // Exit the method if sound type is not recognized. // Beendet die Methode, wenn der Soundtyp nicht erkannt wird.
      }
      
      await _uiSoundPlayer.setAsset(soundPath); // Set the audio source to the selected sound file. // Setzt die Audioquelle auf die ausgewählte Sounddatei.
      await _uiSoundPlayer.play(); // Play the sound. // Spielt den Ton ab.
    } catch (e) { // Error handling for sound playback issues. // Fehlerbehandlung für Tonwiedergabeprobleme.
      print('Error playing UI sound: $e'); // Log the error message. // Protokolliert die Fehlermeldung.
    }
  }


@override
Future<void> playAudio(String audioPath) async { // Method to play translated audio content. // Methode zum Abspielen übersetzter Audioinhalte.
  try {
    final audioUrl = _getAudioUrl(audioPath); // Get the full URL for the audio file. // Holt die vollständige URL für die Audiodatei.
    print('Playing audio from URL: $audioUrl'); // Log the audio URL for debugging. // Protokolliert die Audio-URL zur Fehlersuche.



    // Configure Android audio attributes // Konfiguriert Android-Audioattribute
    await _audioPlayer.setAndroidAudioAttributes(
      const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech, // Sets content type to speech for better audio routing. // Setzt den Inhaltstyp auf Sprache für besseres Audio-Routing.
        usage: AndroidAudioUsage.assistant, // Sets usage to assistant, similar to voice assistants. // Setzt die Verwendung auf Assistent, ähnlich wie Sprachassistenten.
      ),
    );

    // Set audio source with headers // Setzt die Audioquelle mit Headern
    await _audioPlayer.setAudioSource(
      AudioSource.uri(
        Uri.parse(audioUrl), // Parse the URL into a URI. // Parst die URL in eine URI.
        headers: {"Content-Type": "audio/mpeg"}, // Set the expected content type header. // Setzt den erwarteten Content-Type-Header.
      ),
      preload: true, // Preload the audio for faster playback. // Lädt das Audio für schnellere Wiedergabe vor.
      initialPosition: Duration.zero, // Start from the beginning of the audio. // Startet vom Anfang des Audios.
    );

    _audioPlayer.playbackEventStream.listen( // Listen to playback events for monitoring. // Hört auf Wiedergabeereignisse zur Überwachung.
      (event) {}, // Empty event handler since we're just interested in errors. // Leerer Event-Handler, da wir nur an Fehlern interessiert sind.
      onError: (e, st) => print('Player error: $e'), // Log any playback errors. // Protokolliert alle Wiedergabefehler.
    );

    await _audioPlayer.play(); // Start playing the audio. // Startet die Audiowiedergabe.
    await _audioPlayer.playerStateStream.firstWhere((state) => // Wait for playback to complete. // Wartet auf den Abschluss der Wiedergabe.
        state.processingState == ProcessingState.completed || // Check if playback completed normally. // Prüft, ob die Wiedergabe normal abgeschlossen wurde.
        state.processingState == ProcessingState.idle); // Or if the player returned to idle state. // Oder ob der Player in den Leerlaufzustand zurückgekehrt ist.
  } catch (e) { // Error handling for audio playback issues. // Fehlerbehandlung für Audiowiedergabeprobleme.
    print('Error: $e'); // Log the error message. // Protokolliert die Fehlermeldung.
    await _audioPlayer.stop(); // Stop playback in case of error. // Stoppt die Wiedergabe im Fehlerfall.
    rethrow; // Rethrow the error for higher-level handling. // Wirft den Fehler zur höheren Behandlung weiter.
  } finally { // Ensure resources are cleaned up regardless of outcome. // Stellt sicher, dass Ressourcen unabhängig vom Ergebnis bereinigt werden.
    await _audioPlayer.stop(); // Stop the audio player. // Stoppt den Audio-Player.
  }
}


  @override
  Future<void> playCompletionSound() async { // Method to play a sound when a process completes. // Methode zum Abspielen eines Tons, wenn ein Prozess abgeschlossen ist.
    try {
      await _soundPlayer.setAsset('assets/sounds/Blink.wav'); // Set the audio source to the completion sound file. // Setzt die Audioquelle auf die Abschlusston-Datei.
      await _soundPlayer.play(); // Play the completion sound. // Spielt den Abschlusston ab.
    } catch (e) { // Error handling for sound playback issues. // Fehlerbehandlung für Tonwiedergabeprobleme.
      print('Error playing completion sound: $e'); // Log the error message. // Protokolliert die Fehlermeldung.
    }
  }

  @override
  Future<Translation> getTranslation(String text) async { // Method to get a translation from the API. // Methode zum Abrufen einer Übersetzung von der API.
    try {
      final response = await _client.post( // Send a POST request to the translation API. // Sendet eine POST-Anfrage an die Übersetzungs-API.
        Uri.parse('$baseUrl/api/conversation'), // Parse the URL into a URI. // Parst die URL in eine URI.
        headers: { // Set request headers. // Setzt Anfrage-Header.
          'Content-Type': 'application/json; charset=UTF-8', // JSON content type with UTF-8 encoding. // JSON-Inhaltstyp mit UTF-8-Kodierung.
          'Accept': 'application/json; charset=UTF-8', // Accept JSON responses with UTF-8 encoding. // Akzeptiert JSON-Antworten mit UTF-8-Kodierung.
        },
        body: utf8.encode(json.encode({ // Encode the request body as UTF-8 JSON. // Kodiert den Anfragekörper als UTF-8-JSON.
          'text': text, // The text to translate. // Der zu übersetzende Text.
          'source_lang': 'en', // Source language (English). // Ausgangssprache (Englisch).
          'target_lang': 'de', // Target language (German). // Zielsprache (Deutsch).
        })),
      ).timeout(timeoutDuration); // Set request timeout duration. // Setzt die Anfrage-Timeout-Dauer.

      if (response.statusCode == 200) { // Check if the request was successful. // Prüft, ob die Anfrage erfolgreich war.
        final String decodedBody = utf8.decode(response.bodyBytes); // Decode response bytes as UTF-8. // Dekodiert Antwortbytes als UTF-8.
        final Map<String, dynamic> data = json.decode(decodedBody); // Parse JSON string into a map. // Parst JSON-String in eine Map.
        final translation = Translation.fromJson(data); // Create a Translation object from the JSON data. // Erstellt ein Translation-Objekt aus den JSON-Daten.
        
        if (translation.audioPath != null) { // Check if audio is available for the translation. // Prüft, ob Audio für die Übersetzung verfügbar ist.
          final audioUrl = _getAudioUrl(translation.audioPath!); // Get the full URL for the audio file. // Holt die vollständige URL für die Audiodatei.
          print('Audio URL: $audioUrl'); // Log the audio URL for debugging. // Protokolliert die Audio-URL zur Fehlersuche.
        }
        
        return translation; // Return the translation object. // Gibt das Übersetzungsobjekt zurück.
      } 

      else { // Handle non-200 response status codes. // Behandelt Nicht-200-Antwortstatuscodes.
        throw Exception('Server error: ${response.statusCode}\n${utf8.decode(response.bodyBytes)}'); // Throw an exception with the error details. // Wirft eine Ausnahme mit den Fehlerdetails.
      }
    } catch (e) { // Error handling for network or server issues. // Fehlerbehandlung für Netzwerk- oder Serverprobleme.
      print('Error in getTranslation: $e'); // Log the error message. // Protokolliert die Fehlermeldung.
      if (e.toString().contains('Connection refused')) { // Check for connection refused errors. // Prüft auf Verbindungsverweigerungsfehler.
        throw Exception('Cannot connect to server. Please make sure the server is running at $baseUrl'); // Throw a user-friendly error message. // Wirft eine benutzerfreundliche Fehlermeldung.
      }
      rethrow; // Rethrow other errors for higher-level handling. // Wirft andere Fehler zur höheren Behandlung weiter.
    }
  }

  @override
  Future<void> stopAudio() async { // Method to stop audio playback. // Methode zum Stoppen der Audiowiedergabe.
    await _audioPlayer.stop(); // Stop the audio player immediately. // Stoppt den Audio-Player sofort.
  }

  @override
  void dispose() { // Method to clean up resources when the repository is no longer needed. // Methode zum Bereinigen von Ressourcen, wenn das Repository nicht mehr benötigt wird.
    _client.close(); // Close the HTTP client connection. // Schließt die HTTP-Client-Verbindung.
    _audioPlayer.dispose(); // Release audio player resources. // Gibt Audio-Player-Ressourcen frei.
    _soundPlayer.dispose(); // Release sound player resources. // Gibt Sound-Player-Ressourcen frei.
     _uiSoundPlayer.dispose(); // Release UI sound player resources. // Gibt UI-Sound-Player-Ressourcen frei.
  }


@override
Future<String> processAudioInput(String audioPath) async { // Method to convert audio to text (speech recognition). // Methode zur Umwandlung von Audio in Text (Spracherkennung).
  try {
    final file = File(audioPath); // Create a File object from the audio path. // Erstellt ein File-Objekt aus dem Audiopfad.
    final mimeType = _getMimeType(audioPath); // Determine the MIME type from the file extension. // Bestimmt den MIME-Typ aus der Dateierweiterung.
    
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/speech-to-text')) // Create a multipart request for file upload. // Erstellt eine Multipart-Anfrage für den Datei-Upload.
      ..files.add(await http.MultipartFile.fromPath( // Add the audio file to the request. // Fügt die Audiodatei zur Anfrage hinzu.
        'file', // Field name for the file. // Feldname für die Datei.
        audioPath, // Path to the audio file. // Pfad zur Audiodatei.
        contentType: MediaType.parse(mimeType), // Set the correct content type for the file. // Setzt den korrekten Inhaltstyp für die Datei.
      ));

    final response = await request.send().timeout(timeoutDuration); // Send the request with timeout. // Sendet die Anfrage mit Timeout.
    
    if (response.statusCode == 200) { // Check if the request was successful. // Prüft, ob die Anfrage erfolgreich war.
      return json.decode(await response.stream.bytesToString())['text']; // Extract and return the recognized text. // Extrahiert und gibt den erkannten Text zurück.
    } else { // Handle non-200 response status codes. // Behandelt Nicht-200-Antwortstatuscodes.
      final errorBody = await response.stream.bytesToString(); // Get the error response body. // Holt den Fehlerantworttext.
      throw Exception('ASR Error ${response.statusCode}: $errorBody'); // Throw an exception with the error details. // Wirft eine Ausnahme mit den Fehlerdetails.
    }
  } catch (e) { // Error handling for audio processing issues. // Fehlerbehandlung für Audioverarbeitungsprobleme.
    print('Audio processing error: $e'); // Log the error message. // Protokolliert die Fehlermeldung.
    rethrow; // Rethrow the error for higher-level handling. // Wirft den Fehler zur höheren Behandlung weiter.
  }
}


  String _getMimeType(String filePath) { // Helper method to determine the MIME type from a file path. // Hilfsmethode zur Bestimmung des MIME-Typs aus einem Dateipfad.
  final ext = path.extension(filePath).toLowerCase(); // Get the lowercase file extension. // Holt die Dateiendung in Kleinbuchstaben.
  switch (ext) { // Switch statement based on file extension. // Switch-Anweisung basierend auf der Dateiendung.
    case '.wav': // WAV audio file case. // WAV-Audiodatei-Fall.
      return 'audio/wav; codecs=1'; // MIME type for WAV files with PCM codec. // MIME-Typ für WAV-Dateien mit PCM-Codec.
    case '.mp3': // MP3 audio file case. // MP3-Audiodatei-Fall.
      return 'audio/mpeg; codecs=mp3'; // MIME type for MP3 files. // MIME-Typ für MP3-Dateien.
    case '.aac': // AAC audio file case. // AAC-Audiodatei-Fall.
      return 'audio/aac; codecs=mp4a.40.2'; // MIME type for AAC files. // MIME-Typ für AAC-Dateien.
    case '.ogg': // OGG audio file case. // OGG-Audiodatei-Fall.
      return 'audio/ogg; codecs=vorbis'; // MIME type for OGG files with Vorbis codec. // MIME-Typ für OGG-Dateien mit Vorbis-Codec.
    default: // Default case for unsupported file types. // Standardfall für nicht unterstützte Dateitypen.
      throw FormatException('Unsupported audio format: $ext'); // Throw an exception for unsupported formats. // Wirft eine Ausnahme für nicht unterstützte Formate.
  }
}
}
