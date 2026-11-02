import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yin_japanese_coach/main.dart';
import 'package:yin_japanese_coach/romaji_speech.dart';

void main() {
  final words = [
    for (final name in [
      'n5_verbs.json',
      'n5_nouns.json',
      'n5_adjectives.json',
      'n5_adverbs.json',
      'n5_other.json',
    ])
      ...json.decode(File('assets/$name').readAsStringSync()) as List<dynamic>,
  ].map((item) => Vocabulary.fromJson(item as Map<String, dynamic>, '')).toList();

  test('each worksheet word keeps its hiragana reading', () {
    for (final word in words) {
      expect(word.hiragana, isNotEmpty, reason: word.kanji);
      expect(word.romaji, isNotEmpty, reason: word.kanji);
      expect(word.example.hiragana, isNotEmpty, reason: word.kanji);
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
}
