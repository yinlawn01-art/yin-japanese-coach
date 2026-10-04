import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yin_japanese_coach/example_patterns.dart';
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

  testWidgets('例句 shows each pattern and reads the next sentence', (
    tester,
  ) async {
    await tester.runAsync(loadExamplePatterns);
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('例句'));
    await tester.tap(find.text('例句'));
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
}

Future<Set<String>> _vocabularyKanji() async {
  const paths = [
    'assets/n5_verbs.json',
    'assets/n5_nouns.json',
    'assets/n5_adjectives.json',
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
