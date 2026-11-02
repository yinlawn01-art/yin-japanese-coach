class ExampleSentence {
  const ExampleSentence({
    required this.japanese,
    required this.hiragana,
    required this.romaji,
    required this.chinese,
    this.english = '',
    this.pattern = '',
    this.rank = 0,
  });

  final String japanese;
  final String hiragana;
  final String romaji;
  final String chinese;
  final String english;

  /// 例句句型 from the worksheet. 例句優先序 is not stored.
  final String pattern;

  /// 例句常用度排名 from the worksheet.
  final int rank;
}
