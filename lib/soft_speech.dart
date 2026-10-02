import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Speaks Japanese and Chinese with a lower pitch, a quieter volume,
/// and a pace that stays slow without stretching each syllable.
Future<void> applySoftVoice(FlutterTts tts, String language) async {
  await tts.setLanguage(language);
  await tts.setVolume(0.8);
  if (kIsWeb) {
    await tts.setSpeechRate(0.75);
    await tts.setPitch(0.82);
  } else {
    await tts.setSpeechRate(0.42);
    await tts.setPitch(0.88);
  }
}
