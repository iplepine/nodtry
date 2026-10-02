/// 내기 is never about money (spec §3, store gambling policies): a bet text
/// that mentions money is refused before it is saved.
///
/// The spec lists `원|만원|₩|현금|송금|계좌|포인트`. A bare `원` would also
/// refuse ordinary words — 소원 들어주기 (the classic couple bet), 공원 산책,
/// 병원 데려다주기, 원샷 — so `원` counts only as a currency unit: right after
/// a digit or a Korean number word (3000원, 5천 원, 만원, 오천원, 십만원).
/// 만원, ₩, 현금, 송금, 계좌 and 포인트 match anywhere, and so do a few
/// English money words for the English UI.
library;

final RegExp _moneyPattern = RegExp(
  r'(\d|[일이삼사오육칠팔구십백천만])\s*원'
  r'|만\s*원|₩|현금|송금|계좌|포인트'
  r'|\$\s*\d|\d\s*(dollars?|bucks|usd|krw)\b'
  r'|\bcash\b|\bvenmo\b|\bpaypal\b|bank\s+transfer',
  caseSensitive: false,
);

/// Whether [text] is a money bet that must not be saved.
bool mentionsMoney(String text) => _moneyPattern.hasMatch(text);
