import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  testWidgets('單字 buttons show how many words are in each section', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();
    final wordsButton = find.text('單字(5)');
    expect(wordsButton, findsOneWidget);
    await tester.ensureVisible(wordsButton);
    await tester.tap(wordsButton);
    await tester.pumpAndSettle();
    expect(find.text('名詞(2)'), findsOneWidget);
    expect(find.text('動詞(2)'), findsOneWidget);
    expect(find.text('形容詞(1)'), findsOneWidget);
    expect(find.text('全部(5)'), findsOneWidget);

    await tester.tap(find.text('名詞(2)'));
    await tester.pumpAndSettle();
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('会う'), findsNothing);
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
