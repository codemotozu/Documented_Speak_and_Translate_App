// lib/features/translation/presentation/providers/translation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_message_model.dart';
import '../../domain/repositories/translation_repository.dart';
import 'speech_provider.dart';

// History management constants
const _maxMessages = 50; // Maximum messages to keep in history
const _messagesToKeepWhenPruning = 40; // Number to keep when pruning
const _initialMessagesToPreserve = 2; // Keep first N messages of conversation

class TranslationState {
  final bool isLoading;
  final List<ChatMessage> messages;
  final String? error;

  TranslationState({
    required this.isLoading,
    required this.messages,
    this.error,
  });

  factory TranslationState.initial() => TranslationState(
        isLoading: false,
        messages: [],
        error: null,
      );

  TranslationState copyWith({
    bool? isLoading,
    List<ChatMessage>? messages,
    String? error,
  }) {
    return TranslationState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      error: error ?? this.error,
    );
  }
}

class TranslationNotifier extends StateNotifier<TranslationState> {
  final TranslationRepository _repository;
  final Ref _ref;
  bool _mounted = true;

  TranslationNotifier(this._repository, this._ref)
      : super(TranslationState.initial());

  Future<void> startConversation(String text) async {
    if (!_mounted || text.isEmpty) return;

    try {
      // Prune history before adding new messages
      var updatedMessages = _pruneMessageHistory([
        ...state.messages,
        ChatMessage.user(text),
        ChatMessage.aiLoading(),
      ]);

      state = state.copyWith(messages: updatedMessages, isLoading: true);
      await _repository.stopAudio();

      final translation = await _repository.getTranslation(text);
      if (!_mounted) return;

      // Prune again after receiving response
      final newMessages = _pruneMessageHistory(
        List<ChatMessage>.from(state.messages)
          ..removeLast()
          ..add(ChatMessage.ai(translation: translation)),
      );

      state = state.copyWith(
        isLoading: false,
        messages: newMessages,
        error: null,
      );

      final isHandsFree = _ref.read(speechProvider);
      if (isHandsFree && translation.audioPath != null) {
        await _repository.playAudio(translation.audioPath!);
      }
    } catch (e) {
      if (!_mounted) return;
      
      final newMessages = _pruneMessageHistory(
        List<ChatMessage>.from(state.messages)
          ..removeLast()
          ..add(ChatMessage.aiError(e.toString())),
      );

      state = state.copyWith(
        isLoading: false,
        messages: newMessages,
        error: e.toString(),
      );
    }
  }

  List<ChatMessage> _pruneMessageHistory(List<ChatMessage> messages) {
    if (messages.length <= _maxMessages) return messages;

    return [
      // Preserve initial conversation context
      ...messages.take(_initialMessagesToPreserve),
      // Keep most recent messages
      ...messages.sublist(
        messages.length - (_messagesToKeepWhenPruning - _initialMessagesToPreserve),
      ),
    ];
  }

  Future<void> playAudio(String audioPath) async {
    try {
      await _repository.playAudio(audioPath);
    } catch (e) {
      if (_mounted) {
        state = state.copyWith(error: 'Audio playback failed: ${e.toString()}');
      }
    }
  }

  Future<void> stopAudio() async {
    try {
      await _repository.stopAudio();
    } catch (e) {
      if (_mounted) {
        state = state.copyWith(error: 'Error stopping audio: ${e.toString()}');
      }
    }
  }

  void clearConversation() {
    if (_mounted) {
      state = TranslationState.initial();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _repository.dispose();
    super.dispose();
  }
}

final translationProvider =
    StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  return TranslationNotifier(
    ref.watch(translationRepositoryProvider),
    ref,
  );
});