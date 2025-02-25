
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/translation_repository_impl.dart';
import '../entities/translation.dart';

final translationRepositoryProvider = Provider<TranslationRepository>((ref) {
  return TranslationRepositoryImpl();
});


// In translation_repository.dart
abstract class TranslationRepository {
  Future<Translation> getTranslation(String text);
  Future<String> processAudioInput(String audioPath); // Changed from Future<void>
  Future<void> playAudio(String audioPath);
  Future<void> stopAudio();
  Future<void> playCompletionSound(); 
  Future<void> playUISound(String soundType);
  void dispose();
}
