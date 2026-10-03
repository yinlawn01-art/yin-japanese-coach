import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yin_japanese_coach/learning_page.dart';
import 'package:yin_japanese_coach/main.dart';
import 'package:yin_japanese_coach/vocabulary_data.dart';
import 'package:yin_japanese_coach/word_study.dart';

Vocabulary sample(int index) {
  return Vocabulary(
    kanji: '語$index',
    hiragana: 'ご$index',
    romaji: 'go$index',
    meaning: '意思$index',
    wordType: '🔵 名詞',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    wordStudy.reset();
    words
      ..clear()
      ..addAll(List.generate(12, sample));
  });

  tearDown(() {
    wordStudy.reset();
    words.clear();
  });

  test('加10 個單字 appends the next flashcard numbers', () {
    expect(wordStudy.addBatch(words.length), 10);
    expect(wordStudy.indexes, List.generate(10, (index) => index));
    expect(wordStudy.nextIndex, 10);

    expect(wordStudy.addBatch(words.length), 2);
    expect(wordStudy.indexes, List.generate(12, (index) => index));
    expect(wordStudy.nextIndex, 10);
  });

  test('a second pass skips words already in 單字學習', () {
    wordStudy.indexes = [0, 1, 2];
    wordStudy.nextIndex = 0;

    expect(wordStudy.addBatch(5, count: 10), 2);
    expect(wordStudy.indexes, [0, 1, 2, 3, 4]);
    expect(wordStudy.nextIndex, 0);
  });

  test('O removes a word and the session can be restored', () {
    wordStudy.addBatch(words.length);
    wordStudy.beginSession();
    expect(wordStudy.removeAt(0), isFalse);
    expect(wordStudy.indexes.first, 1);
    expect(wordStudy.indexes, hasLength(9));

    wordStudy.restoreSession();
    expect(wordStudy.indexes, List.generate(10, (index) => index));
    expect(wordStudy.nextIndex, 10);
  });

  test('repeating plus ten keeps the snapshot and continues in order', () {
    wordStudy.indexes = [3];
    wordStudy.nextIndex = 4;
    wordStudy.beginSession();
    expect(wordStudy.removeAt(0), isTrue);

    wordStudy.restoreSession();
    wordStudy.addBatch(words.length);
    expect(wordStudy.indexes, [3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 1]);
    expect(wordStudy.nextIndex, 2);
  });

  test('ten new words continue from the cursor without restoring', () {
    wordStudy.indexes = [3];
    wordStudy.nextIndex = 4;
    wordStudy.beginSession();
    wordStudy.removeAt(0);

    wordStudy.addBatch(words.length);
    expect(wordStudy.indexes, [4, 5, 6, 7, 8, 9, 10, 11, 0, 1]);
    expect(wordStudy.sessionSnapshot, [3]);
  });

  test('重新整理 sends the next words back to flashcard 1', () async {
    wordStudy.addBatch(words.length);
    wordStudy.beginSession();
    expect(wordStudy.nextIndex, 10);
    expect(wordStudy.indexes, hasLength(10));

    wordStudy.restartFromBeginning();
    expect(wordStudy.indexes, isEmpty);
    expect(wordStudy.nextIndex, 0);
    expect(wordStudy.sessionSnapshot, List.generate(10, (index) => index));

    await wordStudy.save();
    wordStudy.reset();
    await wordStudy.load();
    expect(wordStudy.indexes, isEmpty);
    expect(wordStudy.nextIndex, 0);
    expect(wordStudy.sessionSnapshot, List.generate(10, (index) => index));

    expect(wordStudy.addBatch(words.length), 10);
    expect(wordStudy.indexes, List.generate(10, (index) => index));
    expect(wordStudy.nextIndex, 10);
  });

  test('the queue is saved', () async {
    wordStudy.addBatch(words.length);
    wordStudy.beginSession();
    await wordStudy.save();

    wordStudy.reset();
    await wordStudy.load();
    expect(wordStudy.indexes, List.generate(10, (index) => index));
    expect(wordStudy.nextIndex, 10);
    expect(wordStudy.sessionSnapshot, List.generate(10, (index) => index));
  });

  testWidgets('學習 offers a larger square 單字學習 button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LearningPage()));
    await tester.pumpAndSettle();

    final addSize = tester.getSize(
      find.widgetWithText(ElevatedButton, '加10 個單字'),
    );
    final studySize = tester.getSize(
      find.widgetWithText(ElevatedButton, '單字學習(0)'),
    );
    expect(addSize, const Size(288, 36));
    expect(studySize, const Size(288, 288));
    expect(tester.widget<Text>(find.text('加10 個單字')).style?.fontSize, 16.5);
    expect(tester.widget<Text>(find.text('單字學習(0)')).style?.fontSize, 52);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, '單字學習(0)'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('加10 個單字'));
    await tester.pumpAndSettle();
    expect(find.text('單字學習(10)'), findsOneWidget);

    await tester.tap(find.text('單字學習(10)'));
    await tester.pumpAndSettle();
    expect(find.text('(1 of 10)'), findsOneWidget);
    expect(find.text('語0'), findsWidgets);
    expect(find.text('答案'), findsOneWidget);
    expect(find.text('意思0'), findsNothing);
    expect(find.byIcon(Icons.star_border), findsNothing);
    expect(find.byIcon(Icons.star), findsNothing);

    final answerSize = tester.getSize(
      find.widgetWithText(ElevatedButton, '答案'),
    );
    expect(answerSize, const Size(336, 64));

    await tester.tap(find.text('答案'));
    await tester.pumpAndSettle();
    expect(find.text('意思0'), findsOneWidget);
    expect(find.text('ご0'), findsOneWidget);
    expect(find.text('go0'), findsOneWidget);
    expect(find.text('詞性：🔵 名詞'), findsOneWidget);
    expect(find.text('例句'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNothing);
    expect(find.byIcon(Icons.star), findsNothing);

    final known = find.widgetWithText(ElevatedButton, 'O');
    final unknown = find.widgetWithText(ElevatedButton, 'X');
    final knownRect = tester.getRect(known);
    final unknownRect = tester.getRect(unknown);
    expect(knownRect.width, closeTo(knownRect.height, 0.1));
    expect(unknownRect.width, closeTo(unknownRect.height, 0.1));
    expect(knownRect.left, lessThan(unknownRect.left));
    expect(unknownRect.left - knownRect.right, closeTo(56, 1));
    expect(tester.widget<Text>(find.text('O')).style?.color, Colors.green);
    expect(tester.widget<Text>(find.text('X')).style?.color, Colors.red);

    await tester.tap(unknown);
    await tester.pumpAndSettle();
    expect(find.text('(2 of 10)'), findsOneWidget);
    expect(find.text('語1'), findsWidgets);
    expect(find.text('意思0'), findsNothing);
    expect(find.text('答案'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('單字學習(10)'), findsOneWidget);

    await tester.tap(find.text('單字學習(10)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('答案'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'O'));
    await tester.pumpAndSettle();
    expect(find.text('(1 of 9)'), findsOneWidget);
    expect(find.text('語1'), findsWidgets);
    expect(find.text('答案'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('單字學習(9)'), findsOneWidget);
  });

  testWidgets('重新整理 is at the top and the next batch starts at word 1', (
    tester,
  ) async {
    wordStudy.indexes = [3, 4, 5];
    wordStudy.nextIndex = 6;
    await wordStudy.save();

    await tester.pumpWidget(const MaterialApp(home: LearningPage()));
    await tester.pumpAndSettle();

    final reset = find.text('重新整理');
    final add = find.text('加10 個單字');
    expect(reset, findsOneWidget);
    expect(tester.getTopLeft(reset).dy, lessThan(tester.getTopLeft(add).dy));
    expect(
      tester.getSize(find.widgetWithText(ElevatedButton, '重新整理')),
      addWordsButtonSize,
    );

    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(find.text('單字學習(0)'), findsOneWidget);
    expect(wordStudy.nextIndex, 0);
    expect(wordStudy.indexes, isEmpty);

    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('單字學習(10)'), findsOneWidget);
    expect(wordStudy.indexes.first, 0);

    await tester.tap(find.text('單字學習(10)'));
    await tester.pumpAndSettle();
    expect(find.text('(1 of 10)'), findsOneWidget);
    expect(find.text('語0'), findsWidgets);
  });

  testWidgets('homepage lists 學習 first and a larger Japanese title', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    final title = find.text('龍吟の日本語コース');
    final learning = find.text('學習');
    final kana = find.text('五十音');
    expect(title, findsOneWidget);
    expect(tester.widget<Text>(title).style?.fontSize, 84);
    expect(learning, findsOneWidget);
    expect(
      tester.getTopLeft(learning).dy,
      lessThan(tester.getTopLeft(kana).dy),
    );
  });

  testWidgets('marking the last word known opens the three choices', (
    tester,
  ) async {
    wordStudy.indexes = [3];
    wordStudy.nextIndex = 4;
    await wordStudy.save();

    await tester.pumpWidget(const MaterialApp(home: LearningPage()));
    await tester.pumpAndSettle();
    expect(find.text('單字學習(1)'), findsOneWidget);

    await tester.tap(find.text('單字學習(1)'));
    await tester.pumpAndSettle();
    expect(find.text('(1 of 1)'), findsOneWidget);
    expect(find.text('語3'), findsWidgets);

    await tester.tap(find.text('答案'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'X'));
    await tester.pumpAndSettle();
    expect(find.text('恭喜你背完目前的單字, 接下來你想做甚麼?'), findsNothing);
    expect(find.text('(1 of 1)'), findsOneWidget);
    expect(find.text('答案'), findsOneWidget);

    await tester.tap(find.text('答案'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'O'));
    await tester.pumpAndSettle();

    expect(find.text('恭喜你背完目前的單字, 接下來你想做甚麼?'), findsOneWidget);
    final repeat = find.widgetWithText(ElevatedButton, '再重複一次');
    final repeatPlus = find.widgetWithText(ElevatedButton, '重複 + 十個新單字');
    final tenNew = find.widgetWithText(ElevatedButton, '再來十個新單字');
    final repeatRect = tester.getRect(repeat);
    final repeatPlusRect = tester.getRect(repeatPlus);
    final tenNewRect = tester.getRect(tenNew);
    expect(repeatRect.width, closeTo(repeatRect.height, 0.5));
    expect(repeatPlusRect.width, closeTo(repeatRect.width, 0.5));
    expect(tenNewRect.width, closeTo(repeatRect.width, 0.5));
    expect(repeatRect.left, lessThan(repeatPlusRect.left));
    expect(repeatPlusRect.left, lessThan(tenNewRect.left));
    expect(
      repeatPlusRect.left - repeatRect.right,
      closeTo(tenNewRect.left - repeatPlusRect.right, 0.5),
    );

    await tester.tap(repeat);
    await tester.pumpAndSettle();
    expect(find.text('單字學習(1)'), findsOneWidget);
    expect(find.text('學習'), findsOneWidget);
    expect(wordStudy.indexes, [3]);
  });

  testWidgets('重複 + 十個新單字 restores the session and adds the next ten', (
    tester,
  ) async {
    wordStudy.indexes = [3];
    wordStudy.nextIndex = 4;
    await wordStudy.save();

    await tester.pumpWidget(const MaterialApp(home: LearningPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('單字學習(1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('答案'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'O'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重複 + 十個新單字'));
    await tester.pumpAndSettle();

    expect(find.text('單字學習(11)'), findsOneWidget);
    expect(find.text('學習'), findsOneWidget);
    expect(wordStudy.indexes, [3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 1]);
  });

  testWidgets('再來十個新單字 adds the next ten without restoring', (tester) async {
    wordStudy.indexes = [3];
    wordStudy.nextIndex = 4;
    await wordStudy.save();

    await tester.pumpWidget(const MaterialApp(home: LearningPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('單字學習(1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('答案'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'O'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('再來十個新單字'));
    await tester.pumpAndSettle();

    expect(find.text('單字學習(10)'), findsOneWidget);
    expect(find.text('學習'), findsOneWidget);
    expect(wordStudy.indexes, [4, 5, 6, 7, 8, 9, 10, 11, 0, 1]);
  });
}
