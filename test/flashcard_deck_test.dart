import 'package:flutter_test/flutter_test.dart';
import 'package:yin_japanese_coach/main.dart';
import 'package:yin_japanese_coach/vocabulary_data.dart';

Vocabulary sample(String kanji, String wordType) {
  return Vocabulary(
    kanji: kanji,
    hiragana: kanji,
    romaji: kanji,
    meaning: kanji,
    wordType: wordType,
  );
}

void main() {
  setUp(() {
    words
      ..clear()
      ..addAll([
        sample('会う', '🟢 動詞'),
        sample('学校', '🔵 名詞'),
        sample('開ける', '🟢 動詞'),
        sample('大きい', '🟣 形容詞'),
        sample('先生', '🔵 名詞'),
      ]);
  });

  tearDown(words.clear);

  test('each part of speech keeps the json order', () {
    expect(wordsOfType('動詞').map((word) => word.kanji), ['会う', '開ける']);
    expect(wordsOfType('名詞').map((word) => word.kanji), ['学校', '先生']);
    expect(wordsOfType('形容詞').map((word) => word.kanji), ['大きい']);
  });

  test('全部 includes every word once', () {
    final deck = allWordsShuffled();

    expect(deck.length, words.length);
    expect(
      deck.map((word) => word.kanji).toList()..sort(),
      words.map((word) => word.kanji).toList()..sort(),
    );
  });
}
