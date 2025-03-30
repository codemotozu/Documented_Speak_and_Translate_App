/// VoiceCommandStatusIndicator
/// 
/// A visual indicator widget that shows when voice listening is active. // Ein visuelles Indikator-Widget, das anzeigt, wenn Spracherkennung aktiv ist.
/// The indicator animates into view when listening starts and fades out when it stops. // Der Indikator wird eingeblendet, wenn das Zuhören beginnt, und ausgeblendet, wenn es stoppt.
/// 
/// Usage:
/// ```dart
/// VoiceCommandStatusIndicator(
///   isListening: _isListeningState,
/// )
/// ```
/// 
/// EN: Displays an animated container with a microphone icon and text to indicate voice listening status.
/// DE: Zeigt einen animierten Container mit einem Mikrofon-Symbol und Text an, um den Status des Sprachzuhörens anzuzeigen.

import 'package:flutter/material.dart'; // Imports Material Design widgets from Flutter. // Importiert Material Design-Widgets aus Flutter.

const _statusKey = Key('voiceStatusIndicator'); // Defines a constant key for widget identification in testing. // Definiert einen konstanten Schlüssel zur Widget-Identifikation beim Testen.

class VoiceCommandStatusIndicator extends StatelessWidget { // Defines a stateless widget for voice status indication. // Definiert ein zustandsloses Widget für die Anzeige des Sprachstatus.
  final bool isListening; // Declares a final boolean property to track listening state. // Deklariert eine finale boolesche Eigenschaft, um den Hörstatus zu verfolgen.

  const VoiceCommandStatusIndicator({ // Constructor for the widget. // Konstruktor für das Widget.
    super.key, // Passes the key to the parent class. // Übergibt den Schlüssel an die Elternklasse.
    required this.isListening, // Requires the listening state to be provided. // Erfordert, dass der Hörstatus bereitgestellt wird.
  });

  @override
  Widget build(BuildContext context) { // Builds the UI for this widget. // Erstellt die Benutzeroberfläche für dieses Widget.
    return AnimatedContainer( // Returns an animated container that smoothly changes properties. // Gibt einen animierten Container zurück, der Eigenschaften sanft ändert.
      key: _statusKey, // Sets the key for widget identification. // Setzt den Schlüssel für die Widget-Identifikation.
      duration: const Duration(milliseconds: 300), // Sets animation duration to 300 milliseconds. // Setzt die Animationsdauer auf 300 Millisekunden.
      curve: Curves.easeInOut, // Sets the animation curve for smooth transitions. // Setzt die Animationskurve für sanfte Übergänge.
      height: isListening ? 40 : 0, // Adjusts height based on listening state - 40px if listening, 0 if not. // Passt die Höhe basierend auf dem Hörstatus an - 40px wenn aktiv, 0 wenn nicht.
      padding: const EdgeInsets.symmetric(horizontal: 16), // Sets horizontal padding to 16 pixels. // Setzt horizontales Padding auf 16 Pixel.
      decoration: BoxDecoration( // Configures the visual appearance of the container. // Konfiguriert das visuelle Erscheinungsbild des Containers.
        color: Colors.black.withOpacity(0.7), // Sets a semi-transparent black background. // Setzt einen halbtransparenten schwarzen Hintergrund.
        borderRadius: BorderRadius.circular(20), // Rounds the corners with a 20 pixel radius. // Rundet die Ecken mit einem Radius von 20 Pixeln.
      ),
      child: AnimatedOpacity( // Creates an animated opacity effect for child widgets. // Erstellt einen animierten Transparenzeffekt für untergeordnete Widgets.
        opacity: isListening ? 1 : 0, // Sets opacity based on listening state - visible if listening, invisible if not. // Setzt die Transparenz basierend auf dem Hörstatus - sichtbar wenn aktiv, unsichtbar wenn nicht.
        duration: const Duration(milliseconds: 200), // Sets opacity animation duration to 200 milliseconds. // Setzt die Dauer der Transparenzanimation auf 200 Millisekunden.
        child: Row( // Arranges children in a horizontal row. // Ordnet Kinder in einer horizontalen Reihe an.
          mainAxisSize: MainAxisSize.min, // Makes the row take minimum required space. // Lässt die Reihe minimalen erforderlichen Platz einnehmen.
          children: [
            const Icon(Icons.mic, color: Colors.red, size: 20), // Adds a red microphone icon. // Fügt ein rotes Mikrofon-Symbol hinzu.
            const SizedBox(width: 8), // Adds 8 pixels of spacing. // Fügt 8 Pixel Abstand hinzu.
            Text( // Creates a text widget. // Erstellt ein Text-Widget.
              'Escuchando...', // The text content in Spanish, meaning "Listening...". // Der Textinhalt auf Spanisch, bedeutet "Hören...".
              style: Theme.of(context).textTheme.bodySmall?.copyWith( // Styles the text using the theme's body small style with modifications. // Stylt den Text mit dem kleinen Textkörperstil des Themes mit Änderungen.
                    color: Colors.white, // Sets text color to white. // Setzt die Textfarbe auf Weiß.
                    fontWeight: FontWeight.w500, // Sets font weight to medium. // Setzt die Schriftstärke auf mittel.
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
