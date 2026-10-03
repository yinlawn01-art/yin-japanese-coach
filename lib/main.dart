import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'favorite_listening_page.dart';
import 'vocabulary_data.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'favorite_flashcard_page.dart';
import 'soft_speech.dart';
import 'example_sentence.dart';

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
    final homeButtonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(90),
      textStyle: const TextStyle(fontSize: 32),
      backgroundColor: const Color(0xF2FFFFFF),
      foregroundColor: const Color(0xFF1A4A8A),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/homepage_shinkai.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment(0.25, 0.05),
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x22FFFFFF),
                Color(0x33FFF8F2),
                Color(0x44FFFFFF),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: LayoutBuilder(
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
                        shadows: [
                          Shadow(
                            color: Color(0xE6FFFFFF),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Words Loaded: ${words.length}',
                      style: const TextStyle(
                        color: Color(0xFF16325C),
                        shadows: [
                          Shadow(
                            color: Color(0xE6FFFFFF),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: homeButtonStyle,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FlashcardMenuPage(),
                          ),
                        ).then((_) {
                          setState(() {});
                        });
                      },
                      child: const Text('單字'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: homeButtonStyle,
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
                      child: Text('收藏單字 ($favoriteCount)'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        ),
      ),
    );
  }
}

List<Vocabulary> wordsOfType(String type) {
  return words.where((word) => word.wordType.contains(type)).toList();
}

List<Vocabulary> allWordsShuffled() {
  return List<Vocabulary>.from(words)..shuffle();
}

class FlashcardMenuPage extends StatelessWidget {
  const FlashcardMenuPage({super.key});

  void _open(BuildContext context, List<Vocabulary> deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardPage(deck: deck),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(64),
      textStyle: const TextStyle(fontSize: 28),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('單字'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => _open(context, wordsOfType('名詞')),
                  child: const Text('名詞'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => _open(context, wordsOfType('動詞')),
                  child: const Text('動詞'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => _open(context, wordsOfType('形容詞')),
                  child: const Text('形容詞'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => _open(context, allWordsShuffled()),
                  child: const Text('全部'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key, required this.deck});

  final List<Vocabulary> deck;

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
  bool showExample = false;

  static const Size _actionButtonSize = Size(168, 48);
  static const double _answerSlotHeight = 210;

  Future<void> speakJapanese(String text) async {
    await flutterTts.stop();
    await applyNaturalVoice(flutterTts, 'ja-JP');
    await flutterTts.speak(text);
  }

  Future<void> showCurrentAnswer() async {
    final japanese = widget.deck[currentIndex].hiragana;

    setState(() {
      showAnswer = true;
    });

    await speakJapanese(japanese);
  }

  void nextWord() {
    flutterTts.stop();
    setState(() {
      if (widget.deck.isEmpty) return;
      currentIndex = (currentIndex + 1) % widget.deck.length;
      showAnswer = false;
      showExample = false;
    });
  }

  Future<void> openExample() async {
    final sentence = exampleSentenceFor(widget.deck[currentIndex].kanji);
    setState(() {
      showExample = true;
    });
    await speakJapanese(sentence.hiragana);
  }

  void closeExample() {
    flutterTts.stop();
    setState(() {
      showExample = false;
    });
  }

  Widget fixedButton(
    String label,
    VoidCallback onPressed, {
    double? fontSize,
  }) {
    final size = fontSize == null
        ? _actionButtonSize
        : const Size(168, 64);
    return SizedBox.fromSize(
      size: size,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          fixedSize: size,
          minimumSize: size,
          maximumSize: size,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: fontSize == null
              ? null
              : TextStyle(fontSize: fontSize, height: 1.1),
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
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: style,
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
                      japanese: sentence.hiragana,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    speakableText(
                      text: sentence.hiragana,
                      japanese: sentence.hiragana,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 10),
                    speakableText(
                      text: sentence.romaji,
                      japanese: sentence.hiragana,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sentence.chinese,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.blue,
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

  @override
  Widget build(BuildContext context) {
    final word = widget.deck[currentIndex];
    final sentence = exampleSentenceFor(word.kanji);

    final largeLabelSize =
        (Theme.of(context).textTheme.labelLarge?.fontSize ?? 14) * 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('單字'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = MediaQuery.sizeOf(context).height;
          final exampleTop = (screenHeight * 0.30 -
                  (screenHeight - constraints.maxHeight))
              .clamp(0.0, constraints.maxHeight);
          final goBackRoom =
              (constraints.maxHeight - _actionButtonSize.height)
                  .clamp(0.0, constraints.maxHeight);
          final goBackBottom =
              (screenHeight * 0.40).clamp(0.0, goBackRoom);
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: showExample
                        ? Padding(
                            padding: EdgeInsets.only(
                              bottom: goBackBottom + _actionButtonSize.height,
                            ),
                            child: exampleBody(sentence),
                          )
                        : LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Align(
                alignment:
                    showAnswer ? Alignment.topCenter : Alignment.center,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    showAnswer ? exampleTop + 64 + 20 : 24,
                    24,
                    24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Word ${currentIndex + 1} / ${widget.deck.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 40),
                      showAnswer
                          ? speakableText(
                              text: word.kanji,
                              japanese: word.hiragana,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text(
                              word.kanji,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
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
                      SizedBox(
                        height: _answerSlotHeight,
                        child: showAnswer
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  speakableText(
                                    text: word.hiragana,
                                    japanese: word.hiragana,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(height: 10),
                                  speakableText(
                                    text: word.romaji,
                                    japanese: word.hiragana,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.orange,
                                    ),
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
                                  speakableText(
                                    text: word.meaning,
                                    japanese: word.hiragana,
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
                        size: showAnswer
                            ? const Size(168, 64)
                            : _actionButtonSize,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            fixedSize: showAnswer
                                ? const Size(168, 64)
                                : _actionButtonSize,
                            minimumSize: showAnswer
                                ? const Size(168, 64)
                                : _actionButtonSize,
                            maximumSize: showAnswer
                                ? const Size(168, 64)
                                : _actionButtonSize,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: showAnswer ? nextWord : showCurrentAnswer,
                          child: Text(
                            showAnswer ? 'Next' : 'Show Answer',
                            style: showAnswer
                                ? TextStyle(
                                    fontSize: largeLabelSize,
                                    height: 1.1,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
                  ),
                ],
              ),
              if (showExample)
                Positioned(
                  bottom: goBackBottom,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: fixedButton('Go back', closeExample),
                  ),
                ),
              if (showAnswer && !showExample)
                Positioned(
                  top: exampleTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: fixedButton(
                      '例句',
                      () {
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

    for (var word in words) {
      if (!isPlaying) break;

      setState(() {
        currentWord = word.kanji;
      });

      await applyNaturalVoice(flutterTts, 'ja-JP');
      await flutterTts.speak(word.hiragana);

      await Future.delayed(
        const Duration(seconds: 3),
      );

      await applyNaturalVoice(flutterTts, 'zh-TW');
      await flutterTts.speak(word.meaning);

      await Future.delayed(
        const Duration(seconds: 3),
      );
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

      await applyNaturalVoice(flutterTts, 'ja-JP');
      await flutterTts.speak(
        word.hiragana,
      );

      await Future.delayed(
        const Duration(seconds: 3),
      );

      await applyNaturalVoice(flutterTts, 'zh-TW');
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
