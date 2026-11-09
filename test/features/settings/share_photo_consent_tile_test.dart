import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/settings/presentation/widgets/share_photo_consent_tile.dart';
import 'package:nod_try/l10n/app_localizations.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/user_repository.dart';

class _FakeUsers extends Fake implements UserRepository {
  final writes = <bool>[];
  Object? error;

  @override
  Future<void> updateAllowPartnerPhotoInShareCard(bool allow) async {
    if (error != null) throw error!;
    writes.add(allow);
  }
}

UserModel _me({bool? allow}) => UserModel(
  uid: 'me',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  allowPartnerPhotoInShareCard: allow,
);

Widget _app(_FakeUsers users, UserModel me) => ProviderScope(
  overrides: [
    userRepositoryProvider.overrideWithValue(users),
    myProfileProvider.overrideWithValue(AsyncData(me)),
  ],
  child: MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(body: SharePhotoConsentTile()),
  ),
);

bool _switchValue(WidgetTester tester) => tester
    .widget<SwitchListTile>(
      find.byKey(const ValueKey('settings-share-photo-consent')),
    )
    .value;

void main() {
  testWidgets('missing field reads as off; turning it on writes true', (
    tester,
  ) async {
    final users = _FakeUsers();
    await tester.pumpWidget(_app(users, _me()));

    expect(find.text('짝꿍이 만드는 공유 카드에 내 인증샷 넣기 허용'), findsOneWidget);
    expect(find.text('끄면 짝꿍 카드에는 짝꿍 사진만 들어가요'), findsOneWidget);
    expect(_switchValue(tester), isFalse);

    await tester.tap(
      find.byKey(const ValueKey('settings-share-photo-consent')),
    );
    await tester.pumpAndSettle();

    expect(users.writes, [true]);
    expect(_switchValue(tester), isTrue);
  });

  testWidgets('turning it off writes false', (tester) async {
    final users = _FakeUsers();
    await tester.pumpWidget(_app(users, _me(allow: true)));
    expect(_switchValue(tester), isTrue);

    await tester.tap(
      find.byKey(const ValueKey('settings-share-photo-consent')),
    );
    await tester.pumpAndSettle();

    expect(users.writes, [false]);
    expect(_switchValue(tester), isFalse);
  });

  testWidgets('a failed save reverts and says so', (tester) async {
    final users = _FakeUsers()..error = Exception('offline');
    await tester.pumpWidget(_app(users, _me()));

    await tester.tap(
      find.byKey(const ValueKey('settings-share-photo-consent')),
    );
    await tester.pumpAndSettle();

    expect(_switchValue(tester), isFalse);
    expect(find.text('설정을 저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
  });

  test('the field round-trips and is optional', () {
    expect(_me().allowsPartnerPhotoInShareCard, isFalse);
    expect(_me().toJson().containsKey('allowPartnerPhotoInShareCard'), isFalse);
    final json = _me(allow: true).toJson();
    expect(json['allowPartnerPhotoInShareCard'], isTrue);
    expect(UserModel.fromJson(json).allowsPartnerPhotoInShareCard, isTrue);
    expect(
      UserModel.fromJson({
        ...json,
        'allowPartnerPhotoInShareCard': 'yes',
      }).allowPartnerPhotoInShareCard,
      isNull,
    );
    expect(
      _me().copyWith(allowPartnerPhotoInShareCard: true).toFirestore(),
      containsPair('allowPartnerPhotoInShareCard', true),
    );
  });
}
