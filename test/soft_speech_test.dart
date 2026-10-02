import 'package:flutter_test/flutter_test.dart';
import 'package:yin_japanese_coach/soft_speech.dart';

void main() {
  test('Japanese is 40% slower than a normal pace', () {
    expect(rateForLanguage('ja-JP', web: true), closeTo(0.6, 0.0001));
    expect(rateForLanguage('ja-JP', web: false), closeTo(0.3, 0.0001));
    expect(rateForLanguage('zh-TW', web: true), 1.0);
    expect(rateForLanguage('zh-TW', web: false), 0.5);
  });

  test('Chinese is one notch quieter and Japanese is at the loudest step', () {
    expect(volumeForLanguage('zh-TW'), 0.9);
    expect(volumeForLanguage('ja-JP'), 1.0);
  });

  test('a male voice outranks a higher-quality female voice', () {
    final female = scoreVoice(
      {'name': 'Google Kyoko', 'locale': 'ja-JP', 'gender': ''},
      'ja-jp',
    );
    final male = scoreVoice(
      {'name': 'Otoya', 'locale': 'ja-JP', 'gender': ''},
      'ja-jp',
    );
    final labeledMale = scoreVoice(
      {'name': 'Google 日本語', 'locale': 'ja-JP', 'gender': 'male'},
      'ja-jp',
    );

    expect(male, greaterThan(female));
    expect(labeledMale, greaterThan(female));
  });

  test('Chinese male voice names outrank female ones', () {
    final female = scoreVoice(
      {'name': 'Mei-Jia', 'locale': 'zh-TW'},
      'zh-tw',
    );
    final male = scoreVoice(
      {'name': 'Microsoft Zhiwei', 'locale': 'zh-TW'},
      'zh-tw',
    );
    final codedMale = scoreVoice(
      {'name': 'cmn-TW-Wavenet-B', 'locale': 'zh-TW'},
      'zh-tw',
    );

    expect(male, greaterThan(female));
    expect(codedMale, greaterThan(female));
  });
}
