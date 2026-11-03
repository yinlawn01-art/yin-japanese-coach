import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yin_japanese_coach/example_pattern_page.dart';
import 'package:yin_japanese_coach/example_patterns.dart';
import 'package:yin_japanese_coach/favorite_example_page.dart';
import 'package:yin_japanese_coach/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    examplePatterns.clear();
    exampleFavorites.clear();
  });

  testWidgets('ten pattern files combine into 全部 in order', (tester) async {
    await tester.runAsync(loadExamplePatterns);

    expect(examplePatterns, hasLength(11));
    for (var i = 0; i < 10; i++) {
      expect(examplePatterns[i].sentences, hasLength(100));
    }

    final all = examplePatterns.last;
    expect(all.label, '(11) 全部');
    expect(all.sentences, hasLength(1000));
    expect(all.sentences.map((sentence) => sentence.japanese).toList(), [
      for (final pattern in examplePatterns.take(10))
        for (final sentence in pattern.sentences) sentence.japanese,
    ]);
    expect(
      all.sentences.sublist(900).map((sentence) => sentence.japanese).toList(),
      examplePatterns[9].sentences
          .map((sentence) => sentence.japanese)
          .toList(),
    );

    for (final sentence in all.sentences) {
      expect(sentence.hiragana, isNotEmpty);
      expect(sentence.romaji, isNotEmpty);
      expect(sentence.chinese, isNotEmpty);
      expect(sentence.english, isNotEmpty);
      expect(sentence.pattern, isNotEmpty);
      expect(sentence.rank, inInclusiveRange(1, 27));
    }
    expect(all.sentences.first.pattern, '～ません（動詞否定）');
    expect(all.sentences.first.rank, 4);
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
      '(1) 1-100 (100)',
    );
    final last = find.widgetWithText(ElevatedButton, '(11) 全部 (1000)');
    expect(tester.getSize(first).height, closeTo(64 * 0.9, 0.2));
    expect(tester.getSize(last).height, closeTo(64 * 0.9, 0.2));
    expect(
      tester.widget<Text>(find.text('(1) 1-100 (100)')).style?.fontSize,
      closeTo(22 * 0.9, 0.1),
    );
    expect(tester.getTopLeft(first).dy, greaterThanOrEqualTo(56));
    expect(tester.getBottomLeft(last).dy, lessThanOrEqualTo(932));
    expect(find.text('(7) 601-700 (100)'), findsOneWidget);
  });

  testWidgets('例句 shows each pattern and reads the next sentence', (
    tester,
  ) async {
    await tester.runAsync(loadExamplePatterns);
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('例句(1000)'));
    await tester.tap(find.text('例句(1000)'));
    await tester.pumpAndSettle();

    expect(find.text('(1) 1-100 (100)'), findsOneWidget);
    expect(find.text('(7) 601-700 (100)'), findsOneWidget);
    expect(find.text('(10) 901-1000 (100)'), findsOneWidget);
    expect(find.text('(11) 全部 (1000)'), findsOneWidget);

    await tester.tap(find.text('(1) 1-100 (100)'));
    await tester.pumpAndSettle();
    expect(find.text('私は酒を飲みません。'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);

    await tester.tap(find.byTooltip('收藏例句'));
    await tester.pumpAndSettle();
    expect(exampleFavorites, contains('私は酒を飲みません。'));
    expect(find.byIcon(Icons.star), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    expect(find.text('わたしはさけをのみません。'), findsOneWidget);
    expect(find.text('Watashi wa sake o nomimasen.'), findsOneWidget);
    expect(find.text('我不喝酒。'), findsOneWidget);
    expect(find.text('例句句型：～ません（動詞否定）'), findsOneWidget);
    expect(find.text('例句常用度排名：4'), findsOneWidget);
    expect(find.text('繼續'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byIcon(Icons.star)).dy,
      lessThan(tester.getTopLeft(find.text('私は酒を飲みません。')).dy),
    );

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pump();
    expect(exampleFavorites, contains('私は酒を飲みません。'));
    expect(find.text('私は酒を飲みません。'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byIcon(Icons.star_border)).dy,
      lessThan(tester.getTopLeft(find.text('私は酒を飲みません。')).dy),
    );

    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(exampleFavorites, isNot(contains('私は酒を飲みません。')));
    expect(find.text('僕はちょっと眠くて目を閉じました。'), findsOneWidget);
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

    expect(_readsOnTap(tester, '私は酒を飲みません。'), isTrue);
    await tester.tap(find.text('私は酒を飲みません。'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('答案'), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    expect(_readsOnTap(tester, '私は酒を飲みません。'), isTrue);
    expect(_readsOnTap(tester, 'わたしはさけをのみません。'), isTrue);
    expect(_readsOnTap(tester, 'Watashi wa sake o nomimasen.'), isTrue);
    expect(_readsOnTap(tester, '我不喝酒。'), isFalse);
    expect(_readsOnTap(tester, '例句句型：～ません（動詞否定）'), isFalse);
    expect(_readsOnTap(tester, '例句常用度排名：4'), isFalse);

    await tester.tap(find.text('わたしはさけをのみません。'));
    await tester.pump();
    await tester.tap(find.text('Watashi wa sake o nomimasen.'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('私は酒を飲みません。'), findsOneWidget);
    expect(find.text('繼續'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('收藏例句 reviews a starred sentence and removes it', (tester) async {
    await tester.runAsync(loadExamplePatterns);
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('例句(1000)'));
    await tester.tap(find.text('例句(1000)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('(1) 1-100 (100)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('收藏例句'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('例句(1000)'), findsOneWidget);
    expect(find.text('收藏例句(1)'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('收藏例句(1)')).dy,
      greaterThan(tester.getTopLeft(find.text('例句(1000)')).dy),
    );

    await tester.ensureVisible(find.text('收藏例句(1)'));
    await tester.tap(find.text('收藏例句(1)'));
    await tester.pumpAndSettle();
    expect(find.text('私は酒を飲みません。'), findsOneWidget);
    expect(find.text('播放收藏例句'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    expect(find.text('わたしはさけをのみません。'), findsOneWidget);
    expect(find.text('Watashi wa sake o nomimasen.'), findsOneWidget);
    expect(find.text('我不喝酒。'), findsOneWidget);
    expect(find.text('例句句型：～ません（動詞否定）'), findsOneWidget);
    expect(find.text('例句常用度排名：4'), findsOneWidget);
    expect(find.text('繼續'), findsOneWidget);
    expect(_readsOnTap(tester, '私は酒を飲みません。'), isTrue);
    expect(_readsOnTap(tester, 'わたしはさけをのみません。'), isTrue);
    expect(_readsOnTap(tester, 'Watashi wa sake o nomimasen.'), isTrue);
    expect(_readsOnTap(tester, '我不喝酒。'), isFalse);
    expect(_readsOnTap(tester, '例句句型：～ません（動詞否定）'), isFalse);
    expect(_readsOnTap(tester, '例句常用度排名：4'), isFalse);
    await tester.tap(find.text('Watashi wa sake o nomimasen.'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.byIcon(Icons.star)).dy,
      greaterThan(tester.getTopLeft(find.text('私は酒を飲みません。')).dy),
    );

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pump();
    expect(find.text('還沒有收藏例句。'), findsNothing);
    expect(find.text('私は酒を飲みません。'), findsOneWidget);
    expect(exampleFavorites, contains('私は酒を飲みません。'));
    expect(
      tester.getTopLeft(find.byIcon(Icons.star_border)).dy,
      greaterThan(tester.getTopLeft(find.text('私は酒を飲みません。')).dy),
    );

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(exampleFavorites, contains('私は酒を飲みません。'));

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
    expect(find.text('例句(1000)'), findsOneWidget);
    expect(find.text('收藏例句(0)'), findsOneWidget);
  });

  testWidgets('收藏例句 continues to another saved sentence', (tester) async {
    await tester.runAsync(() async {
      await loadExamplePatterns();
      exampleFavorites
        ..clear()
        ..addAll(['私は酒を飲みません。', '僕はちょっと眠くて目を閉じました。']);
      await saveExampleFavorites();
    });

    await tester.pumpWidget(const MaterialApp(home: FavoriteExamplePage()));
    await tester.pumpAndSettle();
    expect(find.text('私は酒を飲みません。'), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pump();
    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(find.text('答案'), findsOneWidget);
    expect(find.text('僕はちょっと眠くて目を閉じました。'), findsOneWidget);
    expect(find.text('私は酒を飲みません。'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('收藏例句 front star removes immediately', (tester) async {
    await tester.runAsync(() async {
      await loadExamplePatterns();
      exampleFavorites
        ..clear()
        ..add('私は酒を飲みません。');
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
        ..addAll(['私は酒を飲みません。', '僕はちょっと眠くて目を閉じました。']);
      await saveExampleFavorites();
    });

    await tester.pumpWidget(const MaterialApp(home: FavoriteExamplePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('答案'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.star));
    await tester.pump();
    expect(exampleFavorites, containsAll(['私は酒を飲みません。', '僕はちょっと眠くて目を閉じました。']));
    expect(find.byIcon(Icons.star_border), findsOneWidget);

    await tester.tap(find.text('繼續'));
    await tester.pump();
    expect(exampleFavorites, hasLength(1));
    expect(exampleFavorites, contains('僕はちょっと眠くて目を閉じました。'));
    expect(find.text('僕はちょっと眠くて目を閉じました。'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);
    expect(find.text('私は酒を飲みません。'), findsNothing);

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
