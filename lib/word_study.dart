import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const wordStudyIndexesKey = 'wordStudyIndexes';
const wordStudyNextKey = 'wordStudyNext';
const wordStudySnapshotKey = 'wordStudySnapshot';

/// A study queue. Each entry is an index into the flashcard catalog
/// (`words`), in the order those cards are numbered.
class WordStudy {
  WordStudy({
    this.indexesKey = wordStudyIndexesKey,
    this.nextKey = wordStudyNextKey,
    this.snapshotKey = wordStudySnapshotKey,
  });

  final String indexesKey;
  final String nextKey;
  final String snapshotKey;

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

  /// Moves the next 加10 start ahead by [count] words.
  /// Past the last word, the next batch starts again at word 1.
  void skipAhead(int totalWords, {int count = 50}) {
    if (totalWords <= 0 || count <= 0) return;
    retainAvailable(totalWords);
    final next = nextIndex + count;
    nextIndex = next >= totalWords ? 0 : next;
  }

  /// Sends the next 加10 個單字 back to flashcard 1.
  /// The current 單字學習 list is cleared so those early cards are not skipped.
  void restartFromBeginning() {
    indexes = [];
    nextIndex = 0;
  }

  void beginSession() {
    sessionSnapshot = List<int>.of(indexes);
  }

  void restoreSession() {
    indexes = List<int>.of(sessionSnapshot);
  }

  /// Keeps the place just after the last word of the batch that was opened,
  /// and leaves the queue empty so the next batch starts there.
  void rememberBatchEnd(int totalWords) {
    if (sessionSnapshot.isNotEmpty) {
      var last = sessionSnapshot.first;
      for (final index in sessionSnapshot) {
        if (index > last) last = index;
      }
      nextIndex = last + 1;
    }
    indexes = [];
    if (totalWords > 0) {
      nextIndex %= totalWords;
    }
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
    indexes = _readList(prefs, indexesKey);
    sessionSnapshot = _readList(prefs, snapshotKey);
    nextIndex = prefs.getInt(nextKey) ?? 0;
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
    await prefs.setString(indexesKey, jsonEncode(indexes));
    await prefs.setString(snapshotKey, jsonEncode(snapshot));
    await prefs.setInt(nextKey, next);
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

/// Chinese prompt, Japanese answer. Separate from [wordStudy].
final zhJaStudy = WordStudy(
  indexesKey: 'zhJaStudyIndexes',
  nextKey: 'zhJaStudyNext',
  snapshotKey: 'zhJaStudySnapshot',
);
