import 'package:flutter/material.dart';

import 'dart:math';

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

  const SizedBox(height: 30),

if (showAnswer)
  Column(
    children: [

      Text(
        currentWord.hiragana,
        style: const TextStyle(
          fontSize: 28,
          color: Colors.green,
        ),
      ),

      const SizedBox(height: 10),

      Text(
        currentWord.romaji,
        style: const TextStyle(
          fontSize: 24,
          color: Colors.orange,
        ),
      ),

      const SizedBox(height: 10),

      Text(
        currentWord.meaning,
        style: const TextStyle(
          fontSize: 28,
          color: Colors.blue,
        ),
      ),

    ],
  ),

  const SizedBox(height: 30),

ElevatedButton(
  onPressed: () async {

    setState(() {
      showAnswer = true;
    });

    await flutterTts.setLanguage(
      'ja-JP',
    );

    await flutterTts.setSpeechRate(
      0.4,
    );

    await flutterTts.speak(
      currentWord.hiragana,
    );
  },
  child: const Text(
    'Show Answer',
  ),
),

const SizedBox(height: 10),

//ElevatedButton(
  //onPressed: () async {

   // await flutterTts.setLanguage(
   //   'ja-JP',
   // );

  //  await flutterTts.setSpeechRate(
  //    0.4,
  //  );

  //  await flutterTts.speak(
  //    currentWord.kanji,
  //  );

 // },
 // child: const Text(
 //   '🔊 Replay',
 // ),
//),

const SizedBox(height: 10),

ElevatedButton(
  onPressed: nextFavorite,

  child: const Text(
    'Next Favorite',
  ),
),


],

  ),
),
);
  }
}