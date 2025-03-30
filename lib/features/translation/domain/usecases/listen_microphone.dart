/// ListenMicrophone
/// 
/// A use case class that processes audio recorded from the microphone for speech-to-text conversion. // Eine Anwendungsfallklasse, die von einem Mikrofon aufgenommenes Audio für die Sprache-zu-Text-Umwandlung verarbeitet.
/// Part of the clean architecture pattern, acting as an intermediary between UI and repository layers. // Teil des Clean-Architecture-Musters, fungiert als Vermittler zwischen UI- und Repository-Schichten.
///
/// This class follows the single responsibility principle by focusing solely on audio processing. // Diese Klasse folgt dem Prinzip der einzigen Verantwortung, indem sie sich ausschließlich auf die Audioverarbeitung konzentriert.
/// It delegates the actual implementation to the repository layer. // Sie delegiert die eigentliche Implementierung an die Repository-Schicht.
///
/// Usage:
/// ```dart
/// // Create the use case with a repository instance // Erstellen des Anwendungsfalls mit einer Repository-Instanz
/// final listenMicrophone = ListenMicrophone(translationRepository);
///
/// // Execute the use case with an audio file path // Ausführen des Anwendungsfalls mit einem Audiodateipfad
/// final recognizedText = await listenMicrophone.execute('/path/to/recording.wav');
/// 
/// // Use the recognized text in the UI // Verwendung des erkannten Textes in der Benutzeroberfläche
/// setState(() {
///   userInput = recognizedText;
/// });
/// ```
///
/// EN: Implements the use case for converting microphone audio recordings to text using speech recognition.
/// DE: Implementiert den Anwendungsfall zur Umwandlung von Mikrofonaufnahmen in Text mittels Spracherkennung.

import '../repositories/translation_repository.dart'; // Imports the repository interface that this use case depends on. // Importiert die Repository-Schnittstelle, von der dieser Anwendungsfall abhängt.


class ListenMicrophone { // Defines a use case class for processing microphone audio. // Definiert eine Anwendungsfallklasse zur Verarbeitung von Mikrofonaudio.
  final TranslationRepository repository; // Stores a reference to the repository that will handle the actual processing. // Speichert eine Referenz auf das Repository, das die eigentliche Verarbeitung durchführt.

  ListenMicrophone(this.repository); // Constructor that takes a repository instance. // Konstruktor, der eine Repository-Instanz übernimmt.

  Future<String> execute(String audioPath) async { // Method that executes the use case with a given audio file path. // Methode, die den Anwendungsfall mit einem gegebenen Audiodateipfad ausführt.
    // Implementation for processing audio file // Implementierung zur Verarbeitung der Audiodatei
    return repository.processAudioInput(audioPath); // Delegates the processing to the repository layer and returns the result. // Delegiert die Verarbeitung an die Repository-Schicht und gibt das Ergebnis zurück.
  }
}
