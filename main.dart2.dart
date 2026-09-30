import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const MyApp());
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

  bool isFavorite;

  Vocabulary({
    required this.kanji,
    required this.hiragana,
    required this.romaji,
    required this.meaning,
    this.isFavorite = false,
  });
}

final List<Vocabulary> words = [
  Vocabulary(
    kanji: '食べる',
    hiragana: 'たべる',
    romaji: 'taberu',
    meaning: '吃',
  ),
  Vocabulary(
    kanji: '飲む',
    hiragana: 'のむ',
    romaji: 'nomu',
    meaning: '喝',
  ),
  Vocabulary(
    kanji: '行く',
    hiragana: 'いく',
    romaji: 'iku',
    meaning: '去',
  ),
  Vocabulary(
    kanji: '見る',
    hiragana: 'みる',
    romaji: 'miru',
    meaning: '看',
  ),
  Vocabulary(
    kanji: '聞く',
    hiragana: 'きく',
    romaji: 'kiku',
    meaning: '聽',
  ),
];
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {

  int get favoriteCount =>
      words.where((w) => w.isFavorite).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yin Japanese Coach'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Start Today\'s Study'),
            ),
            const SizedBox(height: 10),
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
                  builder: (context) => const ListeningPage(),
                ),
              );
            },
            child: const Text('Listening Mode'),
              ),
            const SizedBox(height: 10),

           ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const FavoritesPage(),
      ),
    ).then((_) {
      setState(() {});
    });
  },
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.star),
      const SizedBox(width: 8),
      Text(
        'Favorites ($favoriteCount)',
      ),
    ],
  ),
),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Settings'),
            ),
          ],
        ),
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Word ${currentIndex + 1} / ${words.length}',
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              word.kanji,
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

            const SizedBox(height: 30),
            if (showAnswer) ...[
              Text(
                word.hiragana,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 10),
              Text(
                word.romaji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 10),
              Text(
                word.meaning,
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.blue,
                ),
              ),
            ],
            
           IconButton(
  iconSize: 40,
  icon: Icon(
    word.isFavorite
        ? Icons.star
        : Icons.star_border,
    color: Colors.amber,
  ),
  onPressed: () {
    setState(() {
      word.isFavorite = !word.isFavorite;
    });
  },
),

            
            
            
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
                setState(() {
                  currentIndex =
                      (currentIndex + 1) % words.length;
                  showAnswer = false;
                });
              },
              child: const Text('Next Word'),
            ),
          ],
        ),
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

      body: ListView.builder(
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
    );
  }
}