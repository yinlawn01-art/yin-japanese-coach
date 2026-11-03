/// Hiragana the Japanese voice should speak for [romaji].
///
/// The roman spelling is the pronunciation: particle "wa" is わ, "o" is お,
/// and "e" is え. 母 is spoken as the spelling "haha", not はは. Spaces
/// between words are kept so each spelled word is read on its own.
String pronunciationForRomaji(String romaji) {
  final buffer = StringBuffer();
  final pieces = RegExp("[A-Za-z']+|[^A-Za-z']+").allMatches(romaji);
  for (final piece in pieces) {
    final text = piece.group(0)!;
    if (text.toLowerCase() == 'haha') {
      buffer.write('haha');
    } else if (RegExp("[A-Za-z]").hasMatch(text)) {
      buffer.write(_tokenToHiragana(text.toLowerCase()));
    } else {
      buffer.write(text.replaceAll('.', '。').replaceAll(',', '、'));
    }
  }
  return buffer.toString();
}

const Map<String, String> _syllables = {
  'kya': 'きゃ',
  'kyu': 'きゅ',
  'kyo': 'きょ',
  'gya': 'ぎゃ',
  'gyu': 'ぎゅ',
  'gyo': 'ぎょ',
  'sha': 'しゃ',
  'shu': 'しゅ',
  'sho': 'しょ',
  'cha': 'ちゃ',
  'chu': 'ちゅ',
  'cho': 'ちょ',
  'nya': 'にゃ',
  'nyu': 'にゅ',
  'nyo': 'にょ',
  'hya': 'ひゃ',
  'hyu': 'ひゅ',
  'hyo': 'ひょ',
  'bya': 'びゃ',
  'byu': 'びゅ',
  'byo': 'びょ',
  'pya': 'ぴゃ',
  'pyu': 'ぴゅ',
  'pyo': 'ぴょ',
  'mya': 'みゃ',
  'myu': 'みゅ',
  'myo': 'みょ',
  'rya': 'りゃ',
  'ryu': 'りゅ',
  'ryo': 'りょ',
  'ja': 'じゃ',
  'ju': 'じゅ',
  'jo': 'じょ',
  'shi': 'し',
  'chi': 'ち',
  'tsu': 'つ',
  'fu': 'ふ',
  'fa': 'ふぁ',
  'fi': 'ふぃ',
  'fe': 'ふぇ',
  'fo': 'ふぉ',
  'ka': 'か',
  'ki': 'き',
  'ku': 'く',
  'ke': 'け',
  'ko': 'こ',
  'ga': 'が',
  'gi': 'ぎ',
  'gu': 'ぐ',
  'ge': 'げ',
  'go': 'ご',
  'sa': 'さ',
  'su': 'す',
  'se': 'せ',
  'so': 'そ',
  'za': 'ざ',
  'ji': 'じ',
  'zu': 'ず',
  'ze': 'ぜ',
  'zo': 'ぞ',
  'ta': 'た',
  'te': 'て',
  'to': 'と',
  'da': 'だ',
  'di': 'ぢ',
  'du': 'づ',
  'de': 'で',
  'do': 'ど',
  'na': 'な',
  'ni': 'に',
  'nu': 'ぬ',
  'ne': 'ね',
  'no': 'の',
  'ha': 'は',
  'hi': 'ひ',
  'he': 'へ',
  'ho': 'ほ',
  'ba': 'ば',
  'bi': 'び',
  'bu': 'ぶ',
  'be': 'べ',
  'bo': 'ぼ',
  'pa': 'ぱ',
  'pi': 'ぴ',
  'pu': 'ぷ',
  'pe': 'ぺ',
  'po': 'ぽ',
  'ma': 'ま',
  'mi': 'み',
  'mu': 'む',
  'me': 'め',
  'mo': 'も',
  'ya': 'や',
  'yu': 'ゆ',
  'yo': 'よ',
  'ra': 'ら',
  'ri': 'り',
  'ru': 'る',
  're': 'れ',
  'ro': 'ろ',
  'wa': 'わ',
  'wo': 'を',
  'a': 'あ',
  'i': 'い',
  'u': 'う',
  'e': 'え',
  'o': 'お',
  'n': 'ん',
};

const _vowels = 'aeiou';

(String, int)? _syllableAt(String token, int index) {
  for (var size = 3; size >= 1; size--) {
    if (index + size > token.length) continue;
    final candidate = _syllables[token.substring(index, index + size)];
    if (candidate != null) return (candidate, size);
  }
  return null;
}

String _tokenToHiragana(String token) {
  final buffer = StringBuffer();
  var index = 0;
  while (index < token.length) {
    final mark = token[index];
    final doubled = index + 1 < token.length &&
        token[index + 1] == mark &&
        !_vowels.contains(mark) &&
        mark != 'n' &&
        mark != "'";
    if (doubled) {
      buffer.write('っ');
      index++;
      continue;
    }

    final syllable = _syllableAt(token, index);
    if (syllable != null) {
      buffer.write(syllable.$1);
      index += syllable.$2;
      continue;
    }

    // kin'youbi / ten'in: the apostrophe keeps ん separate from the next vowel.
    // A final apostrophe, as in えっ, is a small tsu.
    if (mark == "'") {
      if (index + 1 == token.length) buffer.write('っ');
      index++;
      continue;
    }

    // shutchou: t before ch is っ, the same as a doubled consonant.
    final consonant = !_vowels.contains(mark) && mark != 'n';
    if (consonant && _syllableAt(token, index + 1) != null) {
      buffer.write('っ');
      index++;
      continue;
    }

    buffer.write(mark);
    index++;
  }
  return buffer.toString();
}
