import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'bundled_text.dart';
import 'example_sentence.dart';
import 'main.dart';
import 'romaji_speech.dart';
import 'soft_speech.dart';
import 'vocabulary_data.dart';
import 'word_study.dart';

const Size addWordsButtonSize = Size(288, 36);
const Size studyQueueButtonSize = Size(288, 144);

const Size _studyButtonSize = Size(336, 64);
const double _answerSlotHeight = 210;
const double _markButtonSide = 64;
const double _markButtonGap = 56;

class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await wordStudy.load();
    await zhJaStudy.load();
    wordStudy.retainAvailable(words.length);
    zhJaStudy.retainAvailable(words.length);
    if (mounted) {
      setState(() {
        _ready = true;
      });
    }
  }

  Future<void> _addTen() async {
    wordStudy.addBatch(words.length);
    if (mounted) setState(() {});
    await wordStudy.save();
  }

  Future<void> _restartFromBeginning() async {
    wordStudy.restartFromBeginning();
    if (mounted) setState(() {});
    await wordStudy.save();
  }

  Future<void> _restartZhJa() async {
    zhJaStudy.restartFromBeginning();
    if (mounted) setState(() {});
    await zhJaStudy.save();
  }

  Future<void> _openStudy() async {
    if (wordStudy.indexes.isEmpty) return;
    wordStudy.beginSession();
    await wordStudy.save();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudySessionPage()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _addTenZhJa() async {
    zhJaStudy.addBatch(words.length);
    if (mounted) setState(() {});
    await zhJaStudy.save();
  }

  Future<void> _openZhJa() async {
    if (zhJaStudy.indexes.isEmpty) return;
    zhJaStudy.beginSession();
    await zhJaStudy.save();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudySessionPage(chineseToJapanese: true),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final count = wordStudy.indexes.length;
    final zhJaCount = zhJaStudy.indexes.length;
    final squareShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );

    final resetButton = SizedBox.fromSize(
      size: addWordsButtonSize,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          fixedSize: addWordsButtonSize,
          minimumSize: addWordsButtonSize,
          maximumSize: addWordsButtonSize,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: bundledText.copyWith(fontSize: 16.5, height: 1.1),
        ),
        onPressed: _ready ? _restartFromBeginning : null,
        child: const Text(
          '重新整理 (單字)',
          style: TextStyle(fontSize: 16.5, height: 1.1),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('學習')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = MediaQuery.sizeOf(context).height;
          final topInset = screenHeight - constraints.maxHeight;
          final leadHeight =
              16 +
              addWordsButtonSize.height +
              12 +
              addWordsButtonSize.height +
              28 +
              studyQueueButtonSize.height;
          final zhTop = screenHeight * 0.60 - topInset;
          final rawGap = zhTop - leadHeight;
          final zhSectionGap = rawGap < 28 ? 28.0 : rawGap;

          return Column(
            children: [
              const SizedBox(height: 16),
              resetButton,
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        SizedBox.fromSize(
                          size: addWordsButtonSize,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              fixedSize: addWordsButtonSize,
                              minimumSize: addWordsButtonSize,
                              maximumSize: addWordsButtonSize,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: bundledText.copyWith(
                                fontSize: 16.5,
                                height: 1.1,
                              ),
                            ),
                            onPressed: _ready ? _addTen : null,
                            child: const Text(
                              '加10 個單字',
                              style: TextStyle(fontSize: 16.5, height: 1.1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox.fromSize(
                          size: studyQueueButtonSize,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              fixedSize: studyQueueButtonSize,
                              minimumSize: studyQueueButtonSize,
                              maximumSize: studyQueueButtonSize,
                              padding: const EdgeInsets.all(20),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: squareShape,
                            ),
                            onPressed: count == 0 ? null : _openStudy,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '日→中單字($count)',
                                style: const TextStyle(
                                  fontSize: 52,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: zhSectionGap),
                        SizedBox.fromSize(
                          size: addWordsButtonSize,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              fixedSize: addWordsButtonSize,
                              minimumSize: addWordsButtonSize,
                              maximumSize: addWordsButtonSize,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: bundledText.copyWith(
                                fontSize: 16.5,
                                height: 1.1,
                              ),
                            ),
                            onPressed: _ready ? _restartZhJa : null,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '重新整理(中→日學習)',
                                style: TextStyle(fontSize: 16.5, height: 1.1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox.fromSize(
                          size: addWordsButtonSize,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              fixedSize: addWordsButtonSize,
                              minimumSize: addWordsButtonSize,
                              maximumSize: addWordsButtonSize,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: bundledText.copyWith(
                                fontSize: 16.5,
                                height: 1.1,
                              ),
                            ),
                            onPressed: _ready ? _addTenZhJa : null,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '加10 個單字到中→日學習',
                                style: TextStyle(fontSize: 16.5, height: 1.1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox.fromSize(
                          size: studyQueueButtonSize,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              fixedSize: studyQueueButtonSize,
                              minimumSize: studyQueueButtonSize,
                              maximumSize: studyQueueButtonSize,
                              padding: const EdgeInsets.all(20),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: squareShape,
                            ),
                            onPressed: zhJaCount == 0 ? null : _openZhJa,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '中→日單字($zhJaCount)',
                                style: const TextStyle(
                                  fontSize: 52,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StudySessionPage extends StatefulWidget {
  const StudySessionPage({super.key, this.chineseToJapanese = false});

  final bool chineseToJapanese;

  @override
  State<StudySessionPage> createState() => _StudySessionPageState();
}

class _StudySessionPageState extends State<StudySessionPage> {
  final FlutterTts flutterTts = FlutterTts();

  WordStudy get studyQueue => widget.chineseToJapanese ? zhJaStudy : wordStudy;

  String get _pageTitle => widget.chineseToJapanese ? '中→日單字' : '日→中單字';

  int currentIndex = 0;
  bool showAnswer = false;
  bool showExample = false;

  @override
  void dispose() {
    try {
      flutterTts.stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> speakJapanese(String romaji) async {
    try {
      await flutterTts.stop();
      await applyNaturalVoice(flutterTts, 'ja-JP');
      await flutterTts.speak(pronunciationForRomaji(romaji));
    } catch (_) {}
  }

  Future<void> showCurrentAnswer() async {
    final catalogIndex = studyQueue.indexes[currentIndex];
    setState(() {
      showAnswer = true;
    });
    await speakJapanese(words[catalogIndex].romaji);
  }

  Future<void> _stopSpeech() async {
    try {
      await flutterTts.stop();
    } catch (_) {}
  }

  Future<void> markKnown() async {
    final completed = studyQueue.indexes[currentIndex];
    final finished = studyQueue.removeAt(currentIndex);
    if (!finished) {
      setState(() {
        if (currentIndex >= studyQueue.indexes.length) {
          currentIndex = 0;
        }
        showAnswer = false;
        showExample = false;
      });
    }
    unawaited(_stopSpeech());
    await studyQueue.save();
    if (!mounted) return;
    if (finished) {
      await _showFinishedDialog(completed);
    }
  }

  Future<void> markUnknown() async {
    if (studyQueue.indexes.isEmpty) return;
    setState(() {
      currentIndex = (currentIndex + 1) % studyQueue.indexes.length;
      showAnswer = false;
      showExample = false;
    });
    unawaited(_stopSpeech());
  }

  Future<void> openExample() async {
    final sentence = exampleSentenceFor(
      words[studyQueue.indexes[currentIndex]].kanji,
    );
    setState(() {
      showExample = true;
    });
    await speakJapanese(sentence.romaji);
  }

  void closeExample() {
    try {
      flutterTts.stop();
    } catch (_) {}
    setState(() {
      showExample = false;
    });
  }

  Future<void> _showFinishedDialog(int completedCatalogIndex) async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _FinishedDialog(
          message: widget.chineseToJapanese
              ? '恭喜你背完目前的中翻日, 接下來你想做甚麼?'
              : '恭喜你背完目前的單字, 接下來你想做甚麼?',
        );
      },
    );
    if (!mounted) return;
    final leave = choice == null || choice == 'record';
    if (leave) {
      studyQueue.rememberBatchEnd(words.length);
    } else {
      if (choice == 'repeat' || choice == 'repeat-plus') {
        studyQueue.restoreSession();
      }
      if (choice == 'repeat-plus' || choice == 'new') {
        studyQueue.addBatch(words.length);
      }
      if (studyQueue.indexes.isNotEmpty) {
        final position = studyQueue.indexes.indexOf(completedCatalogIndex);
        final next = position < 0
            ? 0
            : (position + 1) % studyQueue.indexes.length;
        setState(() {
          currentIndex = next;
          showAnswer = false;
          showExample = false;
        });
      }
    }
    await studyQueue.save();
    if (!mounted) return;
    if (leave || studyQueue.indexes.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  Widget studyActionButton({
    required String label,
    required VoidCallback onPressed,
    required double fontSize,
  }) {
    return SizedBox.fromSize(
      size: _studyButtonSize,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          fixedSize: _studyButtonSize,
          minimumSize: _studyButtonSize,
          maximumSize: _studyButtonSize,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(fontSize: fontSize, height: 1.1),
        ),
      ),
    );
  }

  Widget markButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    const side = _markButtonSide;
    return SizedBox(
      width: side,
      height: side,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          fixedSize: const Size(side, side),
          minimumSize: const Size(side, side),
          maximumSize: const Size(side, side),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color, width: 2),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget speakableText({
    required String text,
    required TextStyle style,
    required String japanese,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => speakJapanese(japanese),
        child: Text(text, textAlign: TextAlign.center, style: style),
      ),
    );
  }

  double _textHeight(
    String text,
    TextStyle style,
    double maxWidth,
    TextScaler textScaler,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }

  double _actionButtonTop({
    required double bodyHeight,
    required double bodyWidth,
    required String countText,
    required String kanji,
    required TextStyle countStyle,
    required TextStyle kanjiStyle,
    required TextScaler textScaler,
  }) {
    const gap = 40.0;
    final contentHeight =
        _textHeight(countText, countStyle, bodyWidth - 48, textScaler) +
        gap +
        _textHeight(kanji, kanjiStyle, bodyWidth - 48, textScaler) +
        56 +
        _answerSlotHeight +
        _studyButtonSize.height;
    final paddedHeight = contentHeight + 48;
    final columnTop = (bodyHeight - paddedHeight) / 2;
    return columnTop + 24 + contentHeight - _studyButtonSize.height;
  }

  bool _isSaved(Vocabulary word) => widget.chineseToJapanese
      ? word.isZhJaFavorite
      : word.isFavorite;

  Future<void> _toggleSaved(Vocabulary word) async {
    setState(() {
      if (widget.chineseToJapanese) {
        word.isZhJaFavorite = !word.isZhJaFavorite;
      } else {
        word.isFavorite = !word.isFavorite;
      }
    });
    await saveDirectionFavorites(widget.chineseToJapanese);
  }

  Widget _studyStar(Vocabulary word, {bool compact = false}) {
    final icon = Icon(
      _isSaved(word) ? Icons.star : Icons.star_border,
      color: Colors.amber,
    );
    if (compact) {
      return IconButton(
        iconSize: 32,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        icon: icon,
        onPressed: () => _toggleSaved(word),
      );
    }
    return IconButton(
      iconSize: 40,
      icon: icon,
      onPressed: () => _toggleSaved(word),
    );
  }

  Widget _frontWord(String prompt, String countText, Vocabulary word) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          countText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 40),
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        _studyStar(word),
        const SizedBox(height: _answerSlotHeight),
      ],
    );
  }

  Widget _answeredWord(Vocabulary word, String countText) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          countText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, height: 1.1),
        ),
        const SizedBox(height: 8),
        speakableText(
          text: word.kanji,
          japanese: word.romaji,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        _studyStar(word, compact: true),
        speakableText(
          text: word.hiragana,
          japanese: word.romaji,
          style: const TextStyle(fontSize: 24, height: 1.1),
        ),
        const SizedBox(height: 4),
        speakableText(
          text: word.romaji,
          japanese: word.romaji,
          style: const TextStyle(
            fontSize: 24,
            height: 1.1,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '詞性：${word.wordType}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            height: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        speakableText(
          text: word.meaning,
          japanese: word.romaji,
          style: const TextStyle(fontSize: 28, height: 1.1, color: Colors.blue),
        ),
      ],
    );
  }

  Widget exampleBody(ExampleSentence sentence) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    speakableText(
                      text: sentence.japanese,
                      japanese: sentence.romaji,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    speakableText(
                      text: sentence.hiragana,
                      japanese: sentence.romaji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 10),
                    speakableText(
                      text: sentence.romaji,
                      japanese: sentence.romaji,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sentence.chinese,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bottomAction(double fontSize) {
    if (showExample) {
      return studyActionButton(
        label: 'Go back',
        onPressed: closeExample,
        fontSize: fontSize,
      );
    }
    if (showAnswer) {
      return SizedBox(
        width: _studyButtonSize.width,
        height: _studyButtonSize.height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            markButton(
              label: 'O',
              color: Colors.green,
              onPressed: () {
                markKnown();
              },
            ),
            const SizedBox(width: _markButtonGap),
            markButton(
              label: 'X',
              color: Colors.red,
              onPressed: () {
                markUnknown();
              },
            ),
          ],
        ),
      );
    }
    return studyActionButton(
      label: '答案',
      onPressed: () {
        showCurrentAnswer();
      },
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (studyQueue.indexes.isEmpty || words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: const SizedBox.shrink(),
      );
    }

    if (currentIndex >= studyQueue.indexes.length) {
      currentIndex = 0;
    }
    final catalogIndex = studyQueue.indexes[currentIndex];
    if (catalogIndex < 0 || catalogIndex >= words.length) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: const SizedBox.shrink(),
      );
    }

    final word = words[catalogIndex];
    final countText = '(${currentIndex + 1} of ${studyQueue.indexes.length})';
    final prompt = widget.chineseToJapanese ? word.meaning : word.kanji;
    final sentence = showExample ? exampleSentenceFor(word.kanji) : null;
    final largeLabelSize =
        (Theme.of(context).textTheme.labelLarge?.fontSize ?? 14) * 2;

    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = MediaQuery.sizeOf(context).height;
          final exampleTop =
              (screenHeight * 0.30 - (screenHeight - constraints.maxHeight))
                  .clamp(0.0, constraints.maxHeight);
          final baseStyle = DefaultTextStyle.of(context).style;
          final buttonTop = _actionButtonTop(
            bodyHeight: constraints.maxHeight,
            bodyWidth: constraints.maxWidth,
            countText: countText,
            kanji: prompt,
            countStyle: baseStyle.merge(const TextStyle(fontSize: 20)),
            kanjiStyle: baseStyle.merge(
              const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            textScaler: MediaQuery.textScalerOf(context),
          );
          final contentBottom = (constraints.maxHeight - buttonTop + 8).clamp(
            0.0,
            constraints.maxHeight,
          );

          return Stack(
            children: [
              if (showExample && sentence != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: contentBottom,
                  child: exampleBody(sentence),
                ),
              if (showAnswer && !showExample)
                Positioned(
                  top: exampleTop + 64 + 12,
                  left: 0,
                  right: 0,
                  bottom: contentBottom,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _answeredWord(word, countText),
                  ),
                ),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      showAnswer || showExample
                          ? ExcludeSemantics(
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 0,
                                  child: _frontWord(prompt, countText, word),
                                ),
                              ),
                            )
                          : _frontWord(prompt, countText, word),
                      _bottomAction(largeLabelSize),
                    ],
                  ),
                ),
              ),
              if (showAnswer && !showExample)
                Positioned(
                  top: exampleTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: studyActionButton(
                      label: '例句',
                      onPressed: () {
                        openExample();
                      },
                      fontSize: largeLabelSize,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FinishedDialog extends StatelessWidget {
  const _FinishedDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 28, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _choice(context, '再重複一次', 'repeat'),
                  const SizedBox(width: 12),
                  _choice(context, '重複 + 十個新單字', 'repeat-plus'),
                  const SizedBox(width: 12),
                  _choice(context, '再來十個新單字', 'new'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop('record'),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '紀錄進程與結束',
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(fontSize: 18, height: 1.1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choice(BuildContext context, String label, String value) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(value),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.25),
          ),
        ),
      ),
    );
  }
}
