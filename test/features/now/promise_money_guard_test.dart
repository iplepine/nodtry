import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/domain/promise_money_guard.dart';

void main() {
  group('mentionsMoney', () {
    test('every token from the spec is refused', () {
      for (final text in [
        '만원',
        '1만원',
        '1만 원',
        '3000원',
        '3,000 원',
        '5천원',
        '오천원',
        '십만원',
        '백원 내기',
        '₩5000',
        '현금 박치기',
        '바로 송금하기',
        '계좌이체',
        '포인트 쏘기',
      ]) {
        expect(mentionsMoney(text), isTrue, reason: text);
      }
    });

    test('English money words are refused too', () {
      for (final text in [
        r'$20',
        r'$ 5',
        '20 dollars',
        '10 bucks',
        'cash',
        'Venmo me',
        'PayPal',
        'bank transfer',
      ]) {
        expect(mentionsMoney(text), isTrue, reason: text);
      }
    });

    test('ordinary words that only contain 원 are fine', () {
      for (final text in [
        '소원 들어주기',
        '공원 산책',
        '병원 데려다주기',
        '원샷',
        '원하는 거 해주기',
        '🍗 치킨 쏘기',
        '☕ 아아 쏘기',
        '🍽️ 설거지 일주일',
        '💆 마사지 10분',
        '🎬 영화 고르기 권한',
        '🎬 영화 고르기 양보',
        '🚗 데리러 가기',
        '🍣 같이 오마카세',
        'Buy the chicken',
        'dishes for a week',
        '',
      ]) {
        expect(mentionsMoney(text), isFalse, reason: text);
      }
    });
  });
}
