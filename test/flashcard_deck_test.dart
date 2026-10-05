import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yin_japanese_coach/favorite_flashcard_page.dart';
import 'package:yin_japanese_coach/main.dart';
import 'package:yin_japanese_coach/vocabulary_data.dart';

Finder _directionButton(String section, String label) {
  return find.descendant(
    of: find.byKey(Key(section)),
    matching: find.widgetWithText(ElevatedButton, label),
  );
}

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
    expect(find.text('日→中單字'), findsNWidgets(4));
    expect(find.text('中→日單字'), findsNWidgets(4));

    await tester.tap(_directionButton('名詞', '日→中單字'));
    await tester.pumpAndSettle();
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('会う'), findsNothing);
  });

  testWidgets('日→中單字 keeps the Japanese word and the current answer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    words
      ..clear()
      ..add(
        Vocabulary(
          kanji: '学校',
          hiragana: 'がっこう',
          romaji: 'gakkou',
          meaning: '學校',
          wordType: '🔵 名詞',
        ),
      );

    await tester.pumpWidget(const MaterialApp(home: FlashcardMenuPage()));
    await tester.pumpAndSettle();
    await tester.tap(_directionButton('名詞', '日→中單字'));
    await tester.pumpAndSettle();
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('學校'), findsNothing);
    expect(find.text('Word 1 / 1'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    expect(find.text('学校'), findsWidgets);
    expect(find.text('がっこう'), findsOneWidget);
    expect(find.text('gakkou'), findsOneWidget);
    expect(find.text('詞性：🔵 名詞'), findsOneWidget);
    expect(find.text('學校'), findsOneWidget);
    expect(find.text('繼續'), findsOneWidget);
    expect(find.text('例句'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsWidgets);
    expect(find.text('O'), findsNothing);
    expect(find.text('X'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('中→日單字 shows Chinese and 繼續 after 答案', (tester) async {
    SharedPreferences.setMockInitialValues({});
    words
      ..clear()
      ..add(
        Vocabulary(
          kanji: '学校',
          hiragana: 'がっこう',
          romaji: 'gakkou',
          meaning: '學校',
          wordType: '🔵 名詞',
        ),
      );

    await tester.pumpWidget(const MaterialApp(home: FlashcardMenuPage()));
    await tester.pumpAndSettle();
    await tester.tap(_directionButton('名詞', '中→日單字'));
    await tester.pumpAndSettle();
    expect(find.text('學校'), findsOneWidget);
    expect(find.text('学校'), findsNothing);
    expect(find.text('(1 of 1)'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('がっこう'), findsOneWidget);
    expect(find.text('gakkou'), findsOneWidget);
    expect(find.text('詞性：🔵 名詞'), findsOneWidget);
    expect(find.text('學校'), findsWidgets);
    expect(find.text('繼續'), findsOneWidget);
    expect(find.text('例句'), findsOneWidget);
    expect(find.text('O'), findsNothing);
    expect(find.text('X'), findsNothing);
    expect(find.byIcon(Icons.star_border).hitTestable(), findsOneWidget);

    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(find.text('學校'), findsOneWidget);
    expect(find.text('学校'), findsNothing);
    expect(find.text('答案'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('日→中 star saves the word in 日→中收藏 only', (tester) async {
    SharedPreferences.setMockInitialValues({});
    words
      ..clear()
      ..add(
        Vocabulary(
          kanji: '学校',
          hiragana: 'がっこう',
          romaji: 'gakkou',
          meaning: '學校',
          wordType: '🔵 名詞',
        ),
      );

    await tester.pumpWidget(const MaterialApp(home: FlashcardMenuPage()));
    await tester.pumpAndSettle();
    await tester.tap(_directionButton('名詞', '日→中單字'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();
    expect(words.single.isFavorite, isTrue);
    expect(words.single.isZhJaFavorite, isFalse);

    await tester.pumpWidget(
      const MaterialApp(
        key: ValueKey('favorites'),
        home: FavoriteWordsMenuPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('日→中單字(1)'), findsOneWidget);
    expect(find.text('中→日單字(0)'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, '日→中單字(1)'));
    await tester.pumpAndSettle();
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('學校'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, '中→日單字(0)'));
    await tester.pumpAndSettle();
    expect(find.text('No favorite words yet.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('中→日 stars save and remove the word in 中→日收藏', (tester) async {
    SharedPreferences.setMockInitialValues({});
    words
      ..clear()
      ..add(
        Vocabulary(
          kanji: '学校',
          hiragana: 'がっこう',
          romaji: 'gakkou',
          meaning: '學校',
          wordType: '🔵 名詞',
        ),
      );

    await tester.pumpWidget(const MaterialApp(home: FlashcardMenuPage()));
    await tester.pumpAndSettle();
    await tester.tap(_directionButton('名詞', '中→日單字'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();
    expect(words.single.isZhJaFavorite, isTrue);
    expect(words.single.isFavorite, isFalse);

    await tester.tap(find.byIcon(Icons.star));
    await tester.pump();
    expect(words.single.isZhJaFavorite, isFalse);

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();
    await tester.tap(find.text('答案'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.star).hitTestable());
    await tester.pump();
    expect(words.single.isZhJaFavorite, isFalse);
    expect(words.single.isFavorite, isFalse);

    await tester.tap(find.byIcon(Icons.star_border).hitTestable());
    await tester.pump();
    expect(words.single.isZhJaFavorite, isTrue);

    await tester.pumpWidget(
      const MaterialApp(
        key: ValueKey('favorites'),
        home: FavoriteWordsMenuPage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, '中→日單字(1)'));
    await tester.pumpAndSettle();
    expect(find.text('學校'), findsOneWidget);
    expect(find.text('学校'), findsNothing);

    await tester.tap(find.text('答案'));
    await tester.pump();
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('繼續'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  test('全部 includes every word once', () {
    final deck = allWordsShuffled();

    expect(deck.length, words.length);
    expect(
      deck.map((word) => word.kanji).toList()..sort(),
      words.map((word) => word.kanji).toList()..sort(),
    );
  });

  testWidgets('收藏單字 answer star waits for 繼續', (tester) async {
    SharedPreferences.setMockInitialValues({});
    words
      ..clear()
      ..add(
        Vocabulary(
          kanji: '会う',
          hiragana: 'あう',
          romaji: 'au',
          meaning: '見面',
          wordType: '🟢 動詞',
          isFavorite: true,
        ),
      );

    await tester.pumpWidget(const MaterialApp(home: FavoriteFlashcardPage()));
    await tester.pump();
    await tester.tap(find.text('答案'));
    await tester.pump();

    final kanjiTop = tester.getTopLeft(find.text('会う')).dy;
    final readingTop = tester.getTopLeft(find.text('あう')).dy;
    final starTop = tester.getTopLeft(find.byIcon(Icons.star)).dy;
    expect(starTop, greaterThan(kanjiTop));
    expect(starTop, lessThan(readingTop));

    await tester.tap(find.byIcon(Icons.star));
    await tester.pump();
    expect(find.text('No favorite words yet.'), findsNothing);
    expect(find.text('会う'), findsOneWidget);
    expect(find.text('見面'), findsOneWidget);
    expect(words.single.isFavorite, isTrue);
    expect(
      tester.getTopLeft(find.byIcon(Icons.star_border)).dy,
      greaterThan(kanjiTop),
    );
    expect(
      tester.getTopLeft(find.byIcon(Icons.star_border)).dy,
      lessThan(tester.getTopLeft(find.text('あう')).dy),
    );

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(words.single.isFavorite, isTrue);

    await tester.tap(find.byIcon(Icons.star));
    await tester.pump();
    expect(find.byIcon(Icons.star_border), findsOneWidget);

    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(find.text('No favorite words yet.'), findsOneWidget);
    expect(words.single.isFavorite, isFalse);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('收藏單字 front star removes immediately', (tester) async {
    SharedPreferences.setMockInitialValues({});
    words
      ..clear()
      ..add(
        Vocabulary(
          kanji: '会う',
          hiragana: 'あう',
          romaji: 'au',
          meaning: '見面',
          wordType: '🟢 動詞',
          isFavorite: true,
        ),
      );

    await tester.pumpWidget(const MaterialApp(home: FavoriteFlashcardPage()));
    await tester.pump();
    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pump();
    expect(find.text('No favorite words yet.'), findsOneWidget);
    expect(words.single.isFavorite, isFalse);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('收藏單字 繼續 removes only the marked saved word', (tester) async {
    SharedPreferences.setMockInitialValues({});
    words
      ..clear()
      ..addAll([
        Vocabulary(
          kanji: '会う',
          hiragana: 'あう',
          romaji: 'au',
          meaning: '見面',
          wordType: '🟢 動詞',
          isFavorite: true,
        ),
        Vocabulary(
          kanji: '開ける',
          hiragana: 'あける',
          romaji: 'akeru',
          meaning: '打開',
          wordType: '🟢 動詞',
          isFavorite: true,
        ),
      ]);

    await tester.pumpWidget(const MaterialApp(home: FavoriteFlashcardPage()));
    await tester.pump();
    expect(find.text('会う'), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.star));
    await tester.pump();
    expect(words.every((word) => word.isFavorite), isTrue);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.text('見面'), findsOneWidget);

    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(words.first.isFavorite, isFalse);
    expect(words.last.isFavorite, isTrue);
    expect(find.text('会う'), findsNothing);
    expect(find.text('開ける'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('中→日 播放收藏單字 shows Chinese then Japanese', (tester) async {
    SharedPreferences.setMockInitialValues({});
    words
      ..clear()
      ..add(
        Vocabulary(
          kanji: '学校',
          hiragana: 'がっこう',
          romaji: 'gakkou',
          meaning: '學校',
          wordType: '🔵 名詞',
          isZhJaFavorite: true,
        ),
      );

    await tester.pumpWidget(
      const MaterialApp(
        home: FavoriteFlashcardPage(chineseToJapanese: true),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('播放收藏單字'));
    await tester.pump();
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('學校'), findsOneWidget);
    expect(find.text('学校'), findsNothing);

    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('學校'), findsNothing);
    expect(find.text('Stop'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await tester.pump(const Duration(seconds: 8));
  });

  testWidgets('日→中 播放收藏單字 still shows Japanese first', (tester) async {
    SharedPreferences.setMockInitialValues({});
    words
      ..clear()
      ..add(
        Vocabulary(
          kanji: '学校',
          hiragana: 'がっこう',
          romaji: 'gakkou',
          meaning: '學校',
          wordType: '🔵 名詞',
          isFavorite: true,
        ),
      );

    await tester.pumpWidget(const MaterialApp(home: FavoriteFlashcardPage()));
    await tester.pump();
    await tester.tap(find.text('播放收藏單字'));
    await tester.pump();
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('學校'), findsNothing);

    await tester.tap(find.text('Stop'));
    await tester.pump(const Duration(seconds: 8));
  });
}
