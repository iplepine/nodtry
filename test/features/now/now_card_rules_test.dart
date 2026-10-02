import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/now/presentation/cards/now_card_rules.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/widgets/time_chip.dart';

void main() {
  group('timeChipTypeFor', () {
    test('an overdue card is always past, even without chip text', () {
      expect(
        timeChipTypeFor(HomeCardState.overdue, hasChipText: true),
        TimeChipType.past,
      );
      expect(
        timeChipTypeFor(HomeCardState.overdue, hasChipText: false),
        TimeChipType.past,
      );
    });

    test('any other card with a chip is upcoming', () {
      for (final state in HomeCardState.values) {
        if (state == HomeCardState.overdue) continue;
        expect(
          timeChipTypeFor(state, hasChipText: true),
          TimeChipType.upcoming,
          reason: '$state',
        );
      }
    });

    test('no chip text means no chip type', () {
      expect(
        timeChipTypeFor(HomeCardState.nowAction, hasChipText: false),
        isNull,
      );
    });
  });

  group('managerCardHeaderFor', () {
    test('maps every partner-side state without reading any text', () {
      expect(
        managerCardHeaderFor(HomeCardState.partnerTodayComplete),
        ManagerCardHeader.partnerTodayComplete,
      );
      expect(
        managerCardHeaderFor(HomeCardState.partnerAction),
        ManagerCardHeader.partnerAction,
      );
      expect(
        managerCardHeaderFor(HomeCardState.partnerPlanCreate),
        ManagerCardHeader.planProposed,
      );
      expect(
        managerCardHeaderFor(HomeCardState.partnerPlanModify),
        ManagerCardHeader.planAdjusting,
      );
      expect(
        managerCardHeaderFor(HomeCardState.partnerNoPlan),
        ManagerCardHeader.partnerNoPlan,
      );
      expect(
        managerCardHeaderFor(HomeCardState.partnerPromiseProposed),
        ManagerCardHeader.waitingPromiseAccept,
      );
      expect(
        managerCardHeaderFor(HomeCardState.promiseSettled),
        ManagerCardHeader.promiseResult,
      );
      expect(
        managerCardHeaderFor(HomeCardState.partnerPoke),
        ManagerCardHeader.fallback,
      );
    });
  });

  group('showsPlanApprovalActions', () {
    test('only plan proposal / change cards offer 조정하기 · 승인', () {
      final withButtons = HomeCardState.values
          .where(showsPlanApprovalActions)
          .toSet();
      expect(withButtons, {
        HomeCardState.partnerPlanCreate,
        HomeCardState.partnerPlanModify,
      });
    });
  });
}
