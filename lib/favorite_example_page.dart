import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'example_patterns.dart';
import 'kana_page.dart';

class FavoriteExamplePage extends StatefulWidget {
  const FavoriteExamplePage({super.key});

  @override
  State<FavoriteExamplePage> createState() => _FavoriteExamplePageState();
}

class _FavoriteExamplePageState extends State<FavoriteExamplePage> {
  final KanaSpeaker speaker = KanaSpeaker();
  final Random random = Random();
  int index = 0;
  bool showAnswer = false;
  bool ready = false;
  bool isPlaying = false;
  bool showChinese = false;
  PatternSentence? playing;

  List<PatternSentence> get sentences => favoriteExampleSentences();

  PatternSentence get sentence => sentences[index];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    unawaited(speaker.stop());
    super.dispose();
  }

  Future<void> _load() async {
    await loadExamplePatterns();
    await loadExampleFavorites();
    if (!mounted) return;
    setState(() {
      ready = true;
    });
  }

  bool _isPlaying(int token) {
    return mounted && isPlaying && token == speaker.generation;
  }

  Future<void> _remove() async {
    final japanese = sentence.japanese;
    setState(() {
      exampleFavorites.remove(japanese);
      showAnswer = false;
      if (sentences.isEmpty) {
        index = 0;
      } else if (index >= sentences.length) {
        index = sentences.length - 1;
      }
    });
    unawaited(speaker.stop());
    await saveExampleFavorites();
  }

  Future<void> _showAnswer() async {
    final romaji = sentence.romaji;
    setState(() {
      showAnswer = true;
    });
    final token = speaker.begin();
    await speaker.speakRomaji(romaji, token);
  }

  void _next() {
    final total = sentences.length;
    var nextIndex = 0;
    if (total > 1) {
      do {
        nextIndex = random.nextInt(total);
      } while (nextIndex == index);
    }
    setState(() {
      index = nextIndex;
      showAnswer = false;
    });
    unawaited(speaker.stop());
  }

  int _nextPlayIndex(int length, int current) {
    if (length <= 1) return 0;
    var next = current;
    do {
      next = random.nextInt(length);
    } while (next == current);
    return next;
  }

  Future<void> _playAll() async {
    final list = sentences;
    if (isPlaying || list.isEmpty) return;
    final token = speaker.begin();
    var playIndex = random.nextInt(list.length);
    setState(() {
      isPlaying = true;
      showChinese = false;
      playing = list[playIndex];
    });

    while (_isPlaying(token)) {
      final currentList = sentences;
      if (currentList.isEmpty) break;
      if (playIndex >= currentList.length) playIndex = 0;
      final current = currentList[playIndex];
      setState(() {
        playing = current;
        showChinese = false;
      });

      await speaker.speakRomaji(current.romaji, token);
      if (!_isPlaying(token)) break;
      await speaker.pause(const Duration(milliseconds: 1500), token);
      if (!_isPlaying(token)) break;
      await speaker.speakRomaji(current.romaji, token);
      if (!_isPlaying(token)) break;
      await speaker.pause(const Duration(seconds: 2), token);
      if (!_isPlaying(token)) break;

      final shownAt = DateTime.now();
      setState(() {
        showChinese = true;
      });
      await speaker.speakChinese(current.chinese, token);
      if (!_isPlaying(token)) break;
      final visibleFor = DateTime.now().difference(shownAt);
      const minimumChineseTime = Duration(seconds: 2);
      if (visibleFor < minimumChineseTime) {
        await speaker.pause(minimumChineseTime - visibleFor, token);
      }
      if (!_isPlaying(token)) break;
      playIndex = _nextPlayIndex(currentList.length, playIndex);
    }

    if (mounted && token == speaker.generation) {
      setState(() {
        isPlaying = false;
        showAnswer = false;
      });
    }
  }

  Future<void> _stopPlaying() async {
    isPlaying = false;
    await speaker.stop();
    if (!mounted) return;
    setState(() {
      isPlaying = false;
      showAnswer = false;
    });
  }

  void _speak(String romaji) {
    final token = speaker.begin();
    unawaited(speaker.speakRomaji(romaji, token));
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return Scaffold(
        appBar: AppBar(title: const Text('收藏例句')),
        body: const SizedBox.shrink(),
      );
    }
    if (sentences.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('收藏例句')),
        body: const Center(child: Text('還沒有收藏例句。')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('收藏例句')),
      body: isPlaying ? _playingView() : _cardView(),
    );
  }

  Widget _playingView() {
    final current = playing;
    final text = current == null
        ? ''
        : showChinese
        ? current.chinese
        : current.japanese;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: showChinese ? 32 : 36,
                    fontWeight: FontWeight.bold,
                    color: showChinese ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            kanaActionButton('Stop', () {
              unawaited(_stopPlaying());
            }, kanaLabelSize(context)),
          ],
        ),
      ),
    );
  }

  Widget _cardView() {
    final current = sentence;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final playTop =
            (screenHeight * 0.10 - (screenHeight - constraints.maxHeight))
                .clamp(0.0, constraints.maxHeight);
        return Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _speakable(
                      current.japanese,
                      current.romaji,
                      const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    kanaStar(
                      favorite: true,
                      onPressed: () {
                        unawaited(_remove());
                      },
                      tooltip: 'Remove from favorites',
                    ),
                    if (showAnswer) ...[
                      const SizedBox(height: 8),
                      _speakable(
                        current.hiragana,
                        current.romaji,
                        const TextStyle(
                          fontSize: 24,
                          height: 1.1,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current.romaji,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.1,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current.chinese,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1.1,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    kanaActionButton(
                      showAnswer ? '繼續' : '答案',
                      showAnswer
                          ? _next
                          : () {
                              unawaited(_showAnswer());
                            },
                      kanaLabelSize(context),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: playTop,
              left: 0,
              right: 0,
              child: Center(
                child: kanaActionButton('播放收藏例句', () {
                  unawaited(_playAll());
                }, kanaLabelSize(context)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _speakable(String text, String romaji, TextStyle style) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _speak(romaji),
        child: Text(text, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}
