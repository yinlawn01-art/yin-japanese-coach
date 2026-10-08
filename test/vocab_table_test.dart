import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yin_japanese_coach/main.dart';
import 'package:yin_japanese_coach/vocab_table_page.dart';
import 'package:yin_japanese_coach/vocabulary_data.dart';

Vocabulary _word({
  required String kanji,
  required String hiragana,
  required String romaji,
  required String meaning,
  required String wordType,
}) {
  return Vocabulary(
    kanji: kanji,
    hiragana: hiragana,
    romaji: romaji,
    meaning: meaning,
    wordType: wordType,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    words
      ..clear()
      ..addAll([
        _word(
          kanji: '学校',
          hiragana: 'がっこう',
          romaji: 'gakkou',
          meaning: '學校',
          wordType: '🔵 名詞',
        ),
        _word(
          kanji: '先生',
          hiragana: 'せんせい',
          romaji: 'sensei',
          meaning: '老師',
          wordType: '🔵 名詞',
        ),
        _word(
          kanji: '会う',
          hiragana: 'あう',
          romaji: 'au',
          meaning: '見面',
          wordType: '🟢 動詞',
        ),
        _word(
          kanji: '大きい',
          hiragana: 'おおきい',
          romaji: 'ookii',
          meaning: '大的',
          wordType: '🟣 形容詞',
        ),
        _word(
          kanji: 'とても',
          hiragana: 'とても',
          romaji: 'totemo',
          meaning: '非常',
          wordType: '◆ 副詞',
        ),
      ]);
  });

  tearDown(words.clear);

  testWidgets('單字表 lists each part of speech and numbers that list', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('收藏單字 (0)')).dy,
      greaterThan(tester.getTopLeft(find.text('單字(${words.length})')).dy),
    );
    expect(
      tester.getTopLeft(find.text('單字表')).dy,
      greaterThan(tester.getTopLeft(find.textContaining('收藏例句')).dy),
    );

    await tester.ensureVisible(find.text('單字表'));
    await tester.tap(find.text('單字表'));
    await tester.pumpAndSettle();
    expect(find.text('名詞(2)'), findsOneWidget);
    expect(find.text('動詞(1)'), findsOneWidget);
    expect(find.text('形容詞(1)'), findsOneWidget);
    expect(find.text('副詞(1)'), findsOneWidget);

    await tester.tap(find.text('名詞(2)'));
    await tester.pumpAndSettle();
    for (final header in vocabTableHeaders) {
      expect(find.text(header), findsOneWidget);
    }
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('ja-0'))).data, '学校');
    expect(tester.widget<Text>(find.byKey(const Key('romaji-0'))).data, 'gakkou');
    expect(tester.widget<Text>(find.byKey(const Key('kana-0'))).data, 'がっこう');
    expect(tester.widget<Text>(find.byKey(const Key('zh-0'))).data, '學校');
    expect(tester.widget<Text>(find.byKey(const Key('ja-1'))).data, '先生');
  });

  testWidgets('日文 saves 日→中 and 中文 saves 中→日, each bold and yellow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VocabTablePage(title: '名詞', deck: wordsOfType('名詞')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ja-0')));
    await tester.pump();
    expect(words[0].isFavorite, isTrue);
    expect(words[0].isZhJaFavorite, isFalse);
    expect(words[1].isFavorite, isFalse);
    expect(
      tester.widget<Text>(find.byKey(const Key('ja-0'))).style?.color,
      vocabTableSaved,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('ja-0'))).style?.fontWeight,
      FontWeight.bold,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('zh-0'))).style?.color,
      isNot(vocabTableSaved),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('zh-0'))).style?.fontWeight,
      FontWeight.normal,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('kana-0'))).style?.color,
      isNot(vocabTableSaved),
    );

    await tester.tap(find.byKey(const Key('zh-0')));
    await tester.pump();
    expect(words[0].isFavorite, isTrue);
    expect(words[0].isZhJaFavorite, isTrue);
    expect(
      tester.widget<Text>(find.byKey(const Key('ja-0'))).style?.color,
      vocabTableSaved,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('zh-0'))).style?.color,
      vocabTableSaved,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('zh-0'))).style?.fontWeight,
      FontWeight.bold,
    );

    await tester.tap(find.byKey(const Key('ja-0')));
    await tester.pump();
    expect(words[0].isFavorite, isFalse);
    expect(words[0].isZhJaFavorite, isTrue);
    expect(
      tester.widget<Text>(find.byKey(const Key('ja-0'))).style?.color,
      isNot(vocabTableSaved),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('ja-0'))).style?.fontWeight,
      FontWeight.normal,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('zh-0'))).style?.color,
      vocabTableSaved,
    );

    await tester.tap(find.byKey(const Key('zh-1')));
    await tester.pump();
    expect(words[1].isFavorite, isFalse);
    expect(words[1].isZhJaFavorite, isTrue);
    expect(
      tester.widget<Text>(find.byKey(const Key('zh-1'))).style?.color,
      vocabTableSaved,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('zh-1'))).style?.fontWeight,
      FontWeight.bold,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('ja-1'))).style?.color,
      isNot(vocabTableSaved),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('ja-1'))).style?.fontWeight,
      FontWeight.normal,
    );

    await tester.tap(find.byKey(const Key('kana-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('romaji-1')));
    await tester.pump();
    expect(words[1].isFavorite, isFalse);
    expect(words[1].isZhJaFavorite, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('field names stay put while the word list scrolls', (tester) async {
    final deck = [
      for (var i = 0; i < 40; i++)
        _word(
          kanji: '語$i',
          hiragana: 'ご',
          romaji: 'go',
          meaning: '意思$i',
          wordType: '🔵 名詞',
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(home: VocabTablePage(title: '名詞', deck: deck)),
    );
    await tester.pumpAndSettle();
    final headerTop = tester.getTopLeft(find.text('日文')).dy;
    expect(find.text('語39'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -2400));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('日文')).dy, headerTop);
    expect(find.text('羅馬拚音'), findsOneWidget);
    expect(find.text('語0'), findsNothing);
    expect(find.text('語39'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
