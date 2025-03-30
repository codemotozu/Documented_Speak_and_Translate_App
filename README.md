# Speak and Translate - AI-Powered Translation App

<div align="center">
  A multilingual voice translation assistant with natural speech synthesis
</div>

## 🌍 Languages | Sprachen

- [English](#english)
- [Deutsch](#deutsch)

---

<a id="english"></a>

# 🗣️ Speak and Translate - AI Translation Assistant [English]

A cross-platform application built with Flutter and Azure AI services that provides real-time speech translation, voice commands, and natural speech synthesis. The app supports conversations between multiple languages with rich educational features for language learners.

## 📋 Features

- **🎙️ Voice Commands**: Activate microphone with "Jarvis" and stop recording with "Alexa"
- **🔊 Speech Recognition**: Convert spoken language to text with high accuracy
- **🌐 Real-time Translation**: Translate between languages with AI-powered accuracy
- **🗣️ Natural Speech Synthesis**: Hear translations in natural-sounding voices
- **🧠 Educational Translations**: View word-by-word translations for language learning
- **🎭 Multiple Translation Styles**: Access native, colloquial, informal, and formal translations
- **💬 Chat Interface**: Track conversation history with visual speech bubbles
- **🎛️ Hands-Free Mode**: Automatically play translations for continuous conversation
- **🔄 Bilingual Audio Playback**: Hear source and translated words sequentially
- **📱 Cross-Platform**: Works on Android, iOS, and web platforms

### Translation Capabilities In Detail

The application provides advanced translation options with four different formality levels:

1. **Native**: Professional translation as a native speaker would express it
2. **Colloquial**: Casual, everyday language with idioms and expressions
3. **Informal**: Relaxed language for casual situations
4. **Formal**: Professional language for business or formal contexts

Each translation includes word-by-word explanations to help users understand the structure and vocabulary of different languages, making this application particularly valuable for language learners.

## 🔧 Technical Implementation

### Architecture Overview

The application consists of two main components:

1. **Flutter Mobile Client**:
   - UI for user interaction and chat interface
   - Handles audio recording and playback
   - Manages conversation history

2. **Python Backend Server**:
   - FastAPI REST service for translation and speech processing
   - Integrates with Google's Gemini AI for advanced translation
   - Uses Azure Cognitive Services for speech synthesis and recognition
   - Containerized with Docker for easy deployment

### Technologies Used

#### Mobile App
- Flutter with Dart
- Riverpod for state management
- Audio recording and playback libraries
- Material Design UI components

#### Backend Server
- Python 3.9
- FastAPI web framework
- Azure Cognitive Services Speech SDK
- Google's Gemini 2.0 AI model
- Docker for containerization
- Pydub for audio processing

#### DevOps
- GitHub Actions for CI/CD
- Azure Container Apps for hosting
- Docker Hub for container registry

### Code Organization

The codebase is structured following clean architecture principles:

```
├── .github/workflows/      # CI/CD configuration for Azure deployment
├── lib/                    # Flutter application source code
│   ├── features/           # Feature modules (translation, voice, etc.)
│   │   └── translation/    # Translation feature
│   │       ├── data/       # Data layer with models and repositories
│   │       ├── domain/     # Domain layer with entities and use cases
│   │       └── presentation/ # UI layer with screens and providers
│   └── main.dart           # Flutter application entry point
└── server/                 # Backend server
    ├── app/                # Server application code
    │   ├── application/    # Application services
    │   ├── domain/         # Domain entities
    │   └── infrastructure/ # API routes and external interfaces
    ├── Dockerfile          # Docker configuration for server
    └── requirements.txt    # Python dependencies
```

## 🚀 Getting Started

### Prerequisites

Before getting started, you'll need to:

1. Install Flutter SDK (latest version)
2. Install Docker (for backend)
3. Obtain the following API credentials:
   - **Azure Speech Services**: Create an account at [Azure Portal](https://portal.azure.com), create a Speech service resource, and get your API key and region
   - **Google Gemini API**: Sign up at [Google AI Studio](https://makersuite.google.com/app/apikey) to get your Gemini API key
   - **Picovoice API**: Create an account at [Picovoice Console](https://console.picovoice.ai/) to get your API key for wake word detection

### Creating Your Project From Scratch

1. Create a new directory for your project:
```bash
# For Windows
mkdir speak_and_translate_app
cd speak_and_translate_app

# For macOS/Linux
mkdir speak_and_translate_app
cd speak_and_translate_app
```

2. Create a new Flutter project:
```bash
flutter create speak_and_translate
cd speak_and_translate
```

3. Replace the default Flutter project structure with the repository structure:
   - Replace the contents of the `lib` folder with the repository's `lib` folder
   - Create a `server` folder and add the backend files

### Server Setup

1. Create a `server` directory in your project root and navigate to it:
```bash
mkdir server
cd server
```

2. Copy the server files from the repository or create the necessary files manually following the repository structure.

3. Set up environment variables:
   Create a `.env` file in the server directory with your own API credentials:
```
AZURE_SPEECH_KEY=your_azure_speech_key
AZURE_SPEECH_REGION=your_azure_region
GEMINI_API_KEY=your_gemini_api_key
PICOVOICE_API_KEY=your_picovoice_api_key
TTS_DEVICE=cpu
```

4. Run with Docker:
```bash
docker-compose up -d
```

5. Or run locally with Python:
```bash
pip install -r requirements.txt
python -m app.main
```

### Mobile App Setup

1. Navigate back to the mobile app directory:
```bash
cd ..
```

2. Update the `pubspec.yaml` file with the required dependencies:
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1
  http: ^1.2.2
  json_annotation: ^4.9.0
  path_provider: ^2.1.5
  record: ^5.2.0
  permission_handler: ^11.3.1
  record_platform_interface: ^1.2.0
  flutter_sound: ^9.19.1
  just_audio: ^0.9.43
  flutter_markdown: ^0.7.5
  flutter_tts: ^4.2.1
  picovoice_flutter: ^3.0.4
  speech_to_text: ^7.0.0
```

3. Install dependencies:
```bash
flutter pub get
```

4. Configure API endpoint:
   In `lib/features/translation/data/repositories/translation_repository_impl.dart`, update the `baseUrl` to point to your server:
```dart
// Change this line to point to your server
final String baseUrl = 'http://localhost:8000'; 
```

5. Set up permissions:
   - For Android: Add microphone permissions to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.INTERNET"/>
   ```
   
   - For iOS: Add microphone permissions to `ios/Runner/Info.plist`:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>This app needs microphone access for speech recognition</string>
   ```

6. Run the app:
```bash
flutter run
```

## 📦 Deployment

### Obtaining API Credentials

Before deployment, you need to obtain your own API credentials:

1. **Azure Speech Services**:
   - Go to [Azure Portal](https://portal.azure.com)
   - Create a new resource → AI + Machine Learning → Speech Service
   - After creation, go to "Keys and Endpoint" to find your key and region

2. **Google Gemini API**:
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create an API key for the Gemini model

3. **Picovoice API**:
   - Create an account at [Picovoice Console](https://console.picovoice.ai/)
   - Generate a new access key for wake word detection

### Server Deployment with Azure Container Apps

The backend can be deployed to Azure Container Apps using the included GitHub Actions workflow:

1. Set up the following GitHub secrets in your repository with your personal API credentials:
   - `AZURE_CREDENTIALS`: Azure service principal credentials
   - `DOCKERHUB_USERNAME`: Docker Hub username
   - `DOCKERHUB_TOKEN`: Docker Hub access token
   - `AZURE_SPEECH_KEY`: Your Azure Speech API key
   - `AZURE_SPEECH_REGION`: Your Azure region
   - `GEMINI_API_KEY`: Your Google Gemini API key
   - `PICOVOICE_API_KEY`: Your Picovoice API key

2. The workflow will automatically:
   - Build the Docker image for the backend
   - Push it to Docker Hub
   - Deploy to Azure Container Apps
   - Configure environment variables
   - Set up health monitoring

For manual deployment to Azure:

1. Build the Docker image
2. Push to your container registry
3. Deploy to Azure Container Apps with appropriate environment variables

### Mobile App Deployment

The Flutter application can be built for various platforms:

- **Android**: `flutter build apk`
- **iOS**: `flutter build ios`
- **Web**: `flutter build web`

## 📡 API Endpoints

The server exposes these main endpoints:

- `POST /api/conversation`: Translates text with comprehensive metadata
- `POST /api/speech-to-text`: Converts audio file to text
- `POST /api/voice-command`: Processes wake word commands
- `GET /api/audio/{filename}`: Retrieves generated audio files

## 🔮 Future Enhancements

- Additional language support beyond English, German, and Spanish
- Offline translation capabilities
- Custom voice and pronunciation options
- Expanded grammar explanation features
- Conversation history export
- Integration with language learning platforms
- Enhanced vocabulary building tools
- Customizable wake words

---

<a id="deutsch"></a>

# 🗣️ Speak and Translate - KI-Übersetzungsassistent [Deutsch]

Eine plattformübergreifende Anwendung, entwickelt mit Flutter und Azure KI-Diensten, die Echtzeit-Sprachübersetzung, Sprachbefehle und natürliche Sprachsynthese bietet. Die App unterstützt Gespräche zwischen mehreren Sprachen mit umfangreichen Lernfunktionen für Sprachschüler.

## 📋 Funktionen

- **🎙️ Sprachbefehle**: Aktivieren Sie das Mikrofon mit "Jarvis" und stoppen Sie die Aufnahme mit "Alexa"
- **🔊 Spracherkennung**: Konvertieren Sie gesprochene Sprache mit hoher Genauigkeit in Text
- **🌐 Echtzeit-Übersetzung**: Übersetzen Sie zwischen Sprachen mit KI-gestützter Präzision
- **🗣️ Natürliche Sprachsynthese**: Hören Sie Übersetzungen in natürlich klingenden Stimmen
- **🧠 Lehrreiche Übersetzungen**: Sehen Sie Wort-für-Wort-Übersetzungen zum Sprachenlernen
- **🎭 Mehrere Übersetzungsstile**: Zugriff auf muttersprachliche, umgangssprachliche, informelle und formelle Übersetzungen
- **💬 Chat-Oberfläche**: Verfolgen Sie den Gesprächsverlauf mit visuellen Sprechblasen
- **🎛️ Freisprechmodus**: Spielen Sie Übersetzungen automatisch für fortlaufende Gespräche ab
- **🔄 Zweisprachige Audiowiedergabe**: Hören Sie Quell- und übersetzte Wörter nacheinander
- **📱 Plattformübergreifend**: Funktioniert auf Android, iOS und Web-Plattformen

### Übersetzungsfähigkeiten im Detail

Die Anwendung bietet fortschrittliche Übersetzungsoptionen mit vier verschiedenen Formalitätsstufen:

1. **Muttersprachlich**: Professionelle Übersetzung, wie ein Muttersprachler sie ausdrücken würde
2. **Umgangssprachlich**: Lässige, alltägliche Sprache mit Redewendungen und Ausdrücken
3. **Informell**: Entspannte Sprache für lockere Situationen
4. **Formell**: Professionelle Sprache für geschäftliche oder formelle Kontexte

Jede Übersetzung enthält Wort-für-Wort-Erklärungen, um Benutzern zu helfen, die Struktur und den Wortschatz verschiedener Sprachen zu verstehen, was diese Anwendung besonders wertvoll für Sprachenlerner macht.

## 🔧 Technische Umsetzung

### Architekturüberblick

Die Anwendung besteht aus zwei Hauptkomponenten:

1. **Flutter Mobile Client**:
   - Benutzeroberfläche für Benutzerinteraktion und Chat-Schnittstelle
   - Verarbeitet Audioaufnahme und -wiedergabe
   - Verwaltet Gesprächsverlauf

2. **Python Backend Server**:
   - FastAPI REST-Dienst für Übersetzung und Sprachverarbeitung
   - Integriert Googles Gemini KI für fortschrittliche Übersetzung
   - Verwendet Azure Cognitive Services für Sprachsynthese und -erkennung
   - Containerisiert mit Docker für einfache Bereitstellung

### Verwendete Technologien

#### Mobile App
- Flutter mit Dart
- Riverpod für Zustandsverwaltung
- Audioaufnahme- und Wiedergabebibliotheken
- Material Design UI-Komponenten

#### Backend Server
- Python 3.9
- FastAPI Web-Framework
- Azure Cognitive Services Speech SDK
- Googles Gemini 2.0 KI-Modell
- Docker für Containerisierung
- Pydub für Audioverarbeitung

#### DevOps
- GitHub Actions für CI/CD
- Azure Container Apps für Hosting
- Docker Hub für Container-Registry

### Code-Organisation

Der Quellcode ist nach Clean-Architecture-Prinzipien strukturiert:

```
├── .github/workflows/      # CI/CD-Konfiguration für Azure-Bereitstellung
├── lib/                    # Flutter-Anwendungsquellcode
│   ├── features/           # Funktionsmodule (Übersetzung, Stimme, usw.)
│   │   └── translation/    # Übersetzungsfunktion
│   │       ├── data/       # Datenschicht mit Modellen und Repositories
│   │       ├── domain/     # Domänenschicht mit Entitäten und Anwendungsfällen
│   │       └── presentation/ # UI-Schicht mit Bildschirmen und Providern
│   └── main.dart           # Flutter-Anwendungseinstiegspunkt
└── server/                 # Backend-Server
    ├── app/                # Server-Anwendungscode
    │   ├── application/    # Anwendungsdienste
    │   ├── domain/         # Domänenentitäten
    │   └── infrastructure/ # API-Routen und externe Schnittstellen
    ├── Dockerfile          # Docker-Konfiguration für Server
    └── requirements.txt    # Python-Abhängigkeiten
```

## 🚀 Erste Schritte

### Voraussetzungen

Bevor Sie beginnen, benötigen Sie:

1. Flutter SDK (neueste Version)
2. Docker (für Backend)
3. Folgende API-Anmeldedaten:
   - **Azure Speech Services**: Erstellen Sie ein Konto im [Azure Portal](https://portal.azure.com), erstellen Sie eine Speech-Service-Ressource und holen Sie Ihren API-Schlüssel und Ihre Region
   - **Google Gemini API**: Melden Sie sich bei [Google AI Studio](https://makersuite.google.com/app/apikey) an, um Ihren Gemini API-Schlüssel zu erhalten
   - **Picovoice API**: Erstellen Sie ein Konto bei [Picovoice Console](https://console.picovoice.ai/), um Ihren API-Schlüssel für die Aktivierungswort-Erkennung zu erhalten

### Projekt von Grund auf erstellen

1. Erstellen Sie ein neues Verzeichnis für Ihr Projekt:
```bash
# Für Windows
mkdir speak_and_translate_app
cd speak_and_translate_app

# Für macOS/Linux
mkdir speak_and_translate_app
cd speak_and_translate_app
```

2. Erstellen Sie ein neues Flutter-Projekt:
```bash
flutter create speak_and_translate
cd speak_and_translate
```

3. Ersetzen Sie die Standard-Flutter-Projektstruktur durch die Repository-Struktur:
   - Ersetzen Sie den Inhalt des `lib`-Ordners durch den `lib`-Ordner des Repositories
   - Erstellen Sie einen `server`-Ordner und fügen Sie die Backend-Dateien hinzu

### Server-Einrichtung

1. Erstellen Sie ein `server`-Verzeichnis im Projektstamm und navigieren Sie dorthin:
```bash
mkdir server
cd server
```

2. Kopieren Sie die Server-Dateien aus dem Repository oder erstellen Sie die notwendigen Dateien manuell gemäß der Repository-Struktur.

3. Richten Sie Umgebungsvariablen ein:
   Erstellen Sie eine `.env`-Datei im Server-Verzeichnis mit Ihren eigenen API-Anmeldedaten:
```
AZURE_SPEECH_KEY=ihr_azure_speech_key
AZURE_SPEECH_REGION=ihre_azure_region
GEMINI_API_KEY=ihr_gemini_api_key
PICOVOICE_API_KEY=ihr_picovoice_api_key
TTS_DEVICE=cpu
```

4. Führen Sie mit Docker aus:
```bash
docker-compose up -d
```

5. Oder führen Sie lokal mit Python aus:
```bash
pip install -r requirements.txt
python -m app.main
```

### Mobile App-Einrichtung

1. Navigieren Sie zurück zum Mobile-App-Verzeichnis:
```bash
cd ..
```

2. Aktualisieren Sie die `pubspec.yaml`-Datei mit den erforderlichen Abhängigkeiten:
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1
  http: ^1.2.2
  json_annotation: ^4.9.0
  path_provider: ^2.1.5
  record: ^5.2.0
  permission_handler: ^11.3.1
  record_platform_interface: ^1.2.0
  flutter_sound: ^9.19.1
  just_audio: ^0.9.43
  flutter_markdown: ^0.7.5
  flutter_tts: ^4.2.1
  picovoice_flutter: ^3.0.4
  speech_to_text: ^7.0.0
```

3. Installieren Sie Abhängigkeiten:
```bash
flutter pub get
```

4. Konfigurieren Sie den API-Endpunkt:
   In `lib/features/translation/data/repositories/translation_repository_impl.dart` aktualisieren Sie die `baseUrl`, um auf Ihren Server zu zeigen:
```dart
// Ändern Sie diese Zeile, um auf Ihren Server zu zeigen
final String baseUrl = 'http://localhost:8000';
```

5. Richten Sie Berechtigungen ein:
   - Für Android: Fügen Sie Mikrofonberechtigungen zu `android/app/src/main/AndroidManifest.xml` hinzu:
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.INTERNET"/>
   ```
   
   - Für iOS: Fügen Sie Mikrofonberechtigungen zu `ios/Runner/Info.plist` hinzu:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>Diese App benötigt Mikrofonzugriff für Spracherkennung</string>
   ```

6. Führen Sie die App aus:
```bash
flutter run
```

## 📦 Bereitstellung

### API-Anmeldedaten erhalten

Vor der Bereitstellung müssen Sie Ihre eigenen API-Anmeldedaten erhalten:

1. **Azure Speech Services**:
   - Gehen Sie zum [Azure Portal](https://portal.azure.com)
   - Erstellen Sie eine neue Ressource → KI + Machine Learning → Speech Service
   - Nach der Erstellung gehen Sie zu "Schlüssel und Endpunkt", um Ihren Schlüssel und Ihre Region zu finden

2. **Google Gemini API**:
   - Besuchen Sie [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Erstellen Sie einen API-Schlüssel für das Gemini-Modell

3. **Picovoice API**:
   - Erstellen Sie ein Konto bei [Picovoice Console](https://console.picovoice.ai/)
   - Generieren Sie einen neuen Zugriffsschlüssel für die Aktivierungswort-Erkennung

### Server-Bereitstellung mit Azure Container Apps

Das Backend kann mit dem enthaltenen GitHub Actions-Workflow auf Azure Container Apps bereitgestellt werden:

1. Richten Sie die folgenden GitHub-Secrets in Ihrem Repository mit Ihren persönlichen API-Anmeldedaten ein:
   - `AZURE_CREDENTIALS`: Azure-Dienstprinzipal-Anmeldeinformationen
   - `DOCKERHUB_USERNAME`: Docker Hub-Benutzername
   - `DOCKERHUB_TOKEN`: Docker Hub-Zugriffstoken
   - `AZURE_SPEECH_KEY`: Ihr Azure Speech API-Schlüssel
   - `AZURE_SPEECH_REGION`: Ihre Azure-Region
   - `GEMINI_API_KEY`: Ihr Google Gemini API-Schlüssel
   - `PICOVOICE_API_KEY`: Ihr Picovoice API-Schlüssel

2. Der Workflow wird automatisch:
   - Das Docker-Image für das Backend erstellen
   - Es auf Docker Hub pushen
   - Auf Azure Container Apps bereitstellen
   - Umgebungsvariablen konfigurieren
   - Gesundheitsüberwachung einrichten

Für manuelle Bereitstellung auf Azure:

1. Erstellen Sie das Docker-Image
2. Pushen Sie es in Ihre Container-Registry
3. Stellen Sie es auf Azure Container Apps mit entsprechenden Umgebungsvariablen bereit

### Mobile App-Bereitstellung

Die Flutter-Anwendung kann für verschiedene Plattformen erstellt werden:

- **Android**: `flutter build apk`
- **iOS**: `flutter build ios`
- **Web**: `flutter build web`

## 📡 API-Endpunkte

Der Server stellt diese Haupt-Endpunkte bereit:

- `POST /api/conversation`: Übersetzt Text mit umfassenden Metadaten
- `POST /api/speech-to-text`: Konvertiert Audiodatei zu Text
- `POST /api/voice-command`: Verarbeitet Aktivierungswort-Befehle
- `GET /api/audio/{filename}`: Ruft generierte Audiodateien ab

## 🔮 Zukünftige Erweiterungen

- Zusätzliche Sprachunterstützung über Englisch, Deutsch und Spanisch hinaus
- Offline-Übersetzungsfähigkeiten
- Benutzerdefinierte Stimm- und Ausspracheoptionen
- Erweiterte Grammatikerklärungsfunktionen
- Export des Gesprächsverlaufs
- Integration mit Sprachlernplattformen
- Verbesserte Werkzeuge zum Wortschatzaufbau
- Anpassbare Aktivierungswörter
