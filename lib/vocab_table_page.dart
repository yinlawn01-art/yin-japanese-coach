import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'app_look.dart';
import 'bundled_text.dart';
import 'main.dart';
import 'romaji_speech.dart';
import 'soft_speech.dart';

/// Yellow used when a table word is in 日→中 收藏單字.
const Color vocabTableSaved = Color(0xFFE6B000);

const List<String> vocabTableHeaders = ['No.', '日文', '羅馬拚音', '假名', '中文'];

const List<int> _columnFlex = [2, 4, 5, 4, 4];

class VocabTableMenuPage extends StatelessWidget {
  const VocabTableMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <(String, List<Vocabulary>)>[
      ('名詞', wordsOfType('名詞')),
      ('動詞', wordsOfType('動詞')),
      ('形容詞', wordsOfType('形容詞')),
      ('副詞', wordsOfType('副詞')),
    ];
    final buttonStyle = ElevatedButton.styleFrom(
      fixedSize: const Size(336, 64),
      minimumSize: const Size(336, 64),
      maximumSize: const Size(336, 64),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: bundledText.copyWith(fontSize: 28),
      backgroundColor: lookCard,
      foregroundColor: lookInkBlue,
      surfaceTintColor: Colors.transparent,
      shape: lookSoftShape,
    );

    return Scaffold(
      backgroundColor: lookPaper,
      appBar: AppBar(title: const Text('單字表')),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            for (final section in sections) ...[
              Center(
                child: ElevatedButton(
                  style: buttonStyle,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VocabTablePage(
                          title: section.$1,
                          deck: section.$2,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    '${section.$1}(${section.$2.length})',
                    style: bundledText.copyWith(fontSize: 28, height: 1.1),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class VocabTablePage extends StatefulWidget {
  const VocabTablePage({
    super.key,
    required this.title,
    required this.deck,
  });

  final String title;
  final List<Vocabulary> deck;

  @override
  State<VocabTablePage> createState() => _VocabTablePageState();
}

class _VocabTablePageState extends State<VocabTablePage> {
  final ScrollController _scroll = ScrollController();
  final FlutterTts _tts = FlutterTts();

  @override
  void dispose() {
    _scroll.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleSaved(Vocabulary word) async {
    setState(() {
      word.isFavorite = !word.isFavorite;
    });
    await saveDirectionFavorites(false);
  }

  Future<void> _speak(Vocabulary word) async {
    await _tts.stop();
    await applyNaturalVoice(_tts, 'ja-JP');
    await _tts.speak(pronunciationForRomaji(word.romaji));
  }

  Widget _cell(
    String text,
    int flex, {
    Key? key,
    VoidCallback? onTap,
    Color color = lookInk,
    FontWeight weight = FontWeight.normal,
  }) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
          child: Text(
            text,
            key: key,
            textAlign: TextAlign.center,
            style: bundledText.copyWith(
              fontSize: 16,
              height: 1.25,
              color: color,
              fontWeight: weight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _row({
    required List<String> values,
    required List<VoidCallback?> taps,
    required List<Color> colors,
    FontWeight weight = FontWeight.normal,
    List<Key?> keys = const [],
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < values.length; i++)
          _cell(
            values[i],
            _columnFlex[i],
            key: i < keys.length ? keys[i] : null,
            onTap: taps[i],
            color: colors[i],
            weight: weight,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lookPaper,
      appBar: AppBar(title: Text('${widget.title}(${widget.deck.length})')),
      body: Column(
        children: [
          Material(
            color: lookCard,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: lookLine, width: 1.4)),
              ),
              child: _row(
                values: vocabTableHeaders,
                taps: const [null, null, null, null, null],
                colors: const [
                  lookInkBlue,
                  lookInkBlue,
                  lookInkBlue,
                  lookInkBlue,
                  lookInkBlue,
                ],
                weight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scroll,
              thumbVisibility: true,
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.only(right: 14, bottom: 24),
                itemCount: widget.deck.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: lookLine,
                ),
                itemBuilder: (context, index) {
                  final word = widget.deck[index];
                  final saved = word.isFavorite ? vocabTableSaved : lookInk;
                  return _row(
                    values: [
                      '${index + 1}',
                      word.kanji,
                      word.romaji,
                      word.hiragana,
                      word.meaning,
                    ],
                    taps: [
                      null,
                      () => _toggleSaved(word),
                      () => _speak(word),
                      () => _speak(word),
                      () => _toggleSaved(word),
                    ],
                    colors: [
                      lookCount,
                      saved,
                      lookRomaji,
                      lookReading,
                      saved,
                    ],
                    keys: [
                      Key('no-$index'),
                      Key('ja-$index'),
                      Key('romaji-$index'),
                      Key('kana-$index'),
                      Key('zh-$index'),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
