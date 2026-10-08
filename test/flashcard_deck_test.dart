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
    expect(find.text('副詞(0)'), findsOneWidget);
    expect(find.text('其他(0)'), findsOneWidget);
    expect(find.text('全部(5)'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('其他(0)')).dy,
      greaterThan(tester.getTopLeft(find.text('副詞(0)')).dy),
    );
    expect(
      tester.getTopLeft(find.text('全部(5)')).dy,
      greaterThan(tester.getTopLeft(find.text('其他(0)')).dy),
    );
    expect(find.text('日→中單字'), findsNWidgets(6));
    expect(find.text('中→日單字'), findsNWidgets(6));

    await tester.tap(_directionButton('名詞', '日→中單字'));
    await tester.pumpAndSettle();
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('会う'), findsNothing);
  });

  testWidgets('單字 sections fit on one phone page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    Future<void> expectFit(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
      await tester.pumpWidget(const MaterialApp(home: FlashcardMenuPage()));
      await tester.pumpAndSettle();
      final first = tester.getTopLeft(find.text('名詞(2)')).dy;
      final last = tester.getBottomLeft(
        _directionButton('全部', '中→日單字'),
      ).dy;
      expect(first, greaterThanOrEqualTo(47));
      expect(last, lessThanOrEqualTo(size.height - 34));
      expect(find.text('其他(0)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await expectFit(const Size(390, 844));
    await expectFit(const Size(375, 667));
    await expectFit(const Size(430, 932));
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
    expect(find.text('gakkou'), findsNothing);
    expect(find.text('學校'), findsNothing);
    expect(find.text('Word 1 / 1'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    expect(find.text('学校'), findsWidgets);
    expect(find.text('がっこう'), findsOneWidget);
    expect(find.text('gakkou'), findsOneWidget);
    expect(tester.widget<Text>(find.text('gakkou')).style?.fontSize, 48);
    expect(tester.widget<Text>(find.text('gakkou')).style?.color, Colors.red);
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
    expect(find.text('gakkou'), findsNothing);
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

  testWidgets('清除 empties only the saved list beside it', (tester) async {
    SharedPreferences.setMockInitialValues({
      'favorites': ['学校'],
      'zhJaFavorites': ['学校'],
    });
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
          isZhJaFavorite: true,
        ),
      );

    await tester.pumpWidget(const MaterialApp(home: FavoriteWordsMenuPage()));
    await tester.pumpAndSettle();

    final ja = find.text('日→中單字(1)');
    final zh = find.text('中→日單字(1)');
    final clearJa = find.byKey(const Key('clear-ja-favorites'));
    final clearZh = find.byKey(const Key('clear-zh-favorites'));
    expect(ja, findsOneWidget);
    expect(zh, findsOneWidget);
    expect(find.text('清除'), findsNWidgets(2));
    expect(tester.getCenter(clearJa).dy, closeTo(tester.getCenter(ja).dy, 1));
    expect(
      tester.getTopLeft(clearJa).dx,
      greaterThan(tester.getTopRight(ja).dx),
    );
    expect(tester.getCenter(clearZh).dy, closeTo(tester.getCenter(zh).dy, 1));
    expect(
      tester.getTopLeft(clearZh).dx,
      greaterThan(tester.getTopRight(zh).dx),
    );

    final jaShape = tester
        .widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '日→中單字(1)'),
        )
        .style
        ?.shape
        ?.resolve(const <WidgetState>{});
    final jaRadius =
        (jaShape! as RoundedRectangleBorder).borderRadius.resolve(
          TextDirection.ltr,
        );
    expect(jaRadius.topLeft.x, 32);
    expect(jaRadius.topRight.x, 0);

    await tester.tap(clearJa);
    await tester.pumpAndSettle();
    expect(find.text('日→中單字(0)'), findsOneWidget);
    expect(find.text('中→日單字(1)'), findsOneWidget);
    expect(words.single.isFavorite, isFalse);
    expect(words.single.isZhJaFavorite, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorites'), isEmpty);
    expect(prefs.getStringList('zhJaFavorites'), ['学校']);

    await tester.tap(clearZh);
    await tester.pumpAndSettle();
    expect(find.text('中→日單字(0)'), findsOneWidget);
    expect(words.single.isZhJaFavorite, isFalse);
    expect((await SharedPreferences.getInstance()).getStringList('zhJaFavorites'), isEmpty);

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

  testWidgets('中→日 播放收藏單字 shows Chinese then reads Japanese twice', (
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

    await tester.pump(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('学校'), findsOneWidget);
    expect(find.text('學校'), findsNothing);

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

  testWidgets('跳過50 jumps 50 words and wraps to the first', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Vocabulary school() {
      return Vocabulary(
        kanji: '学校',
        hiragana: 'がっこう',
        romaji: 'gakkou',
        meaning: '學校',
        wordType: '🔵 名詞',
      );
    }

    void expectSkipBeside(String count) {
      final countRect = tester.getRect(find.text(count).hitTestable());
      final buttonRect = tester.getRect(
        find.widgetWithText(ElevatedButton, '跳過50').hitTestable(),
      );
      expect(buttonRect.left, greaterThan(countRect.right));
      expect(buttonRect.center.dy, closeTo(countRect.center.dy, 12));
    }

    await tester.pumpWidget(
      MaterialApp(home: FlashcardPage(deck: List.generate(60, (_) => school()))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Word 1 / 60'), findsOneWidget);
    expectSkipBeside('Word 1 / 60');

    await tester.tap(find.widgetWithText(ElevatedButton, '跳過50'));
    await tester.pump();
    expect(find.text('Word 51 / 60'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, '跳過50'));
    await tester.pump();
    expect(find.text('Word 1 / 60'), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    expect(find.text('繼續'), findsOneWidget);
    expectSkipBeside('Word 1 / 60');
    await tester.tap(find.widgetWithText(ElevatedButton, '跳過50').hitTestable());
    await tester.pump();
    expect(find.text('Word 51 / 60'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);
    expect(find.text('繼續'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('exact-skip'),
        home: FlashcardPage(deck: List.generate(51, (_) => school())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, '跳過50'));
    await tester.pump();
    expect(find.text('Word 51 / 51'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('zh-skip'),
        home: FlashcardPage(
          deck: List.generate(3, (_) => school()),
          chineseToJapanese: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('(1 of 3)'), findsOneWidget);
    expectSkipBeside('(1 of 3)');
    await tester.tap(find.widgetWithText(ElevatedButton, '跳過50'));
    await tester.pump();
    expect(find.text('(1 of 3)'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
}
