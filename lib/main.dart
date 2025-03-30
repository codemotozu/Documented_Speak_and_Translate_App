/// MyApp
/// 
/// The main application entry point for the AI Chat Assistant Flutter app. // Der Haupteinstiegspunkt für die KI-Chat-Assistent Flutter-App.
/// Sets up the application structure, theme, and navigation routes. // Richtet die Anwendungsstruktur, das Design und die Navigationsrouten ein.
/// 
/// Usage:
/// ```dart
/// void main() {
///   runApp(const ProviderScope(child: MyApp()));
/// }
/// ```
/// 
/// EN: Configures a Material app with Riverpod state management and defines the app's navigation routes.
/// DE: Konfiguriert eine Material-App mit Riverpod-Zustandsverwaltung und definiert die Navigationsrouten der App.

import 'package:flutter/material.dart'; // Imports Material Design widgets from Flutter. // Importiert Material Design-Widgets aus Flutter.
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Imports Riverpod for state management. // Importiert Riverpod für die Zustandsverwaltung.
import 'features/translation/presentation/screens/prompt_screen.dart'; // Imports the prompt screen where users enter their queries. // Importiert den Eingabebildschirm, auf dem Benutzer ihre Anfragen eingeben.
import 'features/translation/presentation/screens/settings_screen.dart'; // Imports the settings screen for app configuration. // Importiert den Einstellungsbildschirm für die App-Konfiguration.
import 'features/translation/presentation/screens/conversation_screen.dart'; // Imports the conversation screen that shows AI responses. // Importiert den Konversationsbildschirm, der KI-Antworten anzeigt.

void main() { // The entry point of the application. // Der Einstiegspunkt der Anwendung.
  WidgetsFlutterBinding.ensureInitialized(); // Initializes Flutter bindings before running the app. // Initialisiert Flutter-Bindungen vor dem Starten der App.
  runApp( // Runs the Flutter application. // Startet die Flutter-Anwendung.
    const ProviderScope( // Wraps the app with ProviderScope for Riverpod state management. // Umschließt die App mit ProviderScope für die Riverpod-Zustandsverwaltung.
      child: MyApp(), // Sets MyApp as the root widget of the application. // Setzt MyApp als Root-Widget der Anwendung.
    ),
  );
}
 
class MyApp extends ConsumerWidget { // Defines the main app class as a ConsumerWidget to access Riverpod providers. // Definiert die Haupt-App-Klasse als ConsumerWidget, um auf Riverpod-Provider zuzugreifen.
  const MyApp({super.key}); // Constructor that accepts a key parameter. // Konstruktor, der einen Key-Parameter akzeptiert.

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Builds the UI with access to the BuildContext and WidgetRef. // Erstellt die Benutzeroberfläche mit Zugriff auf BuildContext und WidgetRef.
    return MaterialApp( // Returns a MaterialApp which provides material design for the app. // Gibt eine MaterialApp zurück, die Material Design für die App bereitstellt.
      debugShowCheckedModeBanner: false, // Disables the debug banner in the top-right corner. // Deaktiviert das Debug-Banner in der oberen rechten Ecke.
      title: 'AI Chat Assistant ', // Sets the application title shown in the task switcher. // Legt den Anwendungstitel fest, der im Task-Switcher angezeigt wird.
      theme: ThemeData( // Configures the app's theme. // Konfiguriert das Design der App.
        primarySwatch: Colors.blue, // Sets the primary color palette to blue. // Setzt die primäre Farbpalette auf Blau.
        useMaterial3: true, // Enables Material Design 3 features. // Aktiviert Material Design 3-Funktionen.
      ),
      initialRoute: '/', // Sets the initial route to the root route. // Legt die Anfangsroute auf die Root-Route fest.
      routes: { // Defines named routes for navigation. // Definiert benannte Routen für die Navigation.
        '/': (context) => const PromptScreen(), // Maps the root route to the PromptScreen. // Ordnet die Root-Route dem PromptScreen zu.
        '/settings': (context) => const SettingsScreen(), // Maps the settings route to the SettingsScreen. // Ordnet die Einstellungsroute dem SettingsScreen zu.
      },
      onGenerateRoute: (settings) { // Custom route generator for routes with parameters. // Benutzerdefinierter Routengenerator für Routen mit Parametern.
        if (settings.name == '/conversation') { // Checks if the route is the conversation route. // Prüft, ob die Route die Konversationsroute ist.
          final prompt = settings.arguments as String; // Extracts the prompt argument as a String. // Extrahiert das Prompt-Argument als String.
          return MaterialPageRoute( // Creates a MaterialPageRoute for the conversation. // Erstellt eine MaterialPageRoute für die Konversation.
            builder: (context) => ConversationScreen(prompt: prompt), // Creates the ConversationScreen with the prompt parameter. // Erstellt den ConversationScreen mit dem Prompt-Parameter.
          );
        }
        return null; // Returns null for unknown routes, triggering the default error page. // Gibt null für unbekannte Routen zurück, was die Standard-Fehlerseite auslöst.
      },
    );
  }
}
