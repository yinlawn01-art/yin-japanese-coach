import 'dart:js_interop';

@JS('speechSynthesis')
external _SpeechSynthesis get _speechSynthesis;

extension type _SpeechSynthesis._(JSObject _) implements JSObject {
  external JSArray<_SpeechVoice> getVoices();
}

extension type _SpeechVoice._(JSObject _) implements JSObject {
  external String get name;
  external String get lang;

  @JS('localService')
  external bool get isLocalService;
}

/// Browser voices, including whether each one is stored on the device.
List<Map<String, String>> webVoices() {
  try {
    final voices = <Map<String, String>>[];
    for (final voice in _speechSynthesis.getVoices().toDart) {
      final name = voice.name;
      final locale = voice.lang;
      if (name.isEmpty || locale.isEmpty) continue;
      voices.add({
        'name': name,
        'locale': locale,
        'gender': '',
        'local': voice.isLocalService ? 'true' : 'false',
      });
    }
    return voices;
  } catch (_) {
    return const [];
  }
}
