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

const List<String> _patternFiles = [
  'assets/example_patterns/01.json',
  'assets/example_patterns/02.json',
  'assets/example_patterns/03.json',
  'assets/example_patterns/04.json',
  'assets/example_patterns/05.json',
  'assets/example_patterns/06.json',
  'assets/example_patterns/07.json',
  'assets/example_patterns/08.json',
  'assets/example_patterns/09.json',
  'assets/example_patterns/10.json',
];

final List<ExamplePattern> examplePatterns = [];

/// Sentences available from the 例句 page.
int exampleSentenceCount() {
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
    for (final sentence in pattern.sentences) {
      if (saved.contains(sentence.japanese)) sentences.add(sentence);
    }
  }
  return sentences;
}

class _OrderedSentence {
  const _OrderedSentence(this.index, this.sentence);

  final int index;
  final PatternSentence sentence;
}

/// Groups every example by 句型. Categories, and the sentences inside them,
/// run from the smallest 常用度排名 at the top to the largest at the bottom.
Future<void> loadExamplePatterns() async {
  if (examplePatterns.isNotEmpty) return;

  final indexed = <_OrderedSentence>[];
  for (final file in _patternFiles) {
    final jsonString = await rootBundle.loadString(file);
    final data = json.decode(jsonString) as List<dynamic>;
    for (final item in data) {
      indexed.add(
        _OrderedSentence(
          indexed.length,
          PatternSentence.fromJson(item as Map<String, dynamic>),
        ),
      );
    }
  }

  final grouped = <String, List<_OrderedSentence>>{};
  for (final item in indexed) {
    grouped.putIfAbsent(item.sentence.pattern, () => []).add(item);
  }

  int lowestRank(List<_OrderedSentence> items) {
    var rank = items.first.sentence.rank;
    for (final item in items) {
      if (item.sentence.rank < rank) rank = item.sentence.rank;
    }
    return rank;
  }

  int earliest(List<_OrderedSentence> items) {
    var index = items.first.index;
    for (final item in items) {
      if (item.index < index) index = item.index;
    }
    return index;
  }

  final names = grouped.keys.toList()
    ..sort((a, b) {
      final byRank = lowestRank(grouped[a]!).compareTo(lowestRank(grouped[b]!));
      if (byRank != 0) return byRank;
      return earliest(grouped[a]!).compareTo(earliest(grouped[b]!));
    });

  final loaded = <ExamplePattern>[];
  for (final name in names) {
    final items = grouped[name]!
      ..sort((a, b) {
        final byRank = a.sentence.rank.compareTo(b.sentence.rank);
        if (byRank != 0) return byRank;
        return a.index.compareTo(b.index);
      });
    loaded.add(
      ExamplePattern(
        label: name.isEmpty ? '其他' : name,
        sentences: [for (final item in items) item.sentence],
      ),
    );
  }

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
