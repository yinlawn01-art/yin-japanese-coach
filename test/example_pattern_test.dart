import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yin_japanese_coach/example_pattern_page.dart';
import 'package:yin_japanese_coach/example_patterns.dart';
import 'package:yin_japanese_coach/favorite_example_page.dart';
import 'package:yin_japanese_coach/main.dart';
import 'package:yin_japanese_coach/romaji_speech.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    examplePatterns.clear();
    exampleFavorites.clear();
  });

  testWidgets('ten pattern files combine into 全部 in order', (tester) async {
    late Set<String> vocabKanji;
    await tester.runAsync(() async {
      await loadExamplePatterns();
      vocabKanji = await _vocabularyKanji();
    });

    expect(examplePatterns, hasLength(11));
    for (var i = 0; i < 10; i++) {
      expect(examplePatterns[i].sentences, hasLength(10));
    }

    final all = examplePatterns.last;
    expect(all.label, '(11) 全部');
    expect(all.sentences, hasLength(100));
    expect(all.sentences.map((sentence) => sentence.japanese).toList(), [
      for (final pattern in examplePatterns.take(10))
        for (final sentence in pattern.sentences) sentence.japanese,
    ]);
    expect(
      all.sentences.sublist(90).map((sentence) => sentence.japanese).toList(),
      examplePatterns[9].sentences
          .map((sentence) => sentence.japanese)
          .toList(),
    );
    expect(
      all.sentences.map((sentence) => sentence.japanese).toSet(),
      hasLength(100),
    );

    final outside = <String>{};
    for (final sentence in all.sentences) {
      expect(sentence.hiragana, isNotEmpty);
      expect(sentence.romaji, isNotEmpty);
      expect(sentence.chinese, isNotEmpty);
      expect(sentence.romaji, isNot(contains(RegExp(r'(^|\s)wo(\s|\.|$)'))));
      final spoken = pronunciationForRomaji(sentence.romaji)
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll('。', '');
      expect(spoken, isNot(contains(RegExp(r'[A-Za-z]'))));
      expect(spoken, _spokenReading(sentence.hiragana, sentence.romaji));
      outside.addAll(
        sentence.japanese.runes
            .where((rune) => rune >= 0x4E00 && rune <= 0x9FFF)
            .map(String.fromCharCode)
            .where((kanji) => !vocabKanji.contains(kanji)),
      );
    }
    expect(outside, {'勉', '強', '料', '理', '掃', '除'});
  });

  testWidgets('例句 buttons fit an iPhone 15 Pro Max', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(loadExamplePatterns);
    await tester.pumpWidget(const MaterialApp(home: ExamplePatternMenuPage()));
    await tester.pumpAndSettle();

    final first = find.widgetWithText(
      ElevatedButton,
      '(1)～は～です : A是B (10)',
    );
    final last = find.widgetWithText(ElevatedButton, '(11) 全部 (100)');
    expect(tester.getSize(first).height, closeTo(64 * 0.9, 0.2));
    expect(tester.getSize(last).height, closeTo(64 * 0.9, 0.2));
    expect(
      tester.widget<Text>(find.text('(1)～は～です : A是B (10)')).style?.fontSize,
      closeTo(22 * 0.9, 0.1),
    );
    expect(tester.getTopLeft(first).dy, greaterThanOrEqualTo(56));
    expect(tester.getBottomLeft(last).dy, lessThanOrEqualTo(932));
    expect(find.text('(7)～ません : 不～ (10)'), findsOneWidget);
  });

  testWidgets('例句 shows each pattern and reads the next sentence', (
    tester,
  ) async {
    await tester.runAsync(loadExamplePatterns);
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('例句(100)'));
    await tester.tap(find.text('例句(100)'));
    await tester.pumpAndSettle();

    expect(find.text('(1)～は～です : A是B (10)'), findsOneWidget);
    expect(find.text('(7)～ません : 不～ (10)'), findsOneWidget);
    expect(find.text('(10)～てください : 請～ (10)'), findsOneWidget);
    expect(find.text('(11) 全部 (100)'), findsOneWidget);

    await tester.tap(find.text('(1)～は～です : A是B (10)'));
    await tester.pumpAndSettle();
    expect(find.text('父は先生です。'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);

    await tester.tap(find.byTooltip('收藏例句'));
    await tester.pumpAndSettle();
    expect(exampleFavorites, contains('父は先生です。'));
    expect(find.byIcon(Icons.star), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    expect(find.text('ちちはせんせいです。'), findsOneWidget);
    expect(find.text('chichi wa sensei desu.'), findsOneWidget);
    expect(find.text('父親是老師。'), findsOneWidget);
    expect(find.text('繼續'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byIcon(Icons.star)).dy,
      lessThan(tester.getTopLeft(find.text('父は先生です。')).dy),
    );

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pump();
    expect(exampleFavorites, contains('父は先生です。'));
    expect(find.text('父は先生です。'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byIcon(Icons.star_border)).dy,
      lessThan(tester.getTopLeft(find.text('父は先生です。')).dy),
    );

    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(exampleFavorites, isNot(contains('父は先生です。')));
    expect(find.text('母は看護師です。'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('tapping the sentence, kana, or romaji reads the Japanese', (
    tester,
  ) async {
    await tester.runAsync(loadExamplePatterns);
    await tester.pumpWidget(
      MaterialApp(
        home: ExamplePatternStudyPage(pattern: examplePatterns.first),
      ),
    );
    await tester.pumpAndSettle();

    expect(_readsOnTap(tester, '父は先生です。'), isTrue);
    await tester.tap(find.text('父は先生です。'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('答案'), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    expect(_readsOnTap(tester, '父は先生です。'), isTrue);
    expect(_readsOnTap(tester, 'ちちはせんせいです。'), isTrue);
    expect(_readsOnTap(tester, 'chichi wa sensei desu.'), isTrue);
    expect(_readsOnTap(tester, '父親是老師。'), isFalse);

    await tester.tap(find.text('ちちはせんせいです。'));
    await tester.pump();
    await tester.tap(find.text('chichi wa sensei desu.'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('父は先生です。'), findsOneWidget);
    expect(find.text('繼續'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('收藏例句 reviews a starred sentence and removes it', (tester) async {
    await tester.runAsync(loadExamplePatterns);
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('例句(100)'));
    await tester.tap(find.text('例句(100)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('(1)～は～です : A是B (10)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('收藏例句'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('例句(100)'), findsOneWidget);
    expect(find.text('收藏例句(1)'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('收藏例句(1)')).dy,
      greaterThan(tester.getTopLeft(find.text('例句(100)')).dy),
    );

    await tester.ensureVisible(find.text('收藏例句(1)'));
    await tester.tap(find.text('收藏例句(1)'));
    await tester.pumpAndSettle();
    expect(find.text('父は先生です。'), findsOneWidget);
    expect(find.text('播放收藏例句'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    expect(find.text('ちちはせんせいです。'), findsOneWidget);
    expect(find.text('chichi wa sensei desu.'), findsOneWidget);
    expect(find.text('父親是老師。'), findsOneWidget);
    expect(find.text('繼續'), findsOneWidget);
    expect(_readsOnTap(tester, '父は先生です。'), isTrue);
    expect(_readsOnTap(tester, 'ちちはせんせいです。'), isTrue);
    expect(_readsOnTap(tester, 'chichi wa sensei desu.'), isTrue);
    expect(_readsOnTap(tester, '父親是老師。'), isFalse);
    await tester.tap(find.text('chichi wa sensei desu.'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.byIcon(Icons.star)).dy,
      greaterThan(tester.getTopLeft(find.text('父は先生です。')).dy),
    );

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pump();
    expect(find.text('還沒有收藏例句。'), findsNothing);
    expect(find.text('父は先生です。'), findsOneWidget);
    expect(exampleFavorites, contains('父は先生です。'));
    expect(
      tester.getTopLeft(find.byIcon(Icons.star_border)).dy,
      greaterThan(tester.getTopLeft(find.text('父は先生です。')).dy),
    );

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(exampleFavorites, contains('父は先生です。'));

    await tester.tap(find.byIcon(Icons.star));
    await tester.pump();
    expect(find.byIcon(Icons.star_border), findsOneWidget);

    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(find.text('還沒有收藏例句。'), findsOneWidget);
    expect(exampleFavorites, isEmpty);

    await tester.pump(const Duration(seconds: 2));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('例句(100)'), findsOneWidget);
    expect(find.text('收藏例句(0)'), findsOneWidget);
  });

  testWidgets('收藏例句 continues to another saved sentence', (tester) async {
    await tester.runAsync(() async {
      await loadExamplePatterns();
      exampleFavorites
        ..clear()
        ..addAll(['父は先生です。', '母は看護師です。']);
      await saveExampleFavorites();
    });

    await tester.pumpWidget(const MaterialApp(home: FavoriteExamplePage()));
    await tester.pumpAndSettle();
    expect(find.text('父は先生です。'), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(find.text('答案'), findsOneWidget);
    expect(find.text('母は看護師です。'), findsOneWidget);
    expect(find.text('父は先生です。'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('收藏例句 front star removes immediately', (tester) async {
    await tester.runAsync(() async {
      await loadExamplePatterns();
      exampleFavorites
        ..clear()
        ..add('父は先生です。');
      await saveExampleFavorites();
    });

    await tester.pumpWidget(const MaterialApp(home: FavoriteExamplePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pump();
    expect(find.text('還沒有收藏例句。'), findsOneWidget);
    expect(exampleFavorites, isEmpty);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('繼續 removes only the marked saved sentence', (tester) async {
    await tester.runAsync(() async {
      await loadExamplePatterns();
      exampleFavorites
        ..clear()
        ..addAll(['父は先生です。', '母は看護師です。']);
      await saveExampleFavorites();
    });

    await tester.pumpWidget(const MaterialApp(home: FavoriteExamplePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('答案'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.star));
    await tester.pump();
    expect(exampleFavorites, containsAll(['父は先生です。', '母は看護師です。']));
    expect(find.byIcon(Icons.star_border), findsOneWidget);

    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(exampleFavorites, hasLength(1));
    expect(exampleFavorites, contains('母は看護師です。'));
    expect(find.text('母は看護師です。'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);
    expect(find.text('父は先生です。'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
  });
}

bool _readsOnTap(WidgetTester tester, String text) {
  var found = false;
  tester.element(find.text(text)).visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is GestureDetector && widget.onTap != null) {
      found = true;
      return false;
    }
    if (widget is Scrollable) return false;
    return true;
  });
  return found;
}

Future<Set<String>> _vocabularyKanji() async {
  const paths = [
    'assets/n5_verbs.json',
    'assets/n5_nouns.json',
    'assets/n5_adjectives.json',
    'assets/n5_adverbs.json',
  ];
  final kanji = <String>{};
  for (final path in paths) {
    final data = json.decode(await rootBundle.loadString(path)) as List;
    for (final item in data) {
      final word = (item as Map<String, dynamic>)['kanji'] as String;
      kanji.addAll(
        word.runes
            .where((rune) => rune >= 0x4E00 && rune <= 0x9FFF)
            .map(String.fromCharCode),
      );
    }
  }
  return kanji;
}

String _spokenReading(String hiragana, String romaji) {
  final katakanaToHiragana = String.fromCharCodes(
    hiragana.runes.map((rune) {
      if (rune >= 0x30A1 && rune <= 0x30F6) return rune - 0x60;
      return rune;
    }),
  ).replaceAll('。', '');
  final hasWa = RegExp(r'(^|\s)wa(\s|\.|$)').hasMatch(romaji);
  var text = katakanaToHiragana;
  if (hasWa) {
    final index = text.lastIndexOf('は');
    if (index >= 0) {
      text = text.replaceRange(index, index + 1, 'わ');
    }
  }
  return text.replaceAll('を', 'お');
}
