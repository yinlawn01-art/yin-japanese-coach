import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'bundled_text.dart';
import 'kana_data.dart';
import 'romaji_speech.dart';
import 'soft_speech.dart';

const Size kanaButtonSize = Size(336, 64);
const double _answerSlotHeight = 210;

class KanaSpeaker {
  KanaSpeaker() : tts = FlutterTts();

  final FlutterTts tts;
  int generation = 0;
  Completer<void>? _done;

  int begin() {
    final pending = _done;
    if (pending != null && !pending.isCompleted) {
      pending.complete();
    }
    return ++generation;
  }

  Future<void> stop() async {
    begin();
    try {
      await tts.stop();
    } catch (_) {}
  }

  Future<void> speakRomaji(String romaji, int token) async {
    if (token != generation || romaji.isEmpty) return;
    try {
      final done = Completer<void>();
      _done = done;
      void finish() {
        if (!done.isCompleted) done.complete();
      }

      tts.setCompletionHandler(finish);
      tts.setErrorHandler((_) => finish());
      tts.setCancelHandler(finish);
      await applyNaturalVoice(tts, 'ja-JP');
      if (token != generation) {
        finish();
        return;
      }
      await tts.speak(pronunciationForRomaji(romaji));
      await done.future.timeout(const Duration(seconds: 8), onTimeout: finish);
    } catch (_) {}
  }

  Future<void> speakChinese(String text, int token) async {
    if (token != generation || text.isEmpty) return;
    try {
      final done = Completer<void>();
      _done = done;
      void finish() {
        if (!done.isCompleted) done.complete();
      }

      tts.setCompletionHandler(finish);
      tts.setErrorHandler((_) => finish());
      tts.setCancelHandler(finish);
      await applyNaturalVoice(tts, 'zh-TW');
      if (token != generation) {
        finish();
        return;
      }
      await tts.speak(text);
      await done.future.timeout(const Duration(seconds: 8), onTimeout: finish);
    } catch (_) {}
  }

  Future<void> pause(Duration duration, int token) async {
    const step = Duration(milliseconds: 100);
    var elapsed = Duration.zero;
    while (elapsed < duration) {
      if (token != generation) return;
      await Future.delayed(step);
      elapsed += step;
    }
  }

  Future<void> reveal(KanaCard card, int token) async {
    await speakRomaji(card.romaji, token);
    if (token != generation) return;
    await pause(const Duration(milliseconds: 800), token);
    if (token != generation) return;
    await speakRomaji(card.exampleRomaji, token);
  }
}

double kanaActionButtonTop({
  required double bodyHeight,
  required double bodyWidth,
  required String countText,
  required String kana,
  required TextStyle countStyle,
  required TextStyle kanaStyle,
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
  final contentHeight =
      line(countText, countStyle) +
      gap +
      line(kana, kanaStyle) +
      iconHeight +
      _answerSlotHeight +
      kanaButtonSize.height;
  final paddedHeight = contentHeight + 48;
  final columnTop = (bodyHeight - paddedHeight) / 2;
  return columnTop + 24 + contentHeight - kanaButtonSize.height;
}

double kanaLabelSize(BuildContext context) {
  return (Theme.of(context).textTheme.labelLarge?.fontSize ?? 14) * 2;
}

Widget kanaActionButton(String label, VoidCallback onPressed, double fontSize) {
  return SizedBox.fromSize(
    size: kanaButtonSize,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        fixedSize: kanaButtonSize,
        minimumSize: kanaButtonSize,
        maximumSize: kanaButtonSize,
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

Widget kanaSpeakable({
  required String text,
  required TextStyle style,
  required VoidCallback onTap,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Text(text, textAlign: TextAlign.center, style: style),
    ),
  );
}

Widget kanaStar({
  required bool favorite,
  required VoidCallback onPressed,
  bool compact = false,
  String? tooltip,
}) {
  return IconButton(
    iconSize: compact ? 32 : 40,
    padding: compact ? EdgeInsets.zero : null,
    visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
    constraints: compact
        ? const BoxConstraints.tightFor(width: 40, height: 40)
        : null,
    tooltip: tooltip,
    icon: Icon(favorite ? Icons.star : Icons.star_border, color: Colors.amber),
    onPressed: onPressed,
  );
}

class KanaMenuPage extends StatelessWidget {
  const KanaMenuPage({super.key});

  void _open(BuildContext context, String title, List<KanaCard> cards) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KanaStudyPage(title: title, cards: cards),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      fixedSize: kanaButtonSize,
      minimumSize: kanaButtonSize,
      maximumSize: kanaButtonSize,
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: bundledText.copyWith(fontSize: 28),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('五十音')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: buttonStyle,
                onPressed: () => _open(context, '平假名', hiraganaCards),
                child: const Text('平假名'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: buttonStyle,
                onPressed: () => _open(context, '片假名', katakanaCards),
                child: const Text('片假名'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KanaStudyPage extends StatefulWidget {
  const KanaStudyPage({super.key, required this.title, required this.cards});

  final String title;
  final List<KanaCard> cards;

  @override
  State<KanaStudyPage> createState() => _KanaStudyPageState();
}

class _KanaStudyPageState extends State<KanaStudyPage> {
  final KanaSpeaker speaker = KanaSpeaker();
  int currentIndex = 0;
  bool showAnswer = false;

  KanaCard get card => widget.cards[currentIndex];

  @override
  void initState() {
    super.initState();
    loadKanaFavorites().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    speaker.stop();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      card.isFavorite = !card.isFavorite;
    });
    await saveKanaFavorites();
  }

  Future<void> _continue() async {
    if (showAnswer) {
      await speaker.stop();
      if (!mounted || widget.cards.isEmpty) return;
      setState(() {
        currentIndex = (currentIndex + 1) % widget.cards.length;
        showAnswer = false;
      });
      return;
    }

    final current = card;
    final token = speaker.begin();
    setState(() {
      showAnswer = true;
    });
    await speaker.reveal(current, token);
  }

  void _speakKana() {
    final token = speaker.begin();
    speaker.speakRomaji(card.romaji, token);
  }

  void _speakExample() {
    final token = speaker.begin();
    speaker.speakRomaji(card.exampleRomaji, token);
  }

  @override
  Widget build(BuildContext context) {
    final current = card;
    final countText = '${currentIndex + 1} / ${widget.cards.length}';
    final fontSize = kanaLabelSize(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = MediaQuery.sizeOf(context).height;
          final exampleTop =
              (screenHeight * 0.30 - (screenHeight - constraints.maxHeight))
                  .clamp(0.0, constraints.maxHeight);
          final baseStyle = DefaultTextStyle.of(context).style;
          final buttonTop = kanaActionButtonTop(
            bodyHeight: constraints.maxHeight,
            bodyWidth: constraints.maxWidth,
            countText: countText,
            kana: current.kana,
            countStyle: baseStyle.merge(const TextStyle(fontSize: 20)),
            kanaStyle: baseStyle.merge(
              const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            textScaler: MediaQuery.textScalerOf(context),
          );
          final contentBottom = (constraints.maxHeight - buttonTop + 8).clamp(
            0.0,
            constraints.maxHeight,
          );

          return Stack(
            children: [
              if (showAnswer)
                Positioned(
                  top: exampleTop,
                  left: 0,
                  right: 0,
                  bottom: contentBottom,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _revealed(current, countText),
                  ),
                ),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      showAnswer
                          ? ExcludeSemantics(
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: 0,
                                  child: _front(current, countText),
                                ),
                              ),
                            )
                          : _front(current, countText),
                      kanaActionButton('繼續', _continue, fontSize),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _front(KanaCard current, String countText) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          countText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 40),
        Text(
          current.kana,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        kanaStar(favorite: current.isFavorite, onPressed: _toggleFavorite),
        const SizedBox(height: _answerSlotHeight),
      ],
    );
  }

  Widget _revealed(KanaCard current, String countText) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          countText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, height: 1.1),
        ),
        const SizedBox(height: 8),
        kanaSpeakable(
          text: current.kana,
          onTap: _speakKana,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        kanaStar(
          favorite: current.isFavorite,
          onPressed: _toggleFavorite,
          compact: true,
        ),
        kanaSpeakable(
          text: current.romaji,
          onTap: _speakKana,
          style: const TextStyle(
            fontSize: 24,
            height: 1.1,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 4),
        kanaSpeakable(
          text: current.example,
          onTap: _speakExample,
          style: const TextStyle(
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        kanaSpeakable(
          text: current.exampleRomaji,
          onTap: _speakExample,
          style: const TextStyle(
            fontSize: 24,
            height: 1.1,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          current.exampleChinese,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, height: 1.1, color: Colors.blue),
        ),
      ],
    );
  }
}

class FavoriteKanaPage extends StatefulWidget {
  const FavoriteKanaPage({super.key});

  @override
  State<FavoriteKanaPage> createState() => _FavoriteKanaPageState();
}

class _FavoriteKanaPageState extends State<FavoriteKanaPage> {
  final KanaSpeaker speaker = KanaSpeaker();
  final Random random = Random();
  int currentIndex = 0;
  bool showAnswer = false;
  bool dropAfterContinue = false;
  bool isPlaying = false;
  _PlayPhase playPhase = _PlayPhase.kana;
  KanaCard? playingCard;

  List<KanaCard> get favorites => favoriteKanaCards;

  KanaCard get card => favorites[currentIndex];

  @override
  void initState() {
    super.initState();
    loadKanaFavorites().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    speaker.stop();
    super.dispose();
  }

  Future<void> _removeFavorite() async {
    card.isFavorite = false;
    if (!mounted) return;
    setState(() {
      showAnswer = false;
      if (favorites.isEmpty) {
        currentIndex = 0;
      } else if (currentIndex >= favorites.length) {
        currentIndex = favorites.length - 1;
      }
    });
    unawaited(speaker.stop());
    await saveKanaFavorites();
  }

  void _toggleRemoveLater() {
    setState(() {
      dropAfterContinue = !dropAfterContinue;
    });
  }

  Future<void> _showAnswer() async {
    final current = card;
    final token = speaker.begin();
    setState(() {
      showAnswer = true;
      dropAfterContinue = false;
    });
    await speaker.reveal(current, token);
  }

  Future<void> _next() async {
    final removing = dropAfterContinue;
    if (removing) {
      card.isFavorite = false;
    }
    dropAfterContinue = false;
    if (!mounted) return;
    if (favorites.isEmpty) {
      setState(() {
        currentIndex = 0;
        showAnswer = false;
      });
    } else {
      var nextIndex = 0;
      if (favorites.length > 1) {
        if (removing) {
          nextIndex = currentIndex >= favorites.length
              ? favorites.length - 1
              : currentIndex;
        } else {
          do {
            nextIndex = random.nextInt(favorites.length);
          } while (nextIndex == currentIndex);
        }
      }
      setState(() {
        currentIndex = nextIndex;
        showAnswer = false;
      });
    }
    unawaited(speaker.stop());
    if (removing) await saveKanaFavorites();
  }

  bool _isPlaying(int token) {
    return mounted && isPlaying && token == speaker.generation;
  }

  Future<void> _playAll() async {
    if (isPlaying || favorites.isEmpty) return;
    final token = speaker.begin();
    var index = random.nextInt(favorites.length);
    setState(() {
      isPlaying = true;
      playPhase = _PlayPhase.kana;
      playingCard = favorites[index];
    });

    while (_isPlaying(token)) {
      final list = favorites;
      if (list.isEmpty) break;
      if (index >= list.length) index = 0;
      final current = list[index];
      if (!_isPlaying(token)) break;
      setState(() {
        playingCard = current;
        playPhase = _PlayPhase.kana;
      });
      await speaker.speakRomaji(current.romaji, token);
      if (!_isPlaying(token)) break;
      await speaker.pause(const Duration(milliseconds: 800), token);
      if (!_isPlaying(token)) break;

      setState(() {
        playPhase = _PlayPhase.example;
      });
      await speaker.speakRomaji(current.exampleRomaji, token);
      if (!_isPlaying(token)) break;
      await speaker.pause(const Duration(seconds: 2), token);
      if (!_isPlaying(token)) break;

      final chineseShownAt = DateTime.now();
      setState(() {
        playPhase = _PlayPhase.chinese;
      });
      await speaker.speakChinese(current.exampleChinese, token);
      if (!_isPlaying(token)) break;
      final visibleFor = DateTime.now().difference(chineseShownAt);
      const minimumChineseTime = Duration(seconds: 2);
      if (visibleFor < minimumChineseTime) {
        await speaker.pause(minimumChineseTime - visibleFor, token);
      }
      if (!_isPlaying(token)) break;
      index = _nextPlayIndex(list.length, index);
    }

    if (mounted && token == speaker.generation) {
      setState(() {
        isPlaying = false;
        showAnswer = false;
      });
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

  Future<void> _stopPlaying() async {
    isPlaying = false;
    await speaker.stop();
    if (!mounted) return;
    setState(() {
      isPlaying = false;
      showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('收藏五十音')),
        body: const Center(child: Text('還沒有收藏五十音。')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('收藏五十音')),
      body: isPlaying ? _playingView() : _cardView(),
    );
  }

  Widget _playingView() {
    final current = playingCard;
    final japanese = playPhase != _PlayPhase.chinese;
    final text = current == null
        ? ''
        : switch (playPhase) {
            _PlayPhase.kana => current.kana,
            _PlayPhase.example => current.example,
            _PlayPhase.chinese => current.exampleChinese,
          };

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
                  fontSize: japanese ? 48 : 40,
                  fontWeight: FontWeight.bold,
                  color: japanese ? Colors.black : Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          kanaActionButton('Stop', _stopPlaying, kanaLabelSize(context)),
        ],
      ),
    );
  }

  Widget _cardView() {
    final current = card;
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final exampleTop =
            (screenHeight * 0.30 - (screenHeight - constraints.maxHeight))
                .clamp(0.0, constraints.maxHeight);
        final fontSize = kanaLabelSize(context);
        final baseStyle = DefaultTextStyle.of(context).style;
        final countText = '${currentIndex + 1} / ${favorites.length}';
        final buttonTop = kanaActionButtonTop(
          bodyHeight: constraints.maxHeight,
          bodyWidth: constraints.maxWidth,
          countText: countText,
          kana: current.kana,
          countStyle: baseStyle.merge(const TextStyle(fontSize: 20)),
          kanaStyle: baseStyle.merge(
            const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          textScaler: MediaQuery.textScalerOf(context),
        );
        final answerBottom = (constraints.maxHeight - buttonTop + 8).clamp(
          0.0,
          constraints.maxHeight,
        );
        final playTop =
            (screenHeight * 0.10 - (screenHeight - constraints.maxHeight))
                .clamp(0.0, constraints.maxHeight);

        return Stack(
          children: [
            if (showAnswer)
              Positioned(
                top: exampleTop,
                left: 0,
                right: 0,
                bottom: answerBottom,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _revealed(current),
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _front(current),
                ),
              ),
            Positioned(
              top: playTop,
              left: 0,
              right: 0,
              child: Center(
                child: kanaActionButton('播放收藏五十音', _playAll, fontSize),
              ),
            ),
            Positioned(
              top: buttonTop,
              left: 0,
              right: 0,
              child: Center(
                child: kanaActionButton(
                  showAnswer ? '繼續' : '答案',
                  showAnswer ? _next : _showAnswer,
                  fontSize,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _front(KanaCard current) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          current.kana,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        kanaStar(
          favorite: true,
          onPressed: _removeFavorite,
          tooltip: 'Remove from favorites',
        ),
        const SizedBox(height: _answerSlotHeight),
      ],
    );
  }

  Widget _revealed(KanaCard current) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        kanaStar(
          favorite: !dropAfterContinue,
          onPressed: _toggleRemoveLater,
          tooltip: 'Remove from favorites',
        ),
        kanaSpeakable(
          text: current.kana,
          onTap: () {
            final token = speaker.begin();
            speaker.speakRomaji(current.romaji, token);
          },
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        kanaSpeakable(
          text: current.romaji,
          onTap: () {
            final token = speaker.begin();
            speaker.speakRomaji(current.romaji, token);
          },
          style: const TextStyle(
            fontSize: 24,
            height: 1.1,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 4),
        kanaSpeakable(
          text: current.example,
          onTap: () {
            final token = speaker.begin();
            speaker.speakRomaji(current.exampleRomaji, token);
          },
          style: const TextStyle(
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        kanaSpeakable(
          text: current.exampleRomaji,
          onTap: () {
            final token = speaker.begin();
            speaker.speakRomaji(current.exampleRomaji, token);
          },
          style: const TextStyle(
            fontSize: 24,
            height: 1.1,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          current.exampleChinese,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, height: 1.1, color: Colors.blue),
        ),
      ],
    );
  }
}

enum _PlayPhase { kana, example, chinese }
