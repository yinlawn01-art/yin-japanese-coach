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

Future<void> showCurrentAnswer() async {
  setState(() {
    showAnswer = true;
  });

  await flutterTts.setLanguage('ja-JP');
  await flutterTts.setSpeechRate(0.4);
  await flutterTts.speak(currentWord.hiragana);
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

 body: Center(
  
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    
children: [

  Text(
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
              Text(
                currentWord.hiragana,
                textAlign: TextAlign.center,
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
              Text(
                currentWord.meaning,
                textAlign: TextAlign.center,
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

  ),
),
);
  }
}