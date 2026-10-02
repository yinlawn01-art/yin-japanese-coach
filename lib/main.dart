import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'favorite_listening_page.dart';
import 'vocabulary_data.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'favorite_flashcard_page.dart';

Future<void> loadJsonFile(
  String path,
  String wordType,
) async {

  final jsonString =
      await rootBundle.loadString(path);

  final List<dynamic> jsonData =
      json.decode(jsonString);

  words.addAll(

    jsonData.map(

      (item) => Vocabulary.fromJson(
        item,
        wordType,
      ),

    ),

  );
}

Future<void> loadWords() async {
  words.clear();

await loadJsonFile(
  'assets/n5_verbs.json',
  '🟢 動詞',
);

await loadJsonFile(
  'assets/n5_nouns.json',
  '🔵 名詞',
);

await loadJsonFile(
  'assets/n5_adjectives.json',
  '🟣 形容詞',
);

await loadJsonFile(
  'assets/n5_words.json',
  '📚 單字',
);
}





void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await loadWords();

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yin Japanese Coach',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}
class Vocabulary {
  final String kanji;
  final String hiragana;
  final String romaji;
  final String meaning;
  final String wordType;

  bool isFavorite;

Vocabulary({
  required this.kanji,
  required this.hiragana,
  required this.romaji,
  required this.meaning,
  required this.wordType,
  this.isFavorite = false,
});

  factory Vocabulary.fromJson(
    Map<String, dynamic> json,
    String wordType,
  ) {
    return Vocabulary(
      kanji: json['kanji'],
      hiragana: json['hiragana'],
      romaji: json['romaji'],
      meaning: json['meaning'],
      wordType: wordType,
    );
  }
}


class HomePage extends StatefulWidget {
  
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {

  int get favoriteCount =>
      words.where((w) => w.isFavorite).length;

@override
void initState() {
  super.initState();
  loadFavoritesHome();
}




Future<void> loadFavoritesHome() async {
  final prefs = await SharedPreferences.getInstance();

  final favorites =
      prefs.getStringList('favorites') ?? [];

  for (var word in words) {
    word.isFavorite =
        favorites.contains(word.kanji);
  }

  setState(() {});
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yin Japanese Coach'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = MediaQuery.sizeOf(context).height;
          final titleTop = (screenHeight * 0.20 -
                  (screenHeight - constraints.maxHeight))
              .clamp(0.0, constraints.maxHeight);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: titleTop),
                const Text(
                  '龍吟的日本課程',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'LXGW WenKai',
                    fontSize: 42,
                    color: Color(0xFF0A2F6B),
                    letterSpacing: 4,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '0 / 10 Words',
                  style: TextStyle(fontSize: 20),
                ),
                const Text(
                  'N5 Vocabulary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Words Loaded: ${words.length}',
                ),
                Text(
                  'Favorites: $favoriteCount',
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FlashcardPage(),
                      ),
                    ).then((_) {
                      setState(() {});
                    });
                  },
                  child: const Text('Flashcards'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoriteFlashcardPage(),
                      ),
                    ).then((_) {
                      setState(() {});
                    });
                  },
                  child: Text('Favorite Words ($favoriteCount)'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FlashcardPage extends StatefulWidget {

  const FlashcardPage({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {

@override
void initState() {
  super.initState();
  //oadFavorites();
}

Future<void> saveFavorites() async {
  final prefs = await SharedPreferences.getInstance();

  final favorites =
      words
          .where((w) => w.isFavorite)
          .map((w) => w.kanji)
          .toList();

  await prefs.setStringList(
    'favorites',
    favorites,
  );

  final check =
      prefs.getStringList('favorites');

  print("Immediately Read Back: $check");
}


  final FlutterTts flutterTts = FlutterTts();

  int currentIndex = 0;
  bool showAnswer = false;

  Future<void> speakJapanese(String text) async {

  await flutterTts.stop();

  await flutterTts.setLanguage("ja-JP");

  await flutterTts.setSpeechRate(0.4);

  await flutterTts.speak(text);
}

  @override
  Widget build(BuildContext context) {
    final word = words[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Word ${currentIndex + 1} / ${words.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        word.kanji,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      IconButton(
                        iconSize: 60,
                        icon: const Icon(Icons.volume_up),
                        onPressed: () {
                          speakJapanese(word.hiragana);
                        },
                      ),
                      IconButton(
                        iconSize: 40,
                        icon: Icon(
                          word.isFavorite
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () async {
                          setState(() {
                            word.isFavorite = !word.isFavorite;
                          });

                          await saveFavorites();

                          print(
                            "Saved Favorites: "
                            "${words.where((w) => w.isFavorite).map((w) => w.kanji).toList()}"
                          );
                        },
                      ),
                      if (showAnswer) ...[
                        const SizedBox(height: 24),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              word.hiragana,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              word.romaji,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '詞性：${word.wordType}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              word.meaning,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showAnswer = true;
                          });
                        },
                        child: const Text('Show Answer'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          final random = Random();

                          int nextIndex;

                          do {
                            nextIndex = random.nextInt(words.length);
                          } while (nextIndex == currentIndex &&
                              words.length > 1);

                          setState(() {
                            currentIndex = nextIndex;
                            showAnswer = false;
                          });
                        },
                        child: const Text('Next Word'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

  }
}
class ListeningPage extends StatefulWidget {
  const ListeningPage({super.key});

  @override
  State<ListeningPage> createState() => _ListeningPageState();
}

class _ListeningPageState extends State<ListeningPage> {
  final FlutterTts flutterTts = FlutterTts();

  bool isPlaying = false;
  String currentWord = "Ready";

@override
void dispose() {
  flutterTts.stop();
  super.dispose();
}

  Future<void> startListening() async {
    setState(() {
      isPlaying = true;
    });

    await flutterTts.setLanguage("ja-JP");
    await flutterTts.setSpeechRate(0.4);

    for (var word in words) {
      if (!isPlaying) break;

      setState(() {
        currentWord = word.kanji;
      });

      await flutterTts.speak(word.hiragana);

      await Future.delayed(
        const Duration(seconds: 3),
      );

      await flutterTts.setLanguage("zh-TW");

      await flutterTts.speak(word.meaning);

      await Future.delayed(
        const Duration(seconds: 3),
      );

      await flutterTts.setLanguage("ja-JP");
    }

    setState(() {
      isPlaying = false;
      currentWord = "Finished";
    });
  }

  Future<void> stopListening() async {
    await flutterTts.stop();

    setState(() {
      isPlaying = false;
      currentWord = "Stopped";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Listening Mode"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Text(
              "Japanese Audio Coach",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              currentWord,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 42,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: isPlaying
                  ? null
                  : startListening,
              child: const Text(
                "Start Listening",
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: stopListening,
              child: const Text(
                "Stop",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {

    final favoriteWords =
        words.where((w) => w.isFavorite).toList();
       

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
      ),

   body: Column(
  children: [
    Padding(
      padding: const EdgeInsets.all(12),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FavoriteListeningPage(),
            ),
          );
        },
        child: const Text(
          "▶ Play Favorites",
        ),
      ),
    ),
    Expanded(
      child: ListView.builder(
        itemCount: favoriteWords.length,
        itemBuilder: (context, index) {

          final word = favoriteWords[index];

          return ListTile(
            leading: const Icon(
              Icons.star,
              color: Colors.amber,
            ),

            title: Text(word.kanji),

            subtitle: Text(
              "${word.hiragana} • ${word.meaning}",
            ),
          );
        },
      ),
    ),
 ],
    ),
  );
}
}
class FavoriteListeningPage extends StatefulWidget {
  FavoriteListeningPage({super.key});

  @override
  State<FavoriteListeningPage> createState() =>
      _FavoriteListeningPageState();
}

class _FavoriteListeningPageState
    extends State<FavoriteListeningPage> {

  final FlutterTts flutterTts = FlutterTts();

  bool isPlaying = false;

  String currentWord = "Ready";

  List<Vocabulary> get favoriteWords =>
      words
          .where((w) => w.isFavorite)
          .toList();

  Future<void> startPlaying() async {

    setState(() {
      isPlaying = true;
    });

    for (var word in favoriteWords) {

      if (!isPlaying) {
        break;
      }

      setState(() {
        currentWord = word.kanji;
      });

      await flutterTts.setLanguage("ja-JP");

      await flutterTts.speak(
        word.hiragana,
      );

      await Future.delayed(
        const Duration(seconds: 3),
      );

      await flutterTts.setLanguage("zh-TW");

      await flutterTts.speak(
        word.meaning,
      );

      await Future.delayed(
        const Duration(seconds: 3),
      );
    }

    setState(() {
      isPlaying = false;
      currentWord = "Finished";
    });
  }

  Future<void> stopPlaying() async {

    await flutterTts.stop();

    setState(() {
      isPlaying = false;
      currentWord = "Stopped";
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Favorite Listening"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [

            Text(
              currentWord,
              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 42,
                color: Colors.blue,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed:
                  isPlaying
                      ? null
                      : startPlaying,

              child: const Text(
                "Start",
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: stopPlaying,

              child: const Text(
                "Stop",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
