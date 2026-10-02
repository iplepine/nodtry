import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/utils/korean_particle.dart';

void main() {
  group('Hangul endings', () {
    test('picks the consonant form after a final consonant', () {
      expect(withJosa('짝꿍', '이랑/랑'), '짝꿍이랑');
      expect(withJosa('민준', '이/가'), '민준이');
      expect(withJosa('여보', '아/야'), '여보야');
      expect(withJosa('오빠', '아/야'), '오빠야');
      expect(withJosa('운동', '을/를'), '운동을');
      expect(withJosa('약속', '은/는'), '약속은');
      expect(withJosa('짝꿍', '과/와'), '짝꿍과');
      expect(withJosa('짝꿍', '이에요/예요'), '짝꿍이에요');
    });

    test('picks the vowel form after a vowel', () {
      expect(withJosa('자기', '이랑/랑'), '자기랑');
      expect(withJosa('지수', '이/가'), '지수가');
      expect(withJosa('애기', '을/를'), '애기를');
      expect(withJosa('여보', '은/는'), '여보는');
      expect(withJosa('자기', '과/와'), '자기와');
      expect(withJosa('자기', '이에요/예요'), '자기예요');
    });

    test('ㄹ takes 로 but keeps the consonant form elsewhere', () {
      expect(withJosa('서울', '으로/로'), '서울로');
      expect(withJosa('공원', '으로/로'), '공원으로');
      expect(withJosa('학교', '으로/로'), '학교로');
      expect(withJosa('하늘', '이랑/랑'), '하늘이랑');
      expect(withJosa('하늘', '을/를'), '하늘을');
    });

    test('josa returns only the particle', () {
      expect(josa('짝꿍', '이랑/랑'), '이랑');
      expect(josa('자기', '이랑/랑'), '랑');
    });

    test('accepts the reversed pair order', () {
      expect(withJosa('짝꿍', '가/이'), '짝꿍이');
      expect(withJosa('자기', '가/이'), '자기가');
      expect(withJosa('짝꿍', '랑/이랑'), '짝꿍이랑');
      expect(withJosa('자기', '를/을'), '자기를');
      expect(withJosa('서울', '로/으로'), '서울로');
    });

    test('lone jamo are read by their letter names', () {
      expect(withJosa('ㅋㅋ', '이/가'), 'ㅋㅋ이');
      expect(withJosa('ㅠㅠ', '이/가'), 'ㅠㅠ가');
    });
  });

  group('non-Hangul endings', () {
    test('digits are read the Sino-Korean way', () {
      expect(withJosa('1', '이/가'), '1이'); // 일
      expect(withJosa('2', '이/가'), '2가'); // 이
      expect(withJosa('3', '을/를'), '3을'); // 삼
      expect(withJosa('4', '을/를'), '4를'); // 사
      expect(withJosa('6', '은/는'), '6은'); // 육
      expect(withJosa('9', '은/는'), '9는'); // 구
      expect(withJosa('10', '이/가'), '10이'); // 십
      expect(withJosa('100', '이/가'), '100이'); // 백
      expect(withJosa('7', '으로/로'), '7로'); // 칠
      expect(withJosa('3', '으로/로'), '3으로'); // 삼
      expect(withJosa('자기2', '이랑/랑'), '자기2랑');
    });

    test('Latin names use loanword heuristics', () {
      expect(withJosa('Tom', '이랑/랑'), 'Tom이랑');
      expect(withJosa('Ben', '이/가'), 'Ben이');
      expect(withJosa('Bill', '으로/로'), 'Bill로');
      expect(withJosa('Bill', '이/가'), 'Bill이');
      expect(withJosa('Jack', '이/가'), 'Jack이');
      expect(withJosa('Amy', '이/가'), 'Amy가');
      expect(withJosa('Mike', '이/가'), 'Mike가');
      expect(withJosa('Mark', '이/가'), 'Mark가');
      expect(withJosa('Peter', '이/가'), 'Peter가');
    });

    test('short all-caps words are spelled out', () {
      expect(withJosa('BTS', '이/가'), 'BTS가'); // 에스
      expect(withJosa('JM', '이/가'), 'JM이'); // 엠
      expect(withJosa('KL', '으로/로'), 'KL로'); // 엘
    });

    test('trailing emoji, punctuation and spaces are skipped', () {
      expect(withJosa('짝꿍❤️', '이랑/랑'), '짝꿍❤️이랑');
      expect(withJosa('자기 🐻', '이랑/랑'), '자기 🐻랑');
      expect(withJosa('민준!', '이/가'), '민준!이');
      expect(withJosa('(지수)', '이/가'), '(지수)가');
    });

    test('unreadable or empty words default to the vowel form', () {
      expect(withJosa('', '이랑/랑'), '랑');
      expect(withJosa('🐻', '이/가'), '🐻가');
      expect(withJosa('José', '이/가'), 'José가');
      expect(withJosa('さくら', '이/가'), 'さくら가');
    });
  });

  group('hasFinalConsonant', () {
    test('reports the final sound', () {
      expect(hasFinalConsonant('짝꿍'), isTrue);
      expect(hasFinalConsonant('서울'), isTrue);
      expect(hasFinalConsonant('자기'), isFalse);
      expect(hasFinalConsonant(''), isFalse);
    });
  });

  test('rejects a malformed pair', () {
    expect(() => josa('짝꿍', '이랑'), throwsArgumentError);
    expect(() => josa('짝꿍', '/랑'), throwsArgumentError);
    expect(() => josa('짝꿍', '이랑/'), throwsArgumentError);
  });
}
