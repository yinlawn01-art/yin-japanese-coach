import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'web_voices.dart';

/// One step on the speech-engine volume scale. The engine accepts 0.0 to 1.0.
const double speechVolumeNotch = 0.1;

final Map<String, Map<String, String>?> _chosenVoices = {};

/// Speaks at a natural pace. Japanese is one notch louder and at 80% of
/// normal speed. Chinese is one notch quieter. Japanese uses a female
/// voice when the device has one. Chinese uses a male voice when it has one.
Future<void> applyNaturalVoice(FlutterTts tts, String language) async {
  await tts.setLanguage(language);
  await tts.setVolume(volumeForLanguage(language));
  await tts.setPitch(1.0);
  await tts.setSpeechRate(rateForLanguage(language));

  final voice = await _preferredVoice(tts, language);
  if (voice != null) {
    await tts.setVoice({'name': voice['name']!, 'locale': voice['locale']!});
  }
}

/// Japanese sits one notch above full volume and is clamped to the engine
/// maximum. Chinese sits one notch below it.
double volumeForLanguage(String language) {
  const base = 1.0;
  final stepped = language.toLowerCase().startsWith('zh')
      ? base - speechVolumeNotch
      : base + speechVolumeNotch;
  return stepped.clamp(0.0, 1.0);
}

/// Japanese is 80% of the platform's normal speaking rate.
double rateForLanguage(String language, {bool? web}) {
  final normal = (web ?? kIsWeb) ? 1.0 : 0.5;
  if (language.toLowerCase().startsWith('ja')) return normal * 0.8;
  return normal;
}

Future<Map<String, String>?> _preferredVoice(
  FlutterTts tts,
  String language,
) async {
  if (_chosenVoices.containsKey(language)) {
    return _chosenVoices[language];
  }

  final voices = await _loadVoices(tts);
  final prefix = language.toLowerCase().replaceAll('_', '-');
  Map<String, String>? best;
  var bestScore = -9999;

  for (final voice in voices) {
    final locale = voice['locale']!.toLowerCase().replaceAll('_', '-');
    if (!locale.startsWith(prefix) && !prefix.startsWith(locale)) {
      continue;
    }
    final score = scoreVoice(voice, prefix);
    if (score > bestScore) {
      bestScore = score;
      best = voice;
    }
  }

  _chosenVoices[language] = best;
  return best;
}

Future<List<Map<String, String>>> _loadVoices(FlutterTts tts) async {
  for (var attempt = 0; attempt < 4; attempt++) {
    final browserVoices = webVoices();
    if (browserVoices.isNotEmpty) return browserVoices;
    final raw = await tts.getVoices;
    if (raw is List && raw.isNotEmpty) {
      final voices = <Map<String, String>>[];
      for (final voice in raw) {
        if (voice is! Map) continue;
        final name = '${voice['name'] ?? ''}';
        final locale = '${voice['locale'] ?? ''}';
        if (name.isEmpty || locale.isEmpty) continue;
        voices.add({
          'name': name,
          'locale': locale,
          'gender': '${voice['gender'] ?? ''}',
        });
      }
      if (voices.isNotEmpty) return voices;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  return const [];
}

/// Prefers a female Japanese voice, or a male voice for other languages,
/// then the clearest recording of that voice.
int scoreVoice(Map<String, String> voice, String language) {
  final name = (voice['name'] ?? '').toLowerCase();
  final locale = (voice['locale'] ?? '').toLowerCase().replaceAll('_', '-');
  final gender = (voice['gender'] ?? '').toLowerCase();
  var score = 0;
  if (locale == language) score += 20;
  // A voice stored on the device keeps working with no network.
  if (voice['local'] == 'true') score += 1000;

  final male = gender == 'male' || _nameIsMale(name, language);
  final female = gender == 'female' || _nameIsFemale(name, language);
  final preferFemale = language.startsWith('ja');
  if (preferFemale) {
    if (female && gender != 'male') score += 400;
    if (male && gender != 'female') score -= 400;
  } else {
    if (male && gender != 'female') score += 400;
    if (female && gender != 'male') score -= 400;
  }

  const qualityHints = [
    'neural',
    'wavenet',
    'premium',
    'enhanced',
    'natural',
    'google',
    'siri',
  ];
  for (final hint in qualityHints) {
    if (name.contains(hint)) score += 40;
  }
  if (name.contains('compact') || name.contains('espeak')) score -= 40;
  return score;
}

bool _nameIsMale(String name, String language) {
  const names = [
    'otoya',
    'ichiro',
    'keita',
    'hattori',
    'daichi',
    'takumi',
    'zhiwei',
    'kangkang',
    'yunxi',
    'yunjian',
    'yunyang',
    'yunhao',
  ];
  for (final hint in names) {
    if (name.contains(hint)) return true;
  }
  if (name.contains(' male')) return true;

  final code = RegExp(r'(?:neural2|wavenet|standard|news)[-_ ]([a-d])\b')
      .firstMatch(name);
  if (code != null) {
    final letter = code.group(1)!;
    if (language.startsWith('ja')) return letter == 'c' || letter == 'd';
    if (language.startsWith('zh')) return letter == 'b' || letter == 'c';
  }
  return false;
}

bool _nameIsFemale(String name, String language) {
  const names = [
    'kyoko',
    'nanami',
    'haruka',
    'sayaka',
    'ayumi',
    'mei-jia',
    'meijia',
    'ting-ting',
    'tingting',
    'sin-ji',
    'sinji',
    'hanhan',
    'yating',
    'hsiaochen',
    'hsiaoyu',
    'xiaoxiao',
    'xiaoyi',
    'yaoyao',
    'huihui',
  ];
  for (final hint in names) {
    if (name.contains(hint)) return true;
  }
  if (name.contains(' female')) return true;

  final code = RegExp(r'(?:neural2|wavenet|standard|news)[-_ ]([a-d])\b')
      .firstMatch(name);
  if (code != null && language.startsWith('ja')) {
    final letter = code.group(1)!;
    return letter == 'a' || letter == 'b';
  }
  return false;
}
