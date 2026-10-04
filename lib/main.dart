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
import 'romaji_speech.dart';
import 'app_version.dart';
import 'kana_data.dart';
import 'kana_page.dart';
import 'word_study.dart';
import 'learning_page.dart';
import 'example_pattern_page.dart';
import 'example_patterns.dart';

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
  await loadExamplePatterns();

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

  int get kanaFavoriteCount => favoriteKanaCards.length;

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

  await loadKanaFavorites();
  await wordStudy.load();

  if (mounted) setState(() {});
}



  @override
  Widget build(BuildContext context) {
    const buttonHeight = 56.7;
    const buttonFontSize = 28.8;
    final homeButtonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(buttonHeight),
      maximumSize: const Size.fromHeight(buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: buttonFontSize, height: 1.1),
      backgroundColor: const Color(0x99FFFFFF),
      foregroundColor: const Color(0xFF1A4A8A),
      surfaceTintColor: Colors.transparent,
    );

    Widget homeButton(String label, Widget page) {
      return Align(
        child: FractionallySizedBox(
          widthFactor: 0.63,
          child: ElevatedButton(
            style: homeButtonStyle,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              ).then((_) {
                setState(() {});
              });
            },
            child: Text(
              label,
              style: const TextStyle(fontSize: buttonFontSize, height: 1.1),
            ),
          ),
        ),
      );
    }

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
              final titleTop = (screenHeight * 0.15 -
                      (screenHeight - constraints.maxHeight))
                  .clamp(0.0, constraints.maxHeight);

              final phone = constraints.maxWidth <= 480;
              const title = Text(
                '龍吟的學日文APP',
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
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
              );
              final column = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: titleTop),
                  if (phone)
                    const FittedBox(fit: BoxFit.scaleDown, child: title)
                  else
                    title,
                  SizedBox(height: phone ? 12 : 36),
                  Text(
                    'version: $appVersion',
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
                  const SizedBox(height: 8),
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
                  SizedBox(height: phone ? 16 : 30),
                  SizedBox(height: buttonHeight),
                  homeButton('學習', const LearningPage()),
                  const SizedBox(height: 10),
                  homeButton('五十音', const KanaMenuPage()),
                  const SizedBox(height: 10),
                  homeButton('收藏五十音 ($kanaFavoriteCount)', const FavoriteKanaPage()),
                  const SizedBox(height: 10),
                  homeButton('單字(${words.length})', const FlashcardMenuPage()),
                  const SizedBox(height: 10),
                  homeButton(
                    '收藏單字 ($favoriteCount)',
                    const FavoriteFlashcardPage(),
                  ),
                  const SizedBox(height: 10),
                  homeButton('例句', const ExamplePatternMenuPage()),
                ],
              );

              if (phone) {
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: SingleChildScrollView(child: column),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: column,
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

const Size _studyButtonSize = Size(336, 64);

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
      fixedSize: _studyButtonSize,
      minimumSize: _studyButtonSize,
      maximumSize: _studyButtonSize,
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 28),
    );

    final nouns = wordsOfType('名詞');
    final verbs = wordsOfType('動詞');
    final adjectives = wordsOfType('形容詞');

    return Scaffold(
      appBar: AppBar(
        title: const Text('單字'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => _open(context, nouns),
                  child: Text('名詞(${nouns.length})'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => _open(context, verbs),
                  child: Text('動詞(${verbs.length})'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => _open(context, adjectives),
                  child: Text('形容詞(${adjectives.length})'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () => _open(context, allWordsShuffled()),
                  child: Text('全部(${words.length})'),
                ),
              ],
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

  Future<void> speakJapanese(String romaji) async {
    await flutterTts.stop();
    await applyNaturalVoice(flutterTts, 'ja-JP');
    await flutterTts.speak(pronunciationForRomaji(romaji));
  }

  Future<void> showCurrentAnswer() async {
    final romaji = widget.deck[currentIndex].romaji;

    setState(() {
      showAnswer = true;
    });

    await speakJapanese(romaji);
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
    await speakJapanese(sentence.romaji);
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
        : _studyButtonSize;
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

  /// Top of the action button inside the body, matching Show Answer's place
  /// after the button grows to Next's height around the same center.
  double _actionButtonTop({
    required double bodyHeight,
    required double bodyWidth,
    required String countText,
    required String kanji,
    required TextStyle countStyle,
    required TextStyle kanjiStyle,
    required TextScaler textScaler,
  }) {
    const iconHeight = 56.0;
    const gap = 40.0;
    final contentHeight = _textHeight(countText, countStyle, bodyWidth - 48, textScaler) +
        gap +
        _textHeight(kanji, kanjiStyle, bodyWidth - 48, textScaler) +
        iconHeight +
        _answerSlotHeight +
        _studyButtonSize.height;
    final paddedHeight = contentHeight + 48;
    final columnTop = (bodyHeight - paddedHeight) / 2;
    return columnTop + 24 + contentHeight - _studyButtonSize.height;
  }

  Widget _favoriteStar(Vocabulary word) {
    return IconButton(
      iconSize: 40,
      icon: Icon(
        word.isFavorite ? Icons.star : Icons.star_border,
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
    );
  }

  Widget _frontWord(Vocabulary word) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Word ${currentIndex + 1} / ${widget.deck.length}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
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
        _favoriteStar(word),
        const SizedBox(height: _answerSlotHeight),
      ],
    );
  }

  Widget _answeredWord(Vocabulary word) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Word ${currentIndex + 1} / ${widget.deck.length}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, height: 1.1),
        ),
        const SizedBox(height: 8),
        speakableText(
          text: word.kanji,
          japanese: word.romaji,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          iconSize: 32,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          icon: Icon(
            word.isFavorite ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () async {
            setState(() {
              word.isFavorite = !word.isFavorite;
            });
            await saveFavorites();
          },
        ),
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
          style: const TextStyle(
            fontSize: 28,
            height: 1.1,
            color: Colors.blue,
          ),
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
          final baseStyle = DefaultTextStyle.of(context).style;
          final buttonTop = _actionButtonTop(
            bodyHeight: constraints.maxHeight,
            bodyWidth: constraints.maxWidth,
            countText: 'Word ${currentIndex + 1} / ${widget.deck.length}',
            kanji: word.kanji,
            countStyle: baseStyle.merge(const TextStyle(fontSize: 20)),
            kanjiStyle: baseStyle.merge(
              const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            textScaler: MediaQuery.textScalerOf(context),
          );
          final contentBottom = (constraints.maxHeight - buttonTop + 8)
              .clamp(0.0, constraints.maxHeight);
          final String actionLabel;
          final VoidCallback action;
          if (showExample) {
            actionLabel = 'Go back';
            action = closeExample;
          } else if (showAnswer) {
            actionLabel = '繼續';
            action = nextWord;
          } else {
            actionLabel = '答案';
            action = () {
              showCurrentAnswer();
            };
          }

          return Stack(
            children: [
              if (showExample)
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
                    child: _answeredWord(word),
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
                                  child: _frontWord(word),
                                ),
                              ),
                            )
                          : _frontWord(word),
                      studyActionButton(
                        label: actionLabel,
                        onPressed: action,
                        fontSize: largeLabelSize,
                      ),
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
      await flutterTts.speak(pronunciationForRomaji(word.romaji));

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
        pronunciationForRomaji(word.romaji),
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
