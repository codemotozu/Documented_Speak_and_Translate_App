import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_message_model.dart';
import '../../domain/repositories/translation_repository.dart';
import '../providers/speech_provider.dart';
import '../providers/translation_provider.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String prompt;

  const ConversationScreen({
    super.key,
    required this.prompt,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.prompt.isNotEmpty) {
        ref.read(translationProvider.notifier).startConversation(widget.prompt);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

@override
void dispose() {
  _scrollController.dispose();
  
  // Use this pattern for safe ref access
  final shouldStopSpeech = mounted;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (shouldStopSpeech && mounted) { // Double-check mounted status
      try {
        ref.read(speechProvider.notifier).stop();
      } catch (e) {
        print('Safe disposal error: $e');
      }
    }
  });
  
  super.dispose();
}



  @override
  Widget build(BuildContext context) {
    final translationState = ref.watch(translationProvider);
    final speechState = ref.watch(speechProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('AI Conversation',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () =>
                ref.read(translationProvider.notifier).clearConversation(),
            tooltip: 'Clear history',
          ),
          IconButton(
            icon: Icon(
              speechState ? Icons.volume_up : Icons.volume_off,
              color: speechState ? Colors.white : Colors.grey,
            ),
            onPressed: () =>
                ref.read(speechProvider.notifier).toggleHandsFreeMode(),
            tooltip: speechState ? 'Disable audio' : 'Enable audio',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: translationState.messages.length,
              itemBuilder: (context, index) {
                final message = translationState.messages[index];
                return _buildMessageWidget(message, speechState);
              },
            ),
          ),
      
        ],
      ),
    );
  }

  Widget _buildMessageWidget(ChatMessage message, bool speechState) {
    switch (message.type) {
      case MessageType.user:
        return _buildUserMessage(message);
      case MessageType.ai:
        if (message.isLoading) return _buildLoadingMessage();
        if (message.error != null) return _buildErrorMessage(message.error!);
        return _buildAiMessage(message, speechState);
    }
  }

  Widget _buildUserMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange[100],
            child: const Icon(Icons.person, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiMessage(ChatMessage message, bool speechState) {
    final translation = message.translation!;

    if (speechState && translation.audioPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await ref
              .read(speechProvider.notifier)
              .playAudio(translation.audioPath);
          ref.read(translationProvider.notifier).clearConversation();

          if (mounted) {
            Navigator.pop(context);
            // Add this to ensure sound plays after navigation animation completes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(translationRepositoryProvider).playCompletionSound();
            });
          }
        } catch (e) {
          print('Error handling audio completion: $e');
        }
      });
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: const Icon(Icons.smart_toy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data: translation.translatedText,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 16, color: Colors.white),
                    h1: const TextStyle(fontSize: 24, color: Colors.orange),
                    h2: const TextStyle(fontSize: 22, color: Colors.orange),
                    h3: const TextStyle(fontSize: 20, color: Colors.orange),
                    code: const TextStyle(
                      backgroundColor: Colors.orange,
                      fontFamily: 'monospace',
                    ),
                    listBullet: TextStyle(color: Colors.orange[800]),
                  ),
                ),
                if (translation.audioPath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            speechState
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            color: Colors.orange[800],
                          ),
                          onPressed: () {
                            if (speechState) {
                              ref.read(speechProvider.notifier).stop();
                            } else {
                              ref
                                  .read(speechProvider.notifier)
                                  .playAudio(translation.audioPath);
                            }
                          },
                        ),
                        Text(
                          speechState ? 'Pause' : 'Play',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Thinking...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[900]!.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
