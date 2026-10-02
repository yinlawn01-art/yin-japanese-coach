import 'dart:async';

import 'package:flutter/material.dart';

import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

import 'vocabulary_data.dart';

import 'package:flutter_tts/flutter_tts.dart';

class FavoriteFlashcardPage extends StatefulWidget {
  const FavoriteFlashcardPage({super.key});

  @override
  State<FavoriteFlashcardPage> createState() =>
      _FavoriteFlashcardPageState();
}

class _FavoriteFlashcardPageState
    extends State<FavoriteFlashcardPage> {

      final FlutterTts flutterTts = FlutterTts();

  List<Vocabulary> get favoriteWords =>
      words
          .where((w) => w.isFavorite)
          .toList();

    int currentIndex = 0;   

    bool showAnswer = false;

    bool isPlayingFavorites = false;

    bool showPlayingJapanese = true;

    Vocabulary? playingWord;

    int _playGeneration = 0;

    Completer<void>? _speechDone;

    final random = Random();

    Vocabulary get currentWord =>
    favoriteWords[currentIndex];

    static const Size _actionButtonSize = Size(168, 48);

    static const double _answerSlotHeight = 196;

Future<void> _saveFavorites() async {
  final prefs = await SharedPreferences.getInstance();

  final favorites = words
      .where((w) => w.isFavorite)
      .map((w) => w.kanji)
      .toList();

  await prefs.setStringList('favorites', favorites);
}

Future<void> speakJapanese(String text) async {
  await flutterTts.stop();
  await flutterTts.setLanguage('ja-JP');
  await flutterTts.setSpeechRate(0.4);
  await flutterTts.speak(text);
}

Future<void> showCurrentAnswer() async {
  final japanese = currentWord.hiragana;

  setState(() {
    showAnswer = true;
  });

  await speakJapanese(japanese);
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
  await flutterTts.stop();

  currentWord.isFavorite = false;
  await _saveFavorites();

  if (!mounted) return;

  setState(() {
    showAnswer = false;

    if (favoriteWords.isEmpty) {
      currentIndex = 0;
    } else if (currentIndex >= favoriteWords.length) {
      currentIndex = favoriteWords.length - 1;
    }
  });
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

  await flutterTts.setLanguage(language);
  await flutterTts.setSpeechRate(0.4);

  if (!_isCurrentPlay(generation)) {
    finish();
    return;
  }

  await flutterTts.speak(text);
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

Future<void> playAllFavorites() async {
  if (isPlayingFavorites || favoriteWords.isEmpty) return;

  final generation = ++_playGeneration;
  var index = random.nextInt(favoriteWords.length);

  await flutterTts.stop();
  if (!mounted || generation != _playGeneration) return;

  setState(() {
    isPlayingFavorites = true;
    showPlayingJapanese = true;
    playingWord = favoriteWords[index];
  });

  while (_isCurrentPlay(generation)) {
    final list = favoriteWords;
    if (list.isEmpty) break;
    if (index >= list.length) index = 0;

    final word = list[index];

    if (!mounted || generation != _playGeneration) break;
    setState(() {
      playingWord = word;
      showPlayingJapanese = true;
    });

    await _speakLine(word.hiragana, 'ja-JP', generation);
    if (!_isCurrentPlay(generation)) break;
    await _pause(const Duration(milliseconds: 1500), generation);
    if (!_isCurrentPlay(generation)) break;

    await _speakLine(word.hiragana, 'ja-JP', generation);
    if (!_isCurrentPlay(generation)) break;
    await _pause(const Duration(seconds: 2), generation);
    if (!_isCurrentPlay(generation)) break;

    if (!mounted || generation != _playGeneration) break;
    setState(() {
      showPlayingJapanese = false;
    });

    await _speakLine(word.meaning, 'zh-TW', generation);
    if (!_isCurrentPlay(generation)) break;

    index = _nextPlayIndex(list.length, index);
  }

  if (mounted && generation == _playGeneration) {
    setState(() {
      isPlayingFavorites = false;
      showAnswer = false;
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

  await flutterTts.stop();

  int nextIndex;

  do {

    nextIndex =
        random.nextInt(
          favoriteWords.length,
        );

  } while (
    nextIndex == currentIndex &&
    favoriteWords.length > 1
  );

  setState(() {

    currentIndex = nextIndex;

    showAnswer = false;

  });
}

  @override
  Widget build(BuildContext context) {
 if (favoriteWords.isEmpty) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'Favorite Words',
      ),
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
    title: const Text(
      'Favorite Words',
    ),
  ),

 body: isPlayingFavorites
      ? _playingFavoritesView()
      : LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Center(
                  child: _favoriteCard(),
                ),
                Positioned(
                  top: constraints.maxHeight * 0.10,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: playAllFavorites,
                      child: const Text(
                        'Playing favorite words',
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
        SizedBox(
          height: 120,
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: showPlayingJapanese ? 48 : 40,
                fontWeight: FontWeight.bold,
                color: showPlayingJapanese
                    ? Colors.black
                    : Colors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox.fromSize(
          size: _actionButtonSize,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: _actionButtonSize,
              minimumSize: _actionButtonSize,
              maximumSize: _actionButtonSize,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: stopPlayingFavorites,
            child: const Text('Stop'),
          ),
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
          japanese: currentWord.hiragana,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        )
      : Text(
          currentWord.kanji,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),

  IconButton(
    iconSize: 40,
    tooltip: 'Remove from favorites',
    icon: const Icon(
      Icons.star,
      color: Colors.amber,
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
                japanese: currentWord.hiragana,
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                currentWord.romaji,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentWord.wordType,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 10),
              speakableText(
                text: currentWord.meaning,
                japanese: currentWord.hiragana,
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.blue,
                ),
              ),
            ],
          )
        : const SizedBox.shrink(),
  ),

  SizedBox.fromSize(
    size: _actionButtonSize,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        fixedSize: _actionButtonSize,
        minimumSize: _actionButtonSize,
        maximumSize: _actionButtonSize,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: showAnswer ? nextFavorite : showCurrentAnswer,
      child: Text(showAnswer ? 'Next' : 'Show Answer'),
    ),
  ),
    ],
  );
}
}