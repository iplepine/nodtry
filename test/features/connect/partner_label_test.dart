import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/connect/application/partner_label_provider.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';

UserModel _user(String uid, {String? name, String? nickname}) {
  final now = DateTime(2026, 10, 3);
  return UserModel(
    uid: uid,
    displayName: name,
    partnerNickname: nickname,
    createdAt: now,
    updatedAt: now,
  );
}

ConnectedUser _partner(String uid, {String? name}) => ConnectedUser(
  user: _user(uid, name: name),
  isSupported: true,
  isCheering: true,
);

ProviderContainer _container({
  required UserModel me,
  required List<ConnectedUser> partners,
}) {
  final container = ProviderContainer(
    overrides: [
      myProfileProvider.overrideWithValue(AsyncData(me)),
      connectedProfilesProvider.overrideWithValue(AsyncData(partners)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late AppLocalizations ko;
  late AppLocalizations en;

  setUpAll(() async {
    ko = await AppLocalizations.delegate.load(const Locale('ko'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('resolvePartnerLabel', () {
    test('nickname, then display name, then the fallback', () {
      expect(
        resolvePartnerLabel(nickname: '자기', displayName: '지민', fallback: '짝꿍'),
        '자기',
      );
      expect(
        resolvePartnerLabel(nickname: null, displayName: '지민', fallback: '짝꿍'),
        '지민',
      );
      expect(
        resolvePartnerLabel(nickname: null, displayName: null, fallback: '짝꿍'),
        '짝꿍',
      );
    });

    test('blank values are skipped', () {
      expect(
        resolvePartnerLabel(nickname: '  ', displayName: ' 지민 ', fallback: 'x'),
        '지민',
      );
      expect(
        resolvePartnerLabel(nickname: '', displayName: '   ', fallback: '짝꿍'),
        '짝꿍',
      );
    });
  });

  group('normalizePartnerNickname', () {
    test('trims and collapses whitespace', () {
      expect(normalizePartnerNickname('  우리   자기 '), '우리 자기');
    });

    test('keeps at most 10 characters', () {
      expect(normalizePartnerNickname('가나다라마바사아자차카'), '가나다라마바사아자차');
      expect(
        normalizePartnerNickname('가나다라마바사아자차')!.runes.length,
        kPartnerNicknameMaxLength,
      );
    });

    test('blank means no nickname', () {
      expect(normalizePartnerNickname(null), isNull);
      expect(normalizePartnerNickname(''), isNull);
      expect(normalizePartnerNickname('   '), isNull);
    });
  });

  group('PartnerLabel', () {
    test('resolve uses the localized 짝꿍 / "your partner" fallback', () {
      const label = PartnerLabel(partnerUid: 'p');
      expect(label.resolve(ko), '짝꿍');
      expect(label.resolve(en), 'your partner');
      expect(PartnerLabel.none.resolve(ko), '짝꿍');
    });

    test('preferredFor applies the nickname to the partner only', () {
      const label = PartnerLabel(
        partnerUid: 'p',
        nickname: '여보',
        displayName: '지민',
      );
      expect(label.preferredFor('p', displayName: '지민'), '여보');
      expect(label.preferredFor('someone-else', displayName: '민수'), '민수');
      expect(label.preferredFor(null, displayName: '민수'), '민수');
      expect(label.preferred, '여보');
    });

    test('preferredFor falls back to the display name, then null', () {
      const label = PartnerLabel(partnerUid: 'p', displayName: '지민');
      expect(label.preferredFor('p'), '지민');
      expect(const PartnerLabel(partnerUid: 'p').preferredFor('p'), isNull);
    });
  });

  group('partnerLabelProvider', () {
    test('my nickname for the partner comes first', () {
      final container = _container(
        me: _user('me', name: '나', nickname: '자기'),
        partners: [_partner('p', name: '지민')],
      );
      final label = container.read(partnerLabelProvider);
      expect(label.partnerUid, 'p');
      expect(label.hasNickname, isTrue);
      expect(label.resolve(ko), '자기');
    });

    test('without a nickname it is the partner display name', () {
      final container = _container(
        me: _user('me', name: '나'),
        partners: [_partner('p', name: '지민')],
      );
      expect(container.read(partnerLabelProvider).resolve(ko), '지민');
    });

    test('without a nickname or a name it is 짝꿍', () {
      final container = _container(
        me: _user('me', name: '나'),
        partners: [_partner('p')],
      );
      expect(container.read(partnerLabelProvider).resolve(ko), '짝꿍');
      expect(container.read(partnerLabelProvider).resolve(en), 'your partner');
    });

    test('a leftover nickname is ignored while nobody is connected', () {
      final container = _container(
        me: _user('me', name: '나', nickname: '전애칭'),
        partners: const [],
      );
      final label = container.read(partnerLabelProvider);
      expect(label.hasPartner, isFalse);
      expect(label.hasNickname, isFalse);
      expect(label.resolve(ko), '짝꿍');
    });
  });
}
