import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_look.dart';

const String exampleFavoritesKey = 'exampleFavorites';

class PatternSentence {
  const PatternSentence({
    required this.japanese,
    required this.hiragana,
    required this.romaji,
    required this.chinese,
    this.english = '',
    this.pattern = '',
    this.rank = 0,
  });

  factory PatternSentence.fromJson(Map<String, dynamic> json) {
    final rawRank = json['rank'];
    return PatternSentence(
      japanese: json['japanese'] as String,
      hiragana: json['hiragana'] as String,
      romaji: json['romaji'] as String,
      chinese: json['chinese'] as String,
      english: json['english'] as String? ?? '',
      pattern: json['pattern'] as String? ?? '',
      rank: rawRank is int ? rawRank : int.tryParse('$rawRank') ?? 0,
    );
  }

  final String japanese;
  final String hiragana;
  final String romaji;
  final String chinese;
  final String english;

  /// 例句句型.
  final String pattern;

  /// 例句常用度排名.
  final int rank;
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
  _PatternFile('assets/example_patterns/01.json', '(1) 1-100'),
  _PatternFile('assets/example_patterns/02.json', '(2) 101-200'),
  _PatternFile('assets/example_patterns/03.json', '(3) 201-300'),
  _PatternFile('assets/example_patterns/04.json', '(4) 301-400'),
  _PatternFile('assets/example_patterns/05.json', '(5) 401-500'),
  _PatternFile('assets/example_patterns/06.json', '(6) 501-600'),
  _PatternFile('assets/example_patterns/07.json', '(7) 601-700'),
  _PatternFile('assets/example_patterns/08.json', '(8) 701-800'),
  _PatternFile('assets/example_patterns/09.json', '(9) 801-900'),
  _PatternFile('assets/example_patterns/10.json', '(10) 901-1000'),
];

const String allExamplesLabel = '(11) 全部';

final List<ExamplePattern> examplePatterns = [];

/// Sentences available from the 例句 page. 全部 already holds every sentence.
int exampleSentenceCount() {
  for (final pattern in examplePatterns) {
    if (pattern.label == allExamplesLabel) return pattern.sentences.length;
  }
  var total = 0;
  for (final pattern in examplePatterns) {
    total += pattern.sentences.length;
  }
  return total;
}

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

/// 句型 and 常用度排名 shown under an 例句 answer.
List<Widget> examplePatternRankLines(PatternSentence sentence) {
  return [
    if (sentence.pattern.isNotEmpty) ...[
      const SizedBox(height: 14),
      Text(
        '例句句型：${sentence.pattern}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          height: 1.3,
          color: lookInk,
        ),
      ),
    ],
    if (sentence.rank > 0) ...[
      const SizedBox(height: 6),
      Text(
        '例句常用度排名：${sentence.rank}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          height: 1.3,
          color: lookCount,
        ),
      ),
    ],
  ];
}
