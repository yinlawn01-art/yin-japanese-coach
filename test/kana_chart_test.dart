import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yin_japanese_coach/app_version.dart';
import 'package:yin_japanese_coach/kana_data.dart';
import 'package:yin_japanese_coach/kana_page.dart';
import 'package:yin_japanese_coach/main.dart';
import 'package:yin_japanese_coach/romaji_speech.dart';
import 'package:yin_japanese_coach/vocabulary_data.dart';

String _spoken(String romaji) {
  return pronunciationForRomaji(romaji).replaceAll(' ', '');
}

String _asHiragana(String text) {
  return String.fromCharCodes(
    text.runes.map((rune) {
      if (rune >= 0x30A1 && rune <= 0x30F6) return rune - 0x60;
      return rune;
    }),
  );
}

String _vowelOf(String kana) {
  const vowels = {
    'あ': 'あかさたなはまやらわがざだばぱゃ',
    'い': 'いきしちにひみりぎじぢびぴ',
    'う': 'うくすつぬふむゆるぐずづぶぷゅ',
    'え': 'えけせてねへめれげぜでべぺ',
    'お': 'おこそとのほもよろをごぞどぼぽょを',
  };
  for (final entry in vowels.entries) {
    if (entry.value.contains(kana)) return entry.key;
  }
  return kana;
}

/// Long-vowel mark ー is spoken as another vowel, which is how romaji reads it.
String _expandChoon(String hiragana) {
  final buffer = StringBuffer();
  for (final rune in hiragana.runes) {
    final char = String.fromCharCode(rune);
    if (char == 'ー' && buffer.isNotEmpty) {
      buffer.write(_vowelOf(String.fromCharCode(buffer.toString().runes.last)));
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

void main() {
  test('homepage version matches the pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([0-9.]+)\+',
      multiLine: true,
    ).firstMatch(pubspec);
    final published = match?.group(1);
    var shown = published;
    while (shown != null && shown != appVersion && shown.endsWith('.0')) {
      shown = shown.substring(0, shown.length - 2);
    }
    expect(shown, appVersion);
  });

  test('every hiragana card speaks its kana and example', () {
    expect(hiraganaCards, hasLength(71));
    expect(
      hiraganaCards.map((card) => card.kana).toSet(),
      hasLength(hiraganaCards.length),
    );
    for (final card in hiraganaCards) {
      expect(_spoken(card.romaji), card.kana, reason: card.romaji);
      expect(card.example, contains(card.kana), reason: card.kana);
      expect(_spoken(card.exampleRomaji), card.example, reason: card.example);
      expect(card.exampleChinese, isNotEmpty);
    }
  });

  test('every katakana card speaks its kana and example', () {
    expect(katakanaCards, hasLength(hiraganaCards.length));
    expect(
      katakanaCards.map((card) => card.kana).toSet(),
      hasLength(katakanaCards.length),
    );
    for (final card in katakanaCards) {
      expect(_spoken(card.romaji), _asHiragana(card.kana), reason: card.kana);
      expect(card.example, contains(card.kana), reason: card.kana);
      expect(
        _asHiragana(_spoken(card.exampleRomaji)),
        _expandChoon(_asHiragana(card.example)),
        reason: card.example,
      );
      expect(card.exampleChinese, isNotEmpty);
    }
  });

  testWidgets('homepage lists version and kana sections above 單字', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    for (final card in allKanaCards) {
      card.isFavorite = false;
    }

    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    final version = find.text('version: $appVersion');
    final wordsLoaded = find.textContaining('Words Loaded:');
    expect(version, findsOneWidget);
    expect(wordsLoaded, findsOneWidget);
    expect(
      tester.getTopLeft(version).dy,
      lessThan(tester.getTopLeft(wordsLoaded).dy),
    );

    expect(
      tester.getTopLeft(find.text('五十音')).dy,
      lessThan(tester.getTopLeft(find.text('單字(${words.length})')).dy),
    );
    expect(
      tester.getTopLeft(find.text('收藏五十音 (0)')).dy,
      lessThan(tester.getTopLeft(find.text('單字(${words.length})')).dy),
    );

    await tester.tap(find.text('五十音'));
    await tester.pumpAndSettle();
    expect(find.text('平假名'), findsOneWidget);
    expect(find.text('片假名'), findsOneWidget);

    await tester.tap(find.text('平假名'));
    await tester.pumpAndSettle();
    expect(find.text('あ'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(tester.widget<Text>(find.text('a')).style?.fontSize, 48);
    expect(tester.widget<Text>(find.text('a')).style?.color, Colors.red);
    expect(find.text('繼續'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star), findsOneWidget);

    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(find.text('a'), findsNWidgets(2));
    expect(find.text('あめ'), findsOneWidget);
    expect(find.text('ame'), findsOneWidget);
    expect(find.text('雨'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('片假名'));
    await tester.pumpAndSettle();
    expect(find.text('ア'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('繼續'), findsOneWidget);
    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(find.text('アイス'), findsOneWidget);
    expect(find.text('aisu'), findsOneWidget);
    expect(find.text('冰淇淋'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('收藏五十音 (1)'), findsOneWidget);

    await tester.ensureVisible(find.text('收藏五十音 (1)'));
    await tester.tap(find.text('收藏五十音 (1)'));
    await tester.pumpAndSettle();
    expect(find.text('あ'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);
    expect(find.text('播放收藏五十音'), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    expect(find.text('あめ'), findsOneWidget);
    expect(find.text('雨'), findsOneWidget);
    expect(find.text('繼續'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    for (final card in allKanaCards) {
      card.isFavorite = false;
    }
  });

  testWidgets('收藏五十音 answer star is above the kana and removes it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    for (final card in allKanaCards) {
      card.isFavorite = false;
    }
    hiraganaCards.first.isFavorite = true;
    await saveKanaFavorites();

    await tester.pumpWidget(const MaterialApp(home: FavoriteKanaPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('答案'));
    await tester.pump();

    final star = tester.getTopLeft(find.byIcon(Icons.star));
    expect(star.dy, lessThan(tester.getTopLeft(find.text('あ')).dy));
    expect(star.dy, lessThan(tester.getTopLeft(find.text('あめ')).dy));

    await tester.tap(find.byIcon(Icons.star));
    await tester.pump();
    expect(find.text('還沒有收藏五十音。'), findsNothing);
    expect(find.text('あ'), findsWidgets);
    expect(hiraganaCards.first.isFavorite, isTrue);
    expect(
      tester.getTopLeft(find.byIcon(Icons.star_border)).dy,
      lessThan(tester.getTopLeft(find.text('あ')).dy),
    );

    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(find.text('還沒有收藏五十音。'), findsOneWidget);
    expect(hiraganaCards.first.isFavorite, isFalse);

    await tester.pump(const Duration(seconds: 2));
  });
}
