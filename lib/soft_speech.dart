import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

final Map<String, Map<String, String>?> _naturalVoices = {};

/// Speaks Japanese and Chinese at a natural pace, with the most
/// human-sounding voice available on the device.
Future<void> applyNaturalVoice(FlutterTts tts, String language) async {
  await tts.setLanguage(language);
  await tts.setVolume(1.0);
  await tts.setPitch(1.0);
  await tts.setSpeechRate(kIsWeb ? 1.0 : 0.5);

  final voice = await _naturalVoice(tts, language);
  if (voice != null) {
    await tts.setVoice(voice);
  }
}

Future<Map<String, String>?> _naturalVoice(
  FlutterTts tts,
  String language,
) async {
  if (_naturalVoices.containsKey(language)) {
    return _naturalVoices[language];
  }

  final voices = await _loadVoices(tts);
  final prefix = language.toLowerCase().replaceAll('_', '-');
  Map<String, String>? best;
  var bestScore = -999;

  for (final voice in voices) {
    final locale = voice['locale']!.toLowerCase().replaceAll('_', '-');
    if (!locale.startsWith(prefix) && !prefix.startsWith(locale)) {
      continue;
    }
    final score = _naturalScore(voice['name']!, locale, prefix);
    if (score > bestScore) {
      bestScore = score;
      best = voice;
    }
  }

  _naturalVoices[language] = best;
  return best;
}

Future<List<Map<String, String>>> _loadVoices(FlutterTts tts) async {
  for (var attempt = 0; attempt < 4; attempt++) {
    final raw = await tts.getVoices;
    if (raw is List && raw.isNotEmpty) {
      final voices = <Map<String, String>>[];
      for (final voice in raw) {
        if (voice is! Map) continue;
        final name = '${voice['name'] ?? ''}';
        final locale = '${voice['locale'] ?? ''}';
        if (name.isEmpty || locale.isEmpty) continue;
        voices.add({'name': name, 'locale': locale});
      }
      if (voices.isNotEmpty) return voices;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  return const [];
}

int _naturalScore(String name, String locale, String language) {
  final normalized = name.toLowerCase();
  var score = 0;
  if (locale == language) score += 20;
  const humanHints = [
    'neural',
    'wavenet',
    'premium',
    'enhanced',
    'natural',
    'google',
    'siri',
    'kyoko',
    'otoya',
    'nanami',
    'haruka',
    'mei-jia',
    'meijia',
    'ting-ting',
    'tingting',
    'sin-ji',
    'sinji',
  ];
  for (final hint in humanHints) {
    if (normalized.contains(hint)) score += 40;
  }
  if (normalized.contains('compact') || normalized.contains('espeak')) {
    score -= 40;
  }
  return score;
}
