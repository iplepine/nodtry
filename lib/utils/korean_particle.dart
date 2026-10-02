/// Korean particle (조사) helpers.
///
/// Korean particles change with the last sound of the word in front of them:
/// `짝꿍이랑` but `자기랑`, `민준이` but `지수가`. Copy that puts a user-chosen
/// name (nickname, display name) in front of such a particle must pick the form
/// at runtime, so ARB strings should take the already-particled value
/// (`{nameWithParticle}`) and the call site should pass
/// `withJosa(name, '이랑/랑')`.
///
/// A pair is written as `'<after a final consonant>/<after a vowel>'`, e.g.
/// `'이/가'`, `'을/를'`, `'은/는'`, `'과/와'`, `'아/야'`, `'이랑/랑'`,
/// `'으로/로'`, `'이에요/예요'`. The reversed order (`'가/이'`) is accepted too.
///
/// Words that do not end in Hangul are handled by pronunciation heuristics:
/// digits are read the Sino-Korean way (1 일, 2 이, 3 삼 …), and Latin letters
/// use loanword rules (`Tom` → 톰, `Bill` → 빌, `Jack` → 잭; anything unclear
/// counts as ending in a vowel). Trailing emoji, punctuation and spaces are
/// skipped, and a word with nothing readable gets the after-a-vowel form.
library;

/// What the word ends with, as far as particle choice is concerned.
enum _Ending {
  /// Ends in a vowel (or could not be read): `가`, `를`, `는`, `와`, `야`, `로`.
  vowel,

  /// Ends in ㄹ: like a consonant, except `으로/로` takes `로` (`서울로`).
  rieul,

  /// Ends in any other final consonant: `이`, `을`, `은`, `과`, `아`, `으로`.
  consonant,
}

/// Whether [word] ends in a final consonant (받침) when read aloud.
///
/// `true` for `짝꿍`, `민준`, `Tom`, `10`; `false` for `자기`, `지수`, `Amy`,
/// `2`, an empty string, or a word made only of emoji.
bool hasFinalConsonant(String word) => _endingOf(word) != _Ending.vowel;

/// The particle from [pair] that fits after [word], without the word.
///
/// ```dart
/// josa('짝꿍', '이랑/랑'); // '이랑'
/// josa('자기', '이랑/랑'); // '랑'
/// josa('서울', '으로/로'); // '로'
/// ```
String josa(String word, String pair) {
  final forms = _splitPair(pair);
  final ending = _endingOf(word);
  switch (ending) {
    case _Ending.vowel:
      return forms.afterVowel;
    case _Ending.rieul:
      // ㄹ behaves like a vowel only for the 으로 family (으로, 으로서, 으로써).
      return forms.afterConsonant.startsWith('으')
          ? forms.afterVowel
          : forms.afterConsonant;
    case _Ending.consonant:
      return forms.afterConsonant;
  }
}

/// [word] followed by the particle from [pair] that fits it.
///
/// ```dart
/// withJosa('짝꿍', '이랑/랑'); // '짝꿍이랑'
/// withJosa('자기', '이/가');   // '자기가'
/// withJosa('Tom', '을/를');    // 'Tom을'
/// ```
String withJosa(String word, String pair) => '$word${josa(word, pair)}';

// ---------------------------------------------------------------------------

/// Forms that only ever follow a vowel. Used to accept a reversed pair.
const Set<String> _vowelOnlyForms = {'가', '를', '는', '와', '야', '여', '로'};

({String afterConsonant, String afterVowel}) _splitPair(String pair) {
  final slash = pair.indexOf('/');
  if (slash <= 0 || slash == pair.length - 1) {
    throw ArgumentError.value(
      pair,
      'pair',
      "expected '<after consonant>/<after vowel>', e.g. '이/가'",
    );
  }
  final first = pair.substring(0, slash).trim();
  final second = pair.substring(slash + 1).trim();

  // '가/이', '랑/이랑', '로/으로' → swap so the consonant form comes first.
  final firstIsVowelForm =
      _vowelOnlyForms.contains(first) ||
      second == '이$first' ||
      second == '으$first';
  return firstIsVowelForm
      ? (afterConsonant: second, afterVowel: first)
      : (afterConsonant: first, afterVowel: second);
}

const int _hangulSyllableStart = 0xAC00;
const int _hangulSyllableEnd = 0xD7A3;
const int _jongseongCount = 28;
const int _jongseongRieul = 8; // ㄹ

_Ending _endingOf(String word) {
  final runes = word.runes.toList();
  for (var i = runes.length - 1; i >= 0; i--) {
    final ending = _endingOfRune(runes, i);
    if (ending != null) return ending;
  }
  return _Ending.vowel;
}

/// The ending decided by the character at [index], or `null` when that
/// character is not readable (emoji, punctuation, space) and the caller should
/// look further left.
_Ending? _endingOfRune(List<int> runes, int index) {
  final rune = runes[index];

  // Precomposed Hangul syllable: the final consonant is encoded in the code.
  if (rune >= _hangulSyllableStart && rune <= _hangulSyllableEnd) {
    final jong = (rune - _hangulSyllableStart) % _jongseongCount;
    if (jong == 0) return _Ending.vowel;
    return jong == _jongseongRieul ? _Ending.rieul : _Ending.consonant;
  }

  // Compatibility jamo typed on their own (ㅋㅋ, ㅠ).
  if (rune >= 0x3131 && rune <= 0x314E) {
    // Consonant letter names all end in a consonant (기역, 니은, 리을 …).
    return rune == 0x3139 ? _Ending.rieul : _Ending.consonant;
  }
  if (rune >= 0x314F && rune <= 0x3163) return _Ending.vowel;

  // Digits, read the Sino-Korean way.
  if (rune >= 0x30 && rune <= 0x39) return _endingOfNumber(runes, index);

  // Latin letters, read as an English loanword.
  if (_isLatin(rune)) return _endingOfLatin(runes, index);

  // Other letters we cannot read (accented Latin, kana, CJK ideographs): stop
  // here and use the after-a-vowel form rather than looking further left.
  if (_isOtherLetter(rune)) return _Ending.vowel;

  return null;
}

bool _isOtherLetter(int rune) =>
    (rune >= 0x00C0 && rune <= 0x024F) || // Latin-1 supplement / extended
    (rune >= 0x0370 && rune <= 0x04FF) || // Greek, Cyrillic
    (rune >= 0x3040 && rune <= 0x30FF) || // Hiragana, Katakana
    (rune >= 0x4E00 && rune <= 0x9FFF); // CJK unified ideographs

/// 0 영, 1 일, 2 이, 3 삼, 4 사, 5 오, 6 육, 7 칠, 8 팔, 9 구.
const List<_Ending> _digitEndings = [
  _Ending.consonant, // 영
  _Ending.rieul, // 일
  _Ending.vowel, // 이
  _Ending.consonant, // 삼
  _Ending.vowel, // 사
  _Ending.vowel, // 오
  _Ending.consonant, // 육
  _Ending.rieul, // 칠
  _Ending.rieul, // 팔
  _Ending.vowel, // 구
];

_Ending _endingOfNumber(List<int> runes, int index) {
  final digit = runes[index] - 0x30;
  if (digit != 0) return _digitEndings[digit];
  // A trailing zero is read as a unit: 10 십, 100 백, 1000 천, 10000 만 — all
  // end in a consonant. A lone 0 is 영, which does too.
  return _Ending.consonant;
}

bool _isLatin(int rune) =>
    (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);

bool _isUpper(int rune) => rune >= 0x41 && rune <= 0x5A;

/// Letter names of a spelled-out acronym: L 엘, M 엠, N 엔, R 알 end in a
/// consonant; every other letter name ends in a vowel (에이, 비, 씨 …).
_Ending _endingOfSpelledLetter(int upperRune) {
  switch (String.fromCharCode(upperRune)) {
    case 'L':
    case 'R':
      return _Ending.rieul;
    case 'M':
    case 'N':
      return _Ending.consonant;
    default:
      return _Ending.vowel;
  }
}

_Ending _endingOfLatin(List<int> runes, int index) {
  // Collect the Latin word that ends at [index].
  var start = index;
  while (start > 0 && _isLatin(runes[start - 1])) {
    start--;
  }
  final letters = runes.sublist(start, index + 1);

  // An all-caps word of up to four letters is spelled out (BTS, JY, ABC).
  if (letters.length <= 4 && letters.every(_isUpper)) {
    return _endingOfSpelledLetter(letters.last);
  }

  final word = String.fromCharCodes(letters).toLowerCase();
  if (word.endsWith('ng') || word.endsWith('m') || word.endsWith('n')) {
    return _Ending.consonant; // Tom 톰, Ben 벤, Jang 장
  }
  if (word.endsWith('l')) return _Ending.rieul; // Bill 빌, Michael 마이클
  if (word.endsWith('ck')) return _Ending.consonant; // Jack 잭, Nick 닉
  // Vowels, silent e/r, and stops that become 크/트/프 (Mark 마크, Kate 케이트)
  // read as ending in a vowel; when unsure we fall back to the vowel form.
  return _Ending.vowel;
}
