import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String exampleFavoritesKey = 'exampleFavorites';

class PatternSentence {
  const PatternSentence({
    required this.japanese,
    required this.hiragana,
    required this.romaji,
    required this.chinese,
  });

  factory PatternSentence.fromJson(Map<String, dynamic> json) {
    return PatternSentence(
      japanese: json['japanese'] as String,
      hiragana: json['hiragana'] as String,
      romaji: json['romaji'] as String,
      chinese: json['chinese'] as String,
    );
  }

  final String japanese;
  final String hiragana;
  final String romaji;
  final String chinese;
}

class ExamplePattern {
  const ExamplePattern({required this.label, required this.sentences});

  final String label;
  final List<PatternSentence> sentences;

  String get buttonLabel => '$label (${sentences.length})';
}

class _PatternFile {
  const _PatternFile(this.asset, this.label);

  final String asset;
  final String label;
}

const List<_PatternFile> _patternFiles = [
  _PatternFile('assets/example_patterns/01.json', '(1)～は～です : A是B'),
  _PatternFile('assets/example_patterns/02.json', '(2)～ですか : ～嗎？'),
  _PatternFile('assets/example_patterns/03.json', '(3)～があります : 有（東西）'),
  _PatternFile('assets/example_patterns/04.json', '(4)～がいます : 有（人、動物）'),
  _PatternFile('assets/example_patterns/05.json', '(5)～に行きます : 去～'),
  _PatternFile('assets/example_patterns/06.json', '(6)～をします : 做～'),
  _PatternFile('assets/example_patterns/07.json', '(7)～ません : 不～'),
  _PatternFile('assets/example_patterns/08.json', '(8)～ました : ～了（過去式）'),
  _PatternFile('assets/example_patterns/09.json', '(9)～たいです : 想～'),
  _PatternFile('assets/example_patterns/10.json', '(10)～てください : 請～'),
];

const String allExamplesLabel = '(11) 全部';

final List<ExamplePattern> examplePatterns = [];

final Set<String> exampleFavorites = {};

List<PatternSentence> favoriteExampleSentences() {
  final saved = exampleFavorites;
  final sentences = <PatternSentence>[];
  for (final pattern in examplePatterns) {
    if (pattern.label == allExamplesLabel) continue;
    for (final sentence in pattern.sentences) {
      if (saved.contains(sentence.japanese)) sentences.add(sentence);
    }
  }
  return sentences;
}

Future<void> loadExamplePatterns() async {
  if (examplePatterns.length == _patternFiles.length + 1) return;

  final loaded = <ExamplePattern>[];
  for (final file in _patternFiles) {
    final jsonString = await rootBundle.loadString(file.asset);
    final data = json.decode(jsonString) as List<dynamic>;
    loaded.add(
      ExamplePattern(
        label: file.label,
        sentences: [
          for (final item in data)
            PatternSentence.fromJson(item as Map<String, dynamic>),
        ],
      ),
    );
  }

  loaded.add(
    ExamplePattern(
      label: allExamplesLabel,
      sentences: [for (final pattern in loaded) ...pattern.sentences],
    ),
  );
  examplePatterns
    ..clear()
    ..addAll(loaded);
}

Future<void> loadExampleFavorites() async {
  final prefs = await SharedPreferences.getInstance();
  exampleFavorites
    ..clear()
    ..addAll(prefs.getStringList(exampleFavoritesKey) ?? const []);
}

Future<void> saveExampleFavorites() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(exampleFavoritesKey, exampleFavorites.toList());
}
