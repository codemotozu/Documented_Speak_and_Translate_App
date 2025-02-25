import 'package:audio_session/audio_session.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../domain/entities/translation.dart';
import '../../domain/repositories/translation_repository.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http_parser/http_parser.dart';


class AudioMetadata {
  final String album;
  final String title;
  final Uri artwork;

  const AudioMetadata({
    required this.album,
    required this.title,
    required this.artwork,
  });
}

class TranslationRepositoryImpl implements TranslationRepository {
  // final String baseUrl = 'http://10.0.2.2:8000'; // here you can hear the translaion in my local machine dont forget to update main.py
  final String baseUrl = 'https://docker-and-azure.redpebble-9a75e52a.westus2.azurecontainerapps.io';
  static const timeoutDuration = Duration(seconds: 240);
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _soundPlayer = AudioPlayer(); // For completion sound
  final HttpClient _httpClient = HttpClient()
    ..badCertificateCallback = (cert, host, port) => true;
  late final http.Client _client;
    final AudioPlayer _uiSoundPlayer = AudioPlayer();

  TranslationRepositoryImpl() {
    _client = IOClient(_httpClient);
  }

  String _getAudioUrl(String audioPath) {
    final filename = path.basename(audioPath);
    final encodedFilename = Uri.encodeComponent(filename);
    return '$baseUrl/api/audio/$encodedFilename';
  }


 @override
  Future<void> playUISound(String soundType) async {
    try {
      String soundPath;
      switch (soundType) {
        case 'mic_on':
          soundPath = 'assets/sounds/open.wav';
          break;
        case 'mic_off':
          soundPath = 'assets/sounds/close.wav';
          break;
        case 'start_conversation':
          soundPath = 'assets/sounds/send.wav';
          break;
        default:
          return;
      }
      
      await _uiSoundPlayer.setAsset(soundPath);
      await _uiSoundPlayer.play();
    } catch (e) {
      print('Error playing UI sound: $e');
    }
  }


@override
Future<void> playAudio(String audioPath) async {
  try {
    final audioUrl = _getAudioUrl(audioPath);
    print('Playing audio from URL: $audioUrl');



    // Configure Android audio attributes
    await _audioPlayer.setAndroidAudioAttributes(
      const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.assistant,
      ),
    );

    // Set audio source with headers
    await _audioPlayer.setAudioSource(
      AudioSource.uri(
        Uri.parse(audioUrl),
        headers: {"Content-Type": "audio/mpeg"},
        // tag:  AudioMetadata( // Your custom class or remove
        //   album: "TranslationAudio",
        //   title: "AudioTranslation",
        //   artwork: Uri.parse("https://example.com/artwork.jpg"),
        // ),
      ),
      preload: true,
      initialPosition: Duration.zero,
    );

    // Error handling
    _audioPlayer.playbackEventStream.listen(
      (event) {},
      onError: (e, st) => print('Player error: $e'),
    );

    await _audioPlayer.play();
    await _audioPlayer.playerStateStream.firstWhere((state) =>
        state.processingState == ProcessingState.completed ||
        state.processingState == ProcessingState.idle);
  } catch (e) {
    print('Error: $e');
    await _audioPlayer.stop();
    rethrow;
  } finally {
    await _audioPlayer.stop();
  }
}


  @override
  Future<void> playCompletionSound() async {
    try {
      await _soundPlayer.setAsset('assets/sounds/Blink.wav');
      await _soundPlayer.play();
    } catch (e) {
      print('Error playing completion sound: $e');
    }
  }

  // Rest of the existing code remains unchanged...
  @override
  Future<Translation> getTranslation(String text) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/conversation'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
        body: utf8.encode(json.encode({
          'text': text,
          'source_lang': 'en',
          'target_lang': 'de',
        })),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(decodedBody);
        final translation = Translation.fromJson(data);
        
        if (translation.audioPath != null) {
          final audioUrl = _getAudioUrl(translation.audioPath!);
          print('Audio URL: $audioUrl');
        }
        
        return translation;
      } 

      else {
        throw Exception('Server error: ${response.statusCode}\n${utf8.decode(response.bodyBytes)}');
      }
    } catch (e) {
      print('Error in getTranslation: $e');
      if (e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to server. Please make sure the server is running at $baseUrl');
      }
      rethrow;
    }
  }

  @override
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _client.close();
    _audioPlayer.dispose();
    _soundPlayer.dispose(); // Dispose the sound player
     _uiSoundPlayer.dispose();
  }


// Update processAudioInput in translation_repository_impl.dart
@override
Future<String> processAudioInput(String audioPath) async {
  try {
    final file = File(audioPath);
    final mimeType = _getMimeType(audioPath);
    
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/speech-to-text'))
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        audioPath,
        contentType: MediaType.parse(mimeType),
      ));

    final response = await request.send().timeout(timeoutDuration);
    
    if (response.statusCode == 200) {
      return json.decode(await response.stream.bytesToString())['text'];
    } else {
      final errorBody = await response.stream.bytesToString();
      throw Exception('ASR Error ${response.statusCode}: $errorBody');
    }
  } catch (e) {
    print('Audio processing error: $e');
    rethrow;
  }
}


  String _getMimeType(String filePath) {
  final ext = path.extension(filePath).toLowerCase();
  switch (ext) {
    case '.wav':
      return 'audio/wav; codecs=1';
    case '.mp3':
      return 'audio/mpeg; codecs=mp3';
    case '.aac':
      return 'audio/aac; codecs=mp4a.40.2';
    case '.ogg':
      return 'audio/ogg; codecs=vorbis';
    default:
      throw FormatException('Unsupported audio format: $ext');
  }
}

}