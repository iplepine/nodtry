import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/widget_sync/application/widget_sync_service.dart';
import 'package:nod_try/features/widget_sync/domain/duo_widget_snapshot.dart';

/// The native widgets can't import Dart, so the storage key, App Group, kind,
/// provider names and JSON field names are duplicated in Swift / Kotlin /
/// entitlements. These checks fail when one side is renamed without the
/// other (the widget would silently show its placeholder forever).
String read(String path) => File(path).readAsStringSync();

const swiftSnapshot = 'ios/DuoWidget/DuoWidgetSnapshot.swift';
const swiftWidget = 'ios/DuoWidget/DuoWidget.swift';
const kotlinSnapshot =
    'android/app/src/main/kotlin/com/devho/nodtry/app/widget/DuoWidgetSnapshot.kt';
const kotlinProviders =
    'android/app/src/main/kotlin/com/devho/nodtry/app/widget/DuoWidgetProviders.kt';

void main() {
  test('storage key and App Group match on both platforms', () {
    expect(read(swiftSnapshot), contains('"$kDuoWidgetSnapshotKey"'));
    expect(read(kotlinSnapshot), contains('"$kDuoWidgetSnapshotKey"'));
    expect(read(swiftSnapshot), contains('"$kDuoWidgetAppGroupId"'));
    for (final entitlements in [
      'ios/Runner/Runner.entitlements',
      'ios/DuoWidget/DuoWidgetExtension.entitlements',
    ]) {
      final plist = read(entitlements);
      expect(plist, contains('com.apple.security.application-groups'));
      expect(plist, contains('<string>$kDuoWidgetAppGroupId</string>'));
    }
  });

  test('iOS widget kind and Android providers exist', () {
    expect(read(swiftWidget), contains('let kind = "$kDuoWidgetIosKind"'));
    final manifest = read('android/app/src/main/AndroidManifest.xml');
    final providers = read(kotlinProviders);
    for (final qualified in kDuoWidgetAndroidProviders) {
      final simple = qualified.split('.').last;
      expect(providers, contains('class $simple'));
      expect(manifest, contains('android:name=".widget.$simple"'));
    }
  });

  test('every JSON field the native side reads is written by Dart', () {
    const person = DuoWidgetPerson(
      name: '나',
      status: DuoWidgetPersonStatus.done,
      statusText: '완료',
    );
    const snapshot = DuoWidgetSnapshot(
      date: '2026-11-09',
      streak: 1,
      headline: 'h',
      duoDoneToday: true,
      badge: 'b',
      me: person,
      partner: person,
      staleText: 's',
      locale: 'ko',
    );
    final json = snapshot.toJson();
    final personJson = person.toJson();

    // Top-level fields the native parsers look up.
    for (final key in ['date', 'streak', 'headline', 'badge', 'stale', 'me']) {
      expect(json, contains(key));
      expect(read(swiftSnapshot), contains('json["$key"]'));
      expect(read(kotlinSnapshot), contains('"$key"'));
    }
    expect(json, contains('duoDone'));
    expect(read(swiftSnapshot), contains('json["duoDone"]'));
    expect(json, contains('partner'));
    for (final key in ['name', 'status', 'text']) {
      expect(personJson, contains(key));
      expect(read(swiftSnapshot), contains('map["$key"]'));
      expect(read(kotlinSnapshot), contains('optString("$key")'));
    }
  });

  test('native status switches know every status wire value', () {
    final kotlin = read(
      'android/app/src/main/kotlin/com/devho/nodtry/app/widget/DuoWidgetRenderer.kt',
    );
    final swift = read(swiftWidget);
    // done/done_proof/pending get their own color; rest/off fall to the
    // secondary default, so only the explicit ones must appear.
    for (final wire in ['done', 'done_proof', 'pending']) {
      expect(kotlin, contains('"$wire"'));
      expect(swift, contains('"$wire"'));
    }
    final wires = DuoWidgetPersonStatus.values.map((s) => s.wire).toSet();
    expect(wires, {'done', 'done_proof', 'rest', 'pending', 'off'});
  });
}
