class ExampleSentence {
  const ExampleSentence({
    required this.japanese,
    required this.hiragana,
    required this.romaji,
    required this.chinese,
    this.english = '',
  });

  final String japanese;
  final String hiragana;
  final String romaji;
  final String chinese;
  final String english;
}
