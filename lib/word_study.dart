import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const wordStudyIndexesKey = 'wordStudyIndexes';
const wordStudyNextKey = 'wordStudyNext';
const wordStudySnapshotKey = 'wordStudySnapshot';

/// The 單字學習 queue. Each entry is an index into the flashcard catalog
/// (`words`), in the order those cards are numbered.
class WordStudy {
  List<int> indexes = [];
  int nextIndex = 0;
  List<int> sessionSnapshot = [];

  Future<void>? _saveChain;
  Future<void>? _loadChain;

  void reset() {
    indexes = [];
    nextIndex = 0;
    sessionSnapshot = [];
    _saveChain = null;
    _loadChain = null;
  }

  void retainAvailable(int totalWords) {
    bool available(int index) => index >= 0 && index < totalWords;
    indexes = indexes.where(available).toList();
    sessionSnapshot = sessionSnapshot.where(available).toList();
    if (totalWords <= 0 || nextIndex < 0) {
      nextIndex = 0;
    } else {
      nextIndex %= totalWords;
    }
  }

  /// Adds up to [count] catalog indexes that are not already queued,
  /// walking forward from [nextIndex] and stopping after one full pass.
  int addBatch(int totalWords, {int count = 10}) {
    if (totalWords <= 0 || count <= 0) return 0;
    retainAvailable(totalWords);
    var added = 0;
    var scanned = 0;
    var cursor = nextIndex;
    while (added < count && scanned < totalWords) {
      if (!indexes.contains(cursor)) {
        indexes.add(cursor);
        added++;
      }
      cursor = (cursor + 1) % totalWords;
      scanned++;
    }
    nextIndex = cursor;
    return added;
  }

  void beginSession() {
    sessionSnapshot = List<int>.of(indexes);
  }

  void restoreSession() {
    indexes = List<int>.of(sessionSnapshot);
  }

  /// Removes the word at [position]. Returns true when the queue is empty.
  bool removeAt(int position) {
    if (position < 0 || position >= indexes.length) return indexes.isEmpty;
    indexes.removeAt(position);
    return indexes.isEmpty;
  }

  Future<void> load() {
    return _loadChain ??= _read();
  }

  Future<void> _read() async {
    final prefs = await SharedPreferences.getInstance();
    indexes = _readList(prefs, wordStudyIndexesKey);
    sessionSnapshot = _readList(prefs, wordStudySnapshotKey);
    nextIndex = prefs.getInt(wordStudyNextKey) ?? 0;
  }

  Future<void> save() {
    final indexesCopy = List<int>.of(indexes);
    final snapshotCopy = List<int>.of(sessionSnapshot);
    final next = nextIndex;
    final chain = (_saveChain ?? Future<void>.value()).then(
      (_) => _write(indexesCopy, snapshotCopy, next),
    );
    _saveChain = chain;
    return chain;
  }

  Future<void> _write(List<int> indexes, List<int> snapshot, int next) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(wordStudyIndexesKey, jsonEncode(indexes));
    await prefs.setString(wordStudySnapshotKey, jsonEncode(snapshot));
    await prefs.setInt(wordStudyNextKey, next);
  }

  static List<int> _readList(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return [
      for (final item in decoded)
        if (item is num) item.toInt(),
    ];
  }
}

final wordStudy = WordStudy();
