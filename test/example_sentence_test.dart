import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yin_japanese_coach/main.dart';

void main() {
  const files = {
    'n5_verbs.json': '動詞',
    'n5_nouns.json': '名詞',
    'n5_adjectives.json': '形容詞',
    'n5_adverbs.json': '副詞',
    'n5_other.json': '其他',
  };
  final words = [
    for (final entry in files.entries)
      for (final item in json.decode(File('assets/${entry.key}').readAsStringSync()) as List<dynamic>)
        Vocabulary.fromJson(item as Map<String, dynamic>, entry.value),
  ]..sort((a, b) => a.number.compareTo(b.number));

  test('worksheet words are numbered 1 to 1000 in ten blocks', () {
    expect(words, hasLength(1000));
    expect(words.map((word) => word.number).toSet(), hasLength(1000));
    expect(words.first.number, 1);
    expect(words.last.number, 1000);

    for (final word in words) {
      final offset = (word.number - 1) % 100;
      final last = word.number > 900;
      final String section;
      if (!last) {
        if (offset < 55) {
          section = '名詞';
        } else if (offset < 75) {
          section = '動詞';
        } else if (offset < 90) {
          section = '形容詞';
        } else if (offset < 95) {
          section = '其他';
        } else {
          section = '副詞';
        }
      } else if (offset < 50) {
        section = '名詞';
      } else if (offset < 70) {
        section = '動詞';
      } else if (offset < 85) {
        section = '形容詞';
      } else if (offset < 95) {
        section = '其他';
      } else {
        section = '副詞';
      }
      expect(word.wordType, contains(section), reason: '${word.number} ${word.kanji}');
      expect(word.english, isNotEmpty, reason: word.kanji);
      expect(word.meaning, isNotEmpty, reason: word.kanji);
      final sentence = word.example;
      expect(sentence.japanese, isNotEmpty, reason: word.kanji);
      expect(sentence.hiragana, isNotEmpty, reason: word.kanji);
      expect(sentence.romaji, isNotEmpty, reason: word.kanji);
      expect(sentence.chinese, isNotEmpty, reason: word.kanji);
      expect(sentence.english, isNotEmpty, reason: word.kanji);
      expect(sentence.pattern, isNotEmpty, reason: word.kanji);
      expect(sentence.rank, inInclusiveRange(1, 27), reason: word.kanji);
    }

    expect(words.where((word) => word.wordType.contains('名詞')), hasLength(545));
    expect(words.where((word) => word.wordType.contains('動詞')), hasLength(200));
    expect(words.where((word) => word.wordType.contains('形容詞')), hasLength(150));
    expect(words.where((word) => word.wordType.contains('副詞')), hasLength(50));
    expect(words.where((word) => word.wordType.contains('其他')), hasLength(55));
    expect(words[0].kanji, '私');
    expect(words[0].example.japanese, '私は酒を飲みません。');
    expect(words[0].example.pattern, '～ません（動詞否定）');
    expect(words[0].example.rank, 4);
    expect(words[0].english, 'I');
    expect(words[999].number, 1000);
    expect(words[999].wordType, contains('副詞'));
  });
}
