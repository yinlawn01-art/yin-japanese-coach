import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yin_japanese_coach/example_sentence.dart';
import 'package:yin_japanese_coach/main.dart';

void main() {
  final words = [
    for (final name in ['n5_verbs.json', 'n5_nouns.json', 'n5_adjectives.json', 'n5_adverbs.json'])
      ...json.decode(File('assets/$name').readAsStringSync()) as List<dynamic>,
  ].map((item) => Vocabulary.fromJson(item as Map<String, dynamic>, '')).toList();

  final byKanji = {
    for (final word in words) word.kanji: word,
  };

  test('every vocabulary word has one example sentence', () {
    expect(words.map((word) => word.kanji).toSet().length, words.length);
    for (final word in words) {
      final sentence = exampleSentenceFor(word.kanji);
      expect(sentence.japanese, contains(word.kanji));
      expect(sentence.hiragana, contains(word.hiragana));
      expect(
        sentence.romaji.replaceAll('.', '').split(' '),
        contains(word.romaji),
      );
      expect(sentence.chinese, isNotEmpty);
      expect(sentence.hiragana, endsWith('。'));
      expect(sentence.japanese, endsWith('。'));
    }
  });

  test('kanji and katakana in each sentence come from the vocabulary', () {
    final known = byKanji.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final word in words) {
      var rest = exampleSentenceFor(word.kanji).japanese;
      while (rest.isNotEmpty) {
        final match = known.cast<String?>().firstWhere(
          (kanji) => rest.startsWith(kanji!),
          orElse: () => null,
        );
        if (match != null) {
          rest = rest.substring(match.length);
          continue;
        }
        final char = rest.substring(0, 1);
        final isGrammar = RegExp(r'^[ぁ-ん。]$').hasMatch(char);
        expect(isGrammar, isTrue, reason: '${word.kanji}: leftover $rest');
        rest = rest.substring(1);
      }
    }
  });
}
