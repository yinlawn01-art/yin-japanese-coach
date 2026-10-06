import 'dart:async';

import 'package:flutter/material.dart';

import 'app_look.dart';
import 'example_patterns.dart';
import 'kana_page.dart';

class ExamplePatternMenuPage extends StatefulWidget {
  const ExamplePatternMenuPage({super.key});

  @override
  State<ExamplePatternMenuPage> createState() => _ExamplePatternMenuPageState();
}

class _ExamplePatternMenuPageState extends State<ExamplePatternMenuPage> {
  bool ready = false;

  @override
  void initState() {
    super.initState();
    if (examplePatterns.isNotEmpty) {
      ready = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    await loadExamplePatterns();
    if (!mounted) return;
    setState(() {
      ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('例句')),
      body: ready
          ? SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final pattern in examplePatterns)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: 64 * 0.9,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(64 * 0.9),
                            maximumSize: const Size.fromHeight(64 * 0.9),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ExamplePatternStudyPage(pattern: pattern),
                              ),
                            );
                          },
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              pattern.buttonLabel,
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(
                                fontSize: 22 * 0.9,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class ExamplePatternStudyPage extends StatefulWidget {
  const ExamplePatternStudyPage({super.key, required this.pattern});

  final ExamplePattern pattern;

  @override
  State<ExamplePatternStudyPage> createState() =>
      _ExamplePatternStudyPageState();
}

class _ExamplePatternStudyPageState extends State<ExamplePatternStudyPage> {
  final KanaSpeaker speaker = KanaSpeaker();
  int index = 0;
  bool showAnswer = false;
  bool dropAfterContinue = false;
  bool ready = false;

  PatternSentence get sentence => widget.pattern.sentences[index];

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
    await loadExampleFavorites();
    if (!mounted) return;
    setState(() {
      ready = true;
    });
  }

  Future<void> _toggleFavorite() async {
    final text = sentence.japanese;
    setState(() {
      if (!exampleFavorites.add(text)) {
        exampleFavorites.remove(text);
      }
    });
    await saveExampleFavorites();
  }

  void _toggleRemoveLater() {
    if (!exampleFavorites.contains(sentence.japanese)) return;
    setState(() {
      dropAfterContinue = !dropAfterContinue;
    });
  }

  void _speak() {
    final token = speaker.begin();
    unawaited(speaker.speakRomaji(sentence.romaji, token));
  }

  Widget _spokenLine(String text, TextStyle style) {
    return kanaSpeakable(text: text, style: style, onTap: _speak);
  }

  Future<void> _showAnswer() async {
    final romaji = sentence.romaji;
    setState(() {
      showAnswer = true;
      dropAfterContinue = false;
    });
    final token = speaker.begin();
    await speaker.speakRomaji(romaji, token);
    if (!mounted || token != speaker.generation) return;
    await speaker.pause(const Duration(milliseconds: 500), token);
    if (!mounted || token != speaker.generation) return;
    await speaker.speakRomaji(romaji, token);
  }

  void _next() {
    final removing = dropAfterContinue;
    final text = sentence.japanese;
    setState(() {
      if (removing) exampleFavorites.remove(text);
      dropAfterContinue = false;
      showAnswer = false;
      final total = widget.pattern.sentences.length;
      if (total > 0) index = (index + 1) % total;
    });
    unawaited(speaker.stop());
    if (removing) unawaited(saveExampleFavorites());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pattern.label)),
      body: ready
          ? LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: showAnswer ? _answer() : _front(),
                      ),
                    ),
                  ),
                );
              },
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _front() {
    final favorite = exampleFavorites.contains(sentence.japanese);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _spokenLine(
          sentence.japanese,
          const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: lookInk,
          ),
        ),
        kanaStar(
          favorite: favorite,
          onPressed: _toggleFavorite,
          tooltip: '收藏例句',
        ),
        const SizedBox(height: 24),
        kanaActionButton('答案', () {
          unawaited(_showAnswer());
        }, kanaLabelSize(context)),
      ],
    );
  }

  Widget _answer() {
    final favorite =
        exampleFavorites.contains(sentence.japanese) && !dropAfterContinue;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        kanaStar(
          favorite: favorite,
          onPressed: _toggleRemoveLater,
          tooltip: 'Remove from favorites',
        ),
        _spokenLine(
          sentence.japanese,
          const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: lookInk,
          ),
        ),
        const SizedBox(height: 8),
        _spokenLine(
          sentence.hiragana,
          const TextStyle(fontSize: 24, height: 1.1, color: lookReading),
        ),
        const SizedBox(height: 4),
        _spokenLine(
          sentence.romaji,
          const TextStyle(
            fontSize: 24,
            height: 1.1,
            color: lookRomaji,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sentence.chinese,
          textAlign: TextAlign.center,
          style: lookMeaningStyle,
        ),
        const SizedBox(height: 24),
        kanaActionButton('繼續', _next, kanaLabelSize(context)),
      ],
    );
  }
}
