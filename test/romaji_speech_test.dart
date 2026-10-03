import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yin_japanese_coach/example_sentence.dart';
import 'package:yin_japanese_coach/main.dart';
import 'package:yin_japanese_coach/romaji_speech.dart';

String _asHiragana(String text) {
  return String.fromCharCodes(
    text.runes.map((rune) {
      if (rune >= 0x30A1 && rune <= 0x30F6) return rune - 0x60;
      return rune;
    }),
  );
}

void main() {
  final words = [
    for (final name in ['n5_verbs.json', 'n5_nouns.json', 'n5_adjectives.json'])
      ...json.decode(File('assets/$name').readAsStringSync()) as List<dynamic>,
  ].map((item) => Vocabulary.fromJson(item as Map<String, dynamic>, '')).toList();

  test('each word is spoken as its roman spelling', () {
    for (final word in words) {
      expect(
        _asHiragana(pronunciationForRomaji(word.romaji)),
        _asHiragana(word.hiragana),
        reason: word.kanji,
      );
    }
  });

  test('sentence particles follow the roman spelling', () {
    expect(
      pronunciationForRomaji('gakusei wa sensei ni au.'),
      'がくせい わ せんせい に あう。',
    );
    expect(
      pronunciationForRomaji('gakusei wa hon o yomu.'),
      'がくせい わ ほん お よむ。',
    );
    expect(
      pronunciationForRomaji('gakusei wa gakkou e iku.'),
      'がくせい わ がっこう え いく。',
    );
    expect(
      pronunciationForRomaji('haha wa gohan o tsukuru.'),
      'はは わ ごはん お つくる。',
    );
  });

  test('every example sentence can be spoken from its romaji', () {
    for (final word in words) {
      final sentence = exampleSentenceFor(word.kanji);
      final spoken = pronunciationForRomaji(sentence.romaji);
      expect(spoken, endsWith('。'), reason: word.kanji);
      expect(
        _asHiragana(spoken.replaceAll(' ', '')),
        contains(_asHiragana(word.hiragana)),
      );
      expect(spoken, isNot(contains(RegExp(r'[A-Za-z]'))));
    }
  });
}
