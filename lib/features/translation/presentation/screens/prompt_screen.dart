import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../domain/repositories/translation_repository.dart';
import '../providers/audio_recorder_provider.dart';
import '../providers/voice_command_provider.dart';
import '../widgets/voice_command_status_inficator.dart';

final isListeningProvider = StateProvider<bool>((ref) => false);

class PromptScreen extends ConsumerStatefulWidget {
  const PromptScreen({super.key});

  @override
  ConsumerState<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends ConsumerState<PromptScreen> {
  late final TextEditingController _textController;
  late final AudioRecorder _recorder;
  late PorcupineManager _porcupineManager;
  late stt.SpeechToText _speech;
  bool _isWakeWordMode = true;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _recorder = ref.read(audioRecorderProvider);
    _speech = stt.SpeechToText();

    _initializeRecorder();
    _initPorcupine();
  }

  Future<void> _initializeRecorder() async {
    try {
      await _recorder.init();
    } catch (e) {
      debugPrint('Recorder init error: $e');
    }
  }

  void _initPorcupine() async {
    try {
      _porcupineManager = await PorcupineManager.fromBuiltInKeywords(
        // 'PICOVOICE_API_KEY',
        '79pMNpkBL/Ssr8wQ4kFF8vqeB0mPwX0G7/FEEaaZfsJgAzVoo07xug==',
        [BuiltInKeyword.JARVIS, BuiltInKeyword.ALEXA],
        _wakeWordCallback,
      );
      await _porcupineManager.start();
      debugPrint("Porcupine initialized successfully");
    } on PorcupineException catch (err) {
      debugPrint("Failed to initialize Porcupine: ${err.message}");
    }
  }

  Future<void> _startConversation() async {
    if (_textController.text.isNotEmpty) {
      await ref.read(translationRepositoryProvider).playUISound('start_conversation');

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/conversation',
          arguments: _textController.text,
        ).then((_) => _textController.clear());
      }
    }
  }

  void _wakeWordCallback(int keywordIndex) async {
    if (!mounted) return;

    // JARVIS detected
    if (keywordIndex == 0 && _isWakeWordMode) {
      await _startVoiceRecording();
      _isWakeWordMode = false;
    }
    // ALEXA detected
    else if (keywordIndex == 1 && !_isWakeWordMode) {
      await _stopVoiceRecording();
      _isWakeWordMode = true;
      
      // Automatically start conversation after stopping recording
      if (_textController.text.isNotEmpty) {
        await _startConversation();
      }
    }
  }

  void _handleVoiceCommand(VoiceCommandState state) {
    if (!mounted) return;
    setState(() {});

    if (state.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.error!)));
    }
  }

  Future<void> _startVoiceRecording() async {
    try {
      await ref.read(translationRepositoryProvider).playUISound('mic_on');
      await _recorder.startListening("open");
      ref.read(isListeningProvider.notifier).state = true;
      final currentState = ref.read(voiceCommandProvider);
      ref.read(voiceCommandProvider.notifier).state =
          currentState.copyWith(isListening: true);
    } catch (e) {
      debugPrint('Recording start error: $e');
    }
  }

  Future<void> _stopVoiceRecording() async {
    try {
      await ref.read(translationRepositoryProvider).playUISound('mic_off');
      final path = await _recorder.stopListening();
      if (path != null) {
        var text = await ref
            .read(translationRepositoryProvider)
            .processAudioInput(path);

        // Filter out wake words from the recognized text
        text = text.replaceAll(RegExp(r'\b(?:jarvis|alexa)\b', caseSensitive: false), '').trim();

        // Only update text if there's actual content after filtering
        if (text.isNotEmpty) {
          _textController.text = text;
        }
      }
    } catch (e) {
      debugPrint('Recording stop error: $e');
    } finally {
      ref.read(isListeningProvider.notifier).state = false;
      final currentState = ref.read(voiceCommandProvider);
      ref.read(voiceCommandProvider.notifier).state =
          currentState.copyWith(isListening: false);
    }
  }

  @override
  void dispose() {
    _porcupineManager.delete();
    _recorder.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceCommandProvider);

    ref.listen<VoiceCommandState>(voiceCommandProvider, (_, state) {
      if (!mounted) return;
      _handleVoiceCommand(state);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1C1C1E),
        border: null,
        middle: const Text('AI Chat Assistant',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.gear,
              color: CupertinoColors.systemGrey, size: 28),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            VoiceCommandStatusIndicator(
              isListening: voiceState.isListening,
            ),
            Text(
              _isWakeWordMode 
                ? 'Say "Jarvis" to start listening'
                : 'Say "Alexa" to stop listening and start conversation',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: CupertinoTextField(
                  controller: _textController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                  placeholder: 'write your prompt here',
                  placeholderStyle: const TextStyle(
                      color: CupertinoColors.placeholderText, fontSize: 17),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF3A3A3C),
                      width: 0.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startConversation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 61, 62, 63),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('start conversation',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final voiceState = ref.watch(voiceCommandProvider);
                    return ElevatedButton(
                      onPressed: () => _toggleRecording(voiceState.isListening),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            voiceState.isListening ? Colors.red : Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Icon(Icons.mic, size: 28, color: Colors.black,),
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

  Future<void> _toggleRecording(bool isCurrentlyListening) async {
    if (isCurrentlyListening) {
      await _stopVoiceRecording();
      _isWakeWordMode = true;
    } else {
      await _startVoiceRecording();
      _isWakeWordMode = false;
    }
  }
}
