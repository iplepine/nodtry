import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/application/notification_routing.dart';
import 'package:nod_try/services/notification_quick_actions.dart';
import 'package:nod_try/services/notification_service.dart';

void main() {
  group('quick action categories', () {
    test('match the server contract', () {
      expect(quickActionsForCategory('partner_proof'), [
        NotificationQuickAction.props,
      ]);
      expect(quickActionsForCategory('poke_reply'), [
        NotificationQuickAction.pokeComing,
        NotificationQuickAction.pokePass,
      ]);
      expect(quickActionsForCategory('partner_missed'), [
        NotificationQuickAction.cheer,
      ]);
      expect(quickActionsForCategory(null), isEmpty);
      expect(quickActionsForCategory('unknown'), isEmpty);
    });

    test('button ids round-trip; a body tap is no action', () {
      for (final action in NotificationQuickAction.values) {
        expect(NotificationQuickAction.fromId(action.id), action);
      }
      expect(
        NotificationQuickAction.fromId(
          'com.apple.UNNotificationDefaultActionIdentifier',
        ),
        isNull,
      );
      expect(NotificationQuickAction.fromId(null), isNull);
    });
  });

  group('opened push with a button', () {
    test('carries the action into the open request', () {
      final request = NotificationOpenRequest.fromData({
        'type': 'action_completed',
        'planId': 'p1',
      }, actionId: 'quick_props');
      expect(request?.quickAction, NotificationQuickAction.props);
      expect(request?.planId, 'p1');
      expect(
        notificationOpenTargetForRequest(request!),
        NotificationOpenTarget.now,
      );
    });

    test('a body tap has no action', () {
      final request = NotificationOpenRequest.fromData({'type': 'poke'});
      expect(request?.quickAction, isNull);
    });
  });

  test('인정 and 응원 answer the partner card, a knock reply my own', () {
    expect(
      quickActionFitsArea(NotificationQuickAction.props, NowCardArea.manager),
      isTrue,
    );
    expect(
      quickActionFitsArea(NotificationQuickAction.props, NowCardArea.carousel),
      isFalse,
    );
    expect(
      quickActionFitsArea(NotificationQuickAction.cheer, NowCardArea.manager),
      isTrue,
    );
    expect(
      quickActionFitsArea(
        NotificationQuickAction.pokeComing,
        NowCardArea.carousel,
      ),
      isTrue,
    );
    expect(
      quickActionFitsArea(NotificationQuickAction.pokePass, NowCardArea.manager),
      isFalse,
    );
  });
}
