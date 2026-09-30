import 'package:flutter/material.dart';

import 'main.dart';

import 'vocabulary_data.dart';

class FavoriteFlashcardPage extends StatefulWidget {
  const FavoriteFlashcardPage({super.key});

  @override
  State<FavoriteFlashcardPage> createState() =>
      _FavoriteFlashcardPageState();
}

class _FavoriteFlashcardPageState
    extends State<FavoriteFlashcardPage> {

  List<Vocabulary> get favoriteWords =>
      words
          .where((w) => w.isFavorite)
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorite Flashcards',
        ),
      ),

      body: Center(
        child: Text(
          'Favorites: ${favoriteWords.length}',
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}