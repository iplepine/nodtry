import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/connect/domain/invite_code.dart';
import 'package:nod_try/routes/app_router.dart';

void main() {
  group('inviteCodeFromLocation', () {
    test('reads the code from an opened /i/{CODE} link', () {
      expect(inviteCodeFromLocation(Uri.parse('/i/K7MP2QXR')), 'K7MP2QXR');
      expect(inviteCodeFromLocation(Uri.parse('/i/k7mp2qxr')), 'K7MP2QXR');
      expect(
        inviteCodeFromLocation(
          Uri.parse('https://nod-try.web.app/i/K7MP2QXR'),
        ),
        'K7MP2QXR',
      );
      // Custom scheme: the host is not part of the path.
      expect(
        inviteCodeFromLocation(Uri.parse('onmybehalf://app/i/K7MP2QXR')),
        'K7MP2QXR',
      );
    });

    test('ignores other paths and malformed codes', () {
      expect(inviteCodeFromLocation(Uri.parse('/home')), isNull);
      expect(inviteCodeFromLocation(Uri.parse('/i/short')), isNull);
      expect(inviteCodeFromLocation(Uri.parse('/i/K7MP2QXR/extra')), isNull);
      expect(inviteCodeFromLocation(Uri.parse('/plan/detail')), isNull);
    });
  });

  test('connectEntry puts code entry first and carries the code', () {
    final plain = Uri.parse(AppRoutes.connectEntry());
    expect(plain.path, AppRoutes.connect);
    expect(plain.queryParameters, {'mode': 'enter'});

    final linked = Uri.parse(
      AppRoutes.connectEntry(code: 'K7MP2QXR', source: InviteCodeSource.link),
    );
    expect(linked.queryParameters, {
      'mode': 'enter',
      'code': 'K7MP2QXR',
      'source': 'link',
    });
  });
}
