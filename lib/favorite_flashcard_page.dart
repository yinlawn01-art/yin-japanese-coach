import 'dart:async';

import 'package:flutter/material.dart';

import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

import 'vocabulary_data.dart';

import 'package:flutter_tts/flutter_tts.dart';

import 'soft_speech.dart';

import 'example_sentence.dart';

import 'romaji_speech.dart';

import 'app_look.dart';
import 'bundled_text.dart';

class FavoriteWordsMenuPage extends StatefulWidget {
  const FavoriteWordsMenuPage({super.key});

  @override
  State<FavoriteWordsMenuPage> createState() => _FavoriteWordsMenuPageState();
}

class _FavoriteWordsMenuPageState extends State<FavoriteWordsMenuPage> {
  Future<void> _open(bool chineseToJapanese) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavoriteFlashcardPage(
          chineseToJapanese: chineseToJapanese,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const size = Size(336, 64);
    final buttonStyle = ElevatedButton.styleFrom(
      fixedSize: size,
      minimumSize: size,
      maximumSize: size,
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: bundledText.copyWith(fontSize: 28),
    );
    final labelStyle = bundledText.copyWith(fontSize: 28, height: 1.1);
    final jaCount = words.where((word) => word.isFavorite).length;
    final zhCount = words.where((word) => word.isZhJaFavorite).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏單字'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: buttonStyle,
              onPressed: () => _open(false),
              child: Text('日→中單字($jaCount)', style: labelStyle),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: buttonStyle,
              onPressed: () => _open(true),
              child: Text('中→日單字($zhCount)', style: labelStyle),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteFlashcardPage extends StatefulWidget {
  const FavoriteFlashcardPage({super.key, this.chineseToJapanese = false});

  final bool chineseToJapanese;

  @override
  State<FavoriteFlashcardPage> createState() =>
      _FavoriteFlashcardPageState();
}

class _FavoriteFlashcardPageState
    extends State<FavoriteFlashcardPage> {

      final FlutterTts flutterTts = FlutterTts();

  List<Vocabulary> get favoriteWords => words
      .where(
        (w) => widget.chineseToJapanese ? w.isZhJaFavorite : w.isFavorite,
      )
      .toList();

  String get _pageTitle =>
      widget.chineseToJapanese ? '中→日單字' : '日→中單字';

  String _prompt(Vocabulary word) =>
      widget.chineseToJapanese ? word.meaning : word.kanji;

  void _clearSaved(Vocabulary word) {
    if (widget.chineseToJapanese) {
      word.isZhJaFavorite = false;
    } else {
      word.isFavorite = false;
    }
  }

    int currentIndex = 0;   

    bool showAnswer = false;

    bool dropAfterContinue = false;

    bool showExample = false;

    bool isPlayingFavorites = false;

    bool showPlayingJapanese = true;

    Vocabulary? playingWord;

    int _playGeneration = 0;

    Completer<void>? _speechDone;

    final random = Random();

    Vocabulary get currentWord =>
    favoriteWords[currentIndex];

    static const Size _studyShowAnswerSize = Size(336, 64);

    static const double _answerSlotHeight = 196;

Future<void> _saveFavorites() async {
  final prefs = await SharedPreferences.getInstance();

  final favorites = words
      .where(
        (w) => widget.chineseToJapanese ? w.isZhJaFavorite : w.isFavorite,
      )
      .map((w) => w.kanji)
      .toList();

  await prefs.setStringList(
    widget.chineseToJapanese ? 'zhJaFavorites' : 'favorites',
    favorites,
  );
}

Future<void> speakJapanese(String romaji) async {
  await flutterTts.stop();
  await applyNaturalVoice(flutterTts, 'ja-JP');
  await flutterTts.speak(pronunciationForRomaji(romaji));
}

void _toggleRemoveLater() {
  setState(() {
    dropAfterContinue = !dropAfterContinue;
  });
}

Future<void> showCurrentAnswer() async {
  final romaji = currentWord.romaji;

  setState(() {
    showAnswer = true;
    dropAfterContinue = false;
  });

  await speakJapanese(romaji);
}

Future<void> openExample() async {
  final sentence = exampleSentenceFor(currentWord.kanji);
  setState(() {
    showExample = true;
  });
  await speakJapanese(sentence.romaji);
}

void closeExample() {
  flutterTts.stop();
  setState(() {
    showExample = false;
  });
}

double _studyShowAnswerTop({
  required double bodyHeight,
  required double bodyWidth,
  required String kanji,
  String? romaji,
  required TextStyle countStyle,
  required TextStyle kanjiStyle,
  required TextScaler textScaler,
}) {
  double line(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      textAlign: TextAlign.center,
      strutStyle: StrutStyle(
        fontSize: style.fontSize,
        height: style.height,
        forceStrutHeight: true,
      ),
    )..layout(maxWidth: bodyWidth - 48);
    return painter.height;
  }

  const iconHeight = 56.0;
  const gap = 40.0;
  const answerSlot = 210.0;
  final contentHeight = line('Word 1 / 1', countStyle) +
      gap +
      line(kanji, kanjiStyle) +
      (romaji == null
          ? 0
          : romanSpellingHeight(romaji, bodyWidth - 48, textScaler)) +
      iconHeight +
      answerSlot +
      _studyShowAnswerSize.height;
  final paddedHeight = contentHeight + 48;
  final columnTop = (bodyHeight - paddedHeight) / 2;
  return columnTop + 24 + contentHeight - _studyShowAnswerSize.height;
}

Widget _matchingButton(
  String label,
  VoidCallback onPressed,
  double fontSize,
) {
  return SizedBox.fromSize(
    size: _studyShowAnswerSize,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        fixedSize: _studyShowAnswerSize,
        minimumSize: _studyShowAnswerSize,
        maximumSize: _studyShowAnswerSize,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: fontSize, height: 1.1),
      ),
    ),
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
                      color: lookInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  speakableText(
                    text: sentence.romaji,
                    japanese: sentence.romaji,
                    style: lookRomajiStyle,
                  ),
                  const SizedBox(height: 10),
                  speakableText(
                    text: sentence.hiragana,
                    japanese: sentence.romaji,
                    style: const TextStyle(fontSize: 24, color: lookReading),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sentence.chinese,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      color: lookMeaning,
                    ),
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
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: style,
      ),
    ),
  );
}

Future<void> removeCurrentFavorite() async {
  if (favoriteWords.isEmpty) return;
  _clearSaved(currentWord);

  if (!mounted) {
    await _saveFavorites();
    return;
  }

  setState(() {
    showAnswer = false;
    showExample = false;
    dropAfterContinue = false;

    if (favoriteWords.isEmpty) {
      currentIndex = 0;
    } else if (currentIndex >= favoriteWords.length) {
      currentIndex = favoriteWords.length - 1;
    }
  });

  unawaited(flutterTts.stop());
  await _saveFavorites();
}

bool _isCurrentPlay(int generation) {
  return mounted &&
      isPlayingFavorites &&
      generation == _playGeneration;
}

void _finishSpeech() {
  final done = _speechDone;
  if (done != null && !done.isCompleted) {
    done.complete();
  }
}

Future<void> _speakLine(
  String text,
  String language,
  int generation,
) async {
  if (!_isCurrentPlay(generation) || text.isEmpty) return;

  final done = Completer<void>();
  _speechDone = done;

  void finish() {
    if (!done.isCompleted) done.complete();
  }

  flutterTts.setCompletionHandler(finish);
  flutterTts.setErrorHandler((_) => finish());
  flutterTts.setCancelHandler(finish);

  try {
    await applyNaturalVoice(flutterTts, language).timeout(
      const Duration(seconds: 8),
    );
  } catch (_) {
    finish();
    return;
  }

  if (!_isCurrentPlay(generation)) {
    finish();
    return;
  }

  try {
    await flutterTts.speak(text).timeout(const Duration(seconds: 8));
  } catch (_) {
    finish();
    return;
  }
  await done.future.timeout(
    const Duration(seconds: 8),
    onTimeout: finish,
  );
}

Future<void> _pause(Duration duration, int generation) async {
  final step = const Duration(milliseconds: 100);
  var elapsed = Duration.zero;

  while (elapsed < duration) {
    if (!_isCurrentPlay(generation)) return;
    await Future.delayed(step);
    elapsed += step;
  }
}

int _nextPlayIndex(int length, int current) {
  if (length <= 1) return 0;

  var next = current;
  do {
    next = random.nextInt(length);
  } while (next == current);

  return next;
}

Future<void> _playJapaneseThenChinese(Vocabulary word, int generation) async {
  if (!mounted || generation != _playGeneration) return;
  setState(() {
    playingWord = word;
    showPlayingJapanese = true;
  });

  await _speakLine(
    pronunciationForRomaji(word.romaji),
    'ja-JP',
    generation,
  );
  if (!_isCurrentPlay(generation)) return;
  await _pause(const Duration(milliseconds: 1500), generation);
  if (!_isCurrentPlay(generation)) return;

  await _speakLine(
    pronunciationForRomaji(word.romaji),
    'ja-JP',
    generation,
  );
  if (!_isCurrentPlay(generation)) return;
  await _pause(const Duration(seconds: 2), generation);
  if (!_isCurrentPlay(generation)) return;

  if (!mounted || generation != _playGeneration) return;
  setState(() {
    showPlayingJapanese = false;
  });

  final chineseShownAt = DateTime.now();
  await _speakLine(word.meaning, 'zh-TW', generation);
  if (!_isCurrentPlay(generation)) return;

  final chineseVisibleFor = DateTime.now().difference(chineseShownAt);
  const minimumChineseTime = Duration(seconds: 2);
  if (chineseVisibleFor < minimumChineseTime) {
    await _pause(
      minimumChineseTime - chineseVisibleFor,
      generation,
    );
  }
}

Future<void> _playChineseThenJapanese(Vocabulary word, int generation) async {
  if (!mounted || generation != _playGeneration) return;
  setState(() {
    playingWord = word;
    showPlayingJapanese = false;
  });

  final chineseShownAt = DateTime.now();
  await _speakLine(word.meaning, 'zh-TW', generation);
  if (!_isCurrentPlay(generation)) return;

  final chineseVisibleFor = DateTime.now().difference(chineseShownAt);
  const minimumChineseTime = Duration(seconds: 2);
  if (chineseVisibleFor < minimumChineseTime) {
    await _pause(
      minimumChineseTime - chineseVisibleFor,
      generation,
    );
  }
  if (!_isCurrentPlay(generation)) return;

  if (!mounted || generation != _playGeneration) return;
  setState(() {
    showPlayingJapanese = true;
  });

  await _speakLine(
    pronunciationForRomaji(word.romaji),
    'ja-JP',
    generation,
  );
  if (!_isCurrentPlay(generation)) return;
  await _pause(const Duration(milliseconds: 1500), generation);
  if (!_isCurrentPlay(generation)) return;

  await _speakLine(
    pronunciationForRomaji(word.romaji),
    'ja-JP',
    generation,
  );
  if (!_isCurrentPlay(generation)) return;
  await _pause(const Duration(seconds: 2), generation);
}

Future<void> playAllFavorites() async {
  if (isPlayingFavorites || favoriteWords.isEmpty) return;

  final generation = ++_playGeneration;
  var index = random.nextInt(favoriteWords.length);

  setState(() {
    isPlayingFavorites = true;
    showPlayingJapanese = !widget.chineseToJapanese;
    playingWord = favoriteWords[index];
  });

  unawaited(flutterTts.stop());
  if (!mounted || generation != _playGeneration) return;

  while (_isCurrentPlay(generation)) {
    final list = favoriteWords;
    if (list.isEmpty) break;
    if (index >= list.length) index = 0;

    final word = list[index];
    if (widget.chineseToJapanese) {
      await _playChineseThenJapanese(word, generation);
    } else {
      await _playJapaneseThenChinese(word, generation);
    }
    if (!_isCurrentPlay(generation)) break;

    index = _nextPlayIndex(list.length, index);
  }

  if (mounted && generation == _playGeneration) {
    setState(() {
      isPlayingFavorites = false;
      showAnswer = false;
      showExample = false;
    });
  }
}

Future<void> stopPlayingFavorites() async {
  _playGeneration++;
  isPlayingFavorites = false;
  _finishSpeech();
  await flutterTts.stop();

  if (!mounted) return;

  setState(() {
    isPlayingFavorites = false;
    showAnswer = false;
    showExample = false;
  });
}

@override
void dispose() {
  _playGeneration++;
  isPlayingFavorites = false;
  _finishSpeech();
  flutterTts.stop();
  super.dispose();
}

Future<void> nextFavorite() async {
  final removing = dropAfterContinue;
  if (removing && favoriteWords.isNotEmpty) {
    _clearSaved(currentWord);
  }

  final total = favoriteWords.length;
  var nextIndex = 0;
  if (total > 1) {
    if (removing) {
      nextIndex = currentIndex >= total ? total - 1 : currentIndex;
    } else {
      do {
        nextIndex = random.nextInt(total);
      } while (nextIndex == currentIndex);
    }
  }

  if (!mounted) {
    unawaited(flutterTts.stop());
    if (removing) await _saveFavorites();
    return;
  }

  setState(() {
    dropAfterContinue = false;
    currentIndex = nextIndex;
    showAnswer = false;
    showExample = false;
  });

  unawaited(flutterTts.stop());
  if (removing) await _saveFavorites();
}

  @override
  Widget build(BuildContext context) {
 if (favoriteWords.isEmpty) {
  return Scaffold(
    appBar: AppBar(
      title: Text(_pageTitle),
    ),
    body: const Center(
      child: Text(
        'No favorite words yet.',
      ),
    ),
  );
}   
return Scaffold(
  appBar: AppBar(
    title: Text(_pageTitle),
  ),

 body: isPlayingFavorites
      ? _playingFavoritesView()
      : LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = MediaQuery.sizeOf(context).height;
            final exampleTop = (screenHeight * 0.30 -
                    (screenHeight - constraints.maxHeight))
                .clamp(0.0, constraints.maxHeight);
            final largeLabelSize =
                (Theme.of(context).textTheme.labelLarge?.fontSize ?? 14) * 2;
            final baseStyle = DefaultTextStyle.of(context).style;
            final showAnswerTop = _studyShowAnswerTop(
              bodyHeight: constraints.maxHeight,
              bodyWidth: constraints.maxWidth,
              kanji: _prompt(currentWord),
              romaji: widget.chineseToJapanese ? null : currentWord.romaji,
              countStyle: baseStyle.merge(const TextStyle(fontSize: 20)),
              kanjiStyle: baseStyle.merge(
                const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              textScaler: MediaQuery.textScalerOf(context),
            );
            final sentence = exampleSentenceFor(currentWord.kanji);

            final answerBottom = (constraints.maxHeight - showAnswerTop + 8)
                .clamp(0.0, constraints.maxHeight);

            return Stack(
              children: [
                if (showExample)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: answerBottom,
                    child: exampleBody(sentence),
                  )
                else if (showAnswer)
                  Positioned(
                    top: exampleTop + _studyShowAnswerSize.height + 12,
                    left: 0,
                    right: 0,
                    bottom: answerBottom,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _answeredFavorite(),
                    ),
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _favoriteCard(),
                    ),
                  ),
                if (!showExample)
                  Positioned(
                    top: (screenHeight * 0.10 -
                            (screenHeight - constraints.maxHeight))
                        .clamp(0.0, constraints.maxHeight),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _matchingButton(
                        '播放收藏單字',
                        playAllFavorites,
                        largeLabelSize,
                      ),
                    ),
                  ),
                if (showExample)
                  Positioned(
                    top: showAnswerTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _matchingButton(
                        'Go back',
                        closeExample,
                        largeLabelSize,
                      ),
                    ),
                  ),
                if (showAnswer && !showExample)
                  Positioned(
                    top: exampleTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _matchingButton(
                        '例句',
                        () {
                          openExample();
                        },
                        largeLabelSize,
                      ),
                    ),
                  ),
                if (!showExample)
                  Positioned(
                    top: showAnswerTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _matchingButton(
                        showAnswer ? '繼續' : '答案',
                        showAnswer
                            ? nextFavorite
                            : () {
                                showCurrentAnswer();
                              },
                        largeLabelSize,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
);
  }

Widget _playingFavoritesView() {
  final word = playingWord;
  final text = word == null
      ? ''
      : showPlayingJapanese
          ? word.kanji
          : word.meaning;

  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: showPlayingJapanese ? 48 : 40,
            fontWeight: FontWeight.bold,
            color: showPlayingJapanese ? lookInk : lookMeaning,
          ),
        ),
        if (showPlayingJapanese && word != null) ...[
          const SizedBox(height: 4),
          Text(
            word.romaji,
            textAlign: TextAlign.center,
            style: lookRomajiStyle,
          ),
        ],
        const SizedBox(height: 24),
        _matchingButton(
          'Stop',
          stopPlayingFavorites,
          (Theme.of(context).textTheme.labelLarge?.fontSize ?? 14) * 2,
        ),
      ],
    ),
  );
}

Widget _favoriteCard() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    
children: [

  showAnswer
      ? speakableText(
          text: currentWord.kanji,
          japanese: currentWord.romaji,
          style: lookPrompt,
        )
      : Text(
          _prompt(currentWord),
          style: lookPrompt,
        ),
  if (showAnswer || !widget.chineseToJapanese) ...[
    const SizedBox(height: 4),
    Text(
      currentWord.romaji,
      textAlign: TextAlign.center,
      style: lookRomajiStyle,
    ),
  ],

  IconButton(
    iconSize: 40,
    tooltip: 'Remove from favorites',
    icon: const Icon(
      Icons.star,
      color: lookGold,
    ),
    onPressed: removeCurrentFavorite,
  ),

  SizedBox(
    height: _answerSlotHeight,
    child: showAnswer
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              speakableText(
                text: currentWord.hiragana,
                japanese: currentWord.romaji,
                style: const TextStyle(
                  fontSize: 28,
                  color: lookReading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentWord.wordType,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: lookInk,
                ),
              ),
              const SizedBox(height: 10),
              speakableText(
                text: currentWord.meaning,
                japanese: currentWord.romaji,
                style: const TextStyle(
                  fontSize: 28,
                  color: lookMeaning,
                ),
              ),
            ],
          )
        : const SizedBox.shrink(),
  ),
    ],
  );
}

Widget _answeredFavorite() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      speakableText(
        text: currentWord.kanji,
        japanese: currentWord.romaji,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            height: 1.0,
            color: lookInk,
          ),
      ),
      const SizedBox(height: 4),
      Text(
        currentWord.romaji,
        textAlign: TextAlign.center,
        style: lookRomajiStyle,
      ),
      IconButton(
        iconSize: 32,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        tooltip: 'Remove from favorites',
        icon: Icon(
          dropAfterContinue ? Icons.star_border : Icons.star,
          color: lookGold,
        ),
        onPressed: _toggleRemoveLater,
      ),
      speakableText(
        text: currentWord.hiragana,
        japanese: currentWord.romaji,
        style: const TextStyle(
          fontSize: 28,
          height: 1.1,
          color: lookReading,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        currentWord.wordType,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          height: 1.1,
          fontWeight: FontWeight.bold,
          color: lookInk,
        ),
      ),
      const SizedBox(height: 4),
      speakableText(
        text: currentWord.meaning,
        japanese: currentWord.romaji,
        style: const TextStyle(
          fontSize: 28,
          height: 1.1,
          color: lookMeaning,
        ),
      ),
    ],
  );
}
}