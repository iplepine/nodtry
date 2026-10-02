import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/connected_user.dart';
import '../../../../models/plan_model.dart';
import '../../../../providers/home_provider.dart';
import '../../../../providers/repository_provider.dart';
import '../../../../repositories/connect_repository.dart' show ConnectionStatus;
import '../../../../utils/analytics.dart';
import '../../domain/workout_template.dart';
import '../plan_create_state.dart';

/// Thrown when a plan save is attempted without a resolved signed-in user.
/// The UI maps this to a localized message (view model has no l10n access).
class PlanCreateAuthException implements Exception {
  const PlanCreateAuthException();
}

/// Thrown when a save is attempted while something required is missing, so
/// the screen never reports a save that did not happen.
class PlanCreateIncompleteException implements Exception {
  final PlanCreateMissing missing;
  const PlanCreateIncompleteException(this.missing);

  @override
  String toString() => 'PlanCreateIncompleteException($missing)';
}

final planCreateViewModelProvider =
    AsyncNotifierProvider<PlanCreateViewModel, PlanCreateState>(
      PlanCreateViewModel.new,
    );

/// Parameters of the `plan_created` analytics event.
///
/// `template_edited` is true when a tile was used and the user then changed
/// its promise line, days or deadline.
@visibleForTesting
Map<String, Object> planCreatedAnalyticsParams(
  PlanCreateState state,
  Plan plan, {
  required bool isEdit,
}) {
  final template = state.appliedTemplate;
  final actionEdited =
      template != null &&
      template.action.isNotEmpty &&
      state.action.trim() != template.action.trim();
  return {
    'is_edit': isEdit,
    'frequency': plan.items.first.days.length,
    'has_partner': plan.managerId != null,
    'workout_type': plan.workoutType ?? 'none',
    'template_id': template?.id ?? 'none',
    'template_edited':
        template != null && (state.editedAfterTemplate || actionEdited),
  };
}

class PlanCreateViewModel extends AsyncNotifier<PlanCreateState> {
  static const _defaultSelectedDays = {0, 2, 4};
  static const _allDays = {0, 1, 2, 3, 4, 5, 6};

  @override
  FutureOr<PlanCreateState> build() {
    return _initialState();
  }

  PlanCreateState _initialState() {
    return PlanCreateState(
      selectedDays: _defaultSelectedDays,
      notificationTime: _defaultDeadline(),
    );
  }

  NotificationTime _defaultDeadline() {
    return NotificationTime.custom(kDefaultDeadlineHour, 0);
  }

  /// Weekdays (0 = Monday) of the partner's most recently created active
  /// plan, or null when the partner has none.
  @visibleForTesting
  static Set<int>? partnerDaySuggestion(List<Plan> partnerPlans) {
    final candidates =
        partnerPlans
            .where(
              (plan) => plan.state == PlanState.active && plan.items.isNotEmpty,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final plan in candidates) {
      final days = plan.items.first.days
          .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
          .map((day) => day - 1)
          .toSet();
      if (days.isNotEmpty) return days;
    }
    return null;
  }

  Future<void> dispatch(PlanCreateIntent intent) async {
    final prevState = state.value!;

    switch (intent) {
      case ResetIntent():
        state = AsyncValue.data(_initialState());
      case UpdateActionIntent(:final action):
        if (action == prevState.action) return;
        // Typing keeps the selected workout; only the analytics flag notices.
        state = AsyncValue.data(prevState.copyWith(action: action));
      case UpdateDescriptionIntent(:final description):
        if (description == prevState.description) return;
        state = AsyncValue.data(prevState.copyWith(description: description));
      case ToggleDayIntent(:final dayIndex):
        final newDays = Set<int>.from(prevState.selectedDays);
        if (!newDays.remove(dayIndex)) newDays.add(dayIndex);
        state = AsyncValue.data(_withDays(prevState, newDays));
      case UpdateSelectedDaysIntent(:final selectedDays):
        state = AsyncValue.data(
          _withDays(prevState, Set<int>.from(selectedDays)),
        );
      case UpdateNotificationTimeIntent(:final notificationTime):
        state = AsyncValue.data(
          prevState.copyWith(
            notificationTime: notificationTime,
            deadlineLocked: true,
            editedAfterTemplate: prevState.appliedTemplate != null,
          ),
        );
      case SelectWorkoutIntent(:final template):
        state = AsyncValue.data(_applyTemplate(prevState, template));
      case InitializePlanIntent(:final plan):
        state = AsyncValue.data(_fromPlan(plan));
      case PrefillPartnerDaysIntent():
        await _prefillPartnerDays();
      case SavePlanIntent():
        await _savePlan();
    }
  }

  PlanCreateState _withDays(PlanCreateState prev, Set<int> days) {
    return prev.copyWith(
      selectedDays: days,
      daysLocked: true,
      editedAfterTemplate: prev.appliedTemplate != null,
    );
  }

  PlanCreateState _applyTemplate(PlanCreateState prev, WorkoutTemplate t) {
    // The tile's line fills an empty field or replaces the previous tile's
    // untouched line. Anything typed by hand (or an edited plan's title) stays.
    final previousLine = prev.appliedTemplate?.action.trim();
    final current = prev.action.trim();
    final lineIsReplaceable =
        current.isEmpty || (previousLine != null && current == previousLine);
    final action = lineIsReplaceable ? t.action : prev.action;

    return prev.copyWith(
      action: action,
      workoutType: t.type,
      appliedTemplate: t,
      editedAfterTemplate: false,
      selectedDays: prev.daysLocked
          ? null
          : Set<int>.from(t.selectedDayIndexes),
      notificationTime: prev.deadlineLocked ? null : t.deadline,
    );
  }

  PlanCreateState _fromPlan(Plan plan) {
    final item = plan.items.firstOrNull;
    // Older plans stored no weekdays to mean "every day"; say so explicitly.
    final days =
        item?.days
            .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
            .map((day) => day - 1)
            .toSet() ??
        <int>{};
    final storedTime = item?.notificationTime;
    // A deadline is required now; an old "no reminder" plan gets the default.
    final deadline = storedTime == null || storedTime.type == 'none'
        ? _defaultDeadline()
        : storedTime;

    return PlanCreateState(
      action: item?.title ?? '',
      description: item?.description ?? '',
      selectedDays: days.isEmpty ? _allDays : days,
      notificationTime: deadline,
      workoutType: WorkoutType.fromId(plan.workoutType),
      daysLocked: true,
      deadlineLocked: true,
      existingPlanId: plan.id,
      originalPlan: plan,
    );
  }

  Future<void> _prefillPartnerDays() async {
    bool applies(PlanCreateState? s) =>
        s != null &&
        s.existingPlanId == null &&
        s.originalPlan == null &&
        !s.daysLocked;
    if (!applies(state.value)) return;

    try {
      final partners = await ref.read(connectedProfilesProvider.future);
      final partnerUid = partners.firstOrNull?.user.uid;
      if (partnerUid == null) return;
      final plans = await ref
          .read(recordRepositoryProvider)
          .getPlansByUserId(partnerUid);
      final days = partnerDaySuggestion(plans);
      if (days == null) return;

      // The user may have started editing while this was loading.
      final latest = state.value;
      if (!applies(latest)) return;
      state = AsyncValue.data(
        latest!.copyWith(
          selectedDays: days,
          daysLocked: true,
          partnerSuggestedDays: days,
        ),
      );
    } catch (e) {
      // Only a suggestion; the regular defaults stay.
      debugPrint('[PlanCreate] partner day suggestion skipped: $e');
    }
  }

  Future<List<ConnectedUser>?> _connectedPartners() async {
    final loaded = ref.read(connectedProfilesProvider).value;
    if (loaded != null) return loaded;
    try {
      return await ref
          .read(connectedProfilesProvider.future)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[PlanCreate] connected profiles unavailable: $e');
      return null;
    }
  }

  Future<void> _savePlan() async {
    final prevState = state.value!;
    // A second tap while the first save is still in flight would run the whole
    // create path again with `existingPlanId` still null, writing a duplicate
    // plan document (and a duplicate push to the partner).
    if (prevState.isSaving) return;
    final missing = prevState.missingField;
    if (missing != null) throw PlanCreateIncompleteException(missing);

    state = AsyncValue.data(
      prevState.copyWith(isSaving: true, errorMessage: null),
    );

    String? createdPlanId;
    Plan? savedPlan;
    try {
      final userState = ref.read(myProfileProvider);
      final userId = userState.asData?.value?.uid;

      if (userId == null) {
        throw const PlanCreateAuthException();
      }

      final days = prevState.selectedDays.map((d) => d + 1).toList()..sort();
      final planItem = PlanItem(
        title: prevState.action.trim(),
        count: days.length,
        days: days,
        notificationTime: prevState.notificationTime,
        description: prevState.description,
      );

      final partners = await _connectedPartners();
      final now = DateTime.now();
      final isEdit = prevState.existingPlanId != null;

      final Plan plan;
      if (isEdit) {
        plan = _editedPlan(
          prevState,
          planItem,
          userId: userId,
          partners: partners,
          now: now,
        );
      } else {
        final period = Plan.periodStartingOn(now);
        // New promises start right away, partner or not. The partner is told
        // by the server's creation push; there is no approval step.
        plan = Plan(
          userId: userId,
          managerId: partners?.firstOrNull?.user.uid,
          startDate: period.start,
          endDate: period.end,
          state: PlanState.active,
          items: [planItem],
          createdAt: now,
          lastUpdatedBy: userId,
          // A copy of an older plan keeps having no type (it may not be a
          // workout); a brand-new promise typed without a tile is "other".
          workoutType:
              prevState.workoutType?.id ??
              (prevState.originalPlan == null ? WorkoutType.other.id : null),
        );
      }

      String planId;
      if (isEdit) {
        await ref.read(recordRepositoryProvider).updatePlan(plan);
        planId = prevState.existingPlanId!;
      } else {
        planId = await ref.read(createNewPlanUseCaseProvider).execute(plan);
      }

      // The plan now exists in Firestore. Remember it before anything else
      // can fail, so a retry updates that document instead of creating a
      // second one (alarm scheduling below is the realistic failure point).
      createdPlanId = planId;
      savedPlan = plan.copyWith(id: planId);

      AnalyticsService.log(
        AnalyticsEvent.planCreated,
        planCreatedAnalyticsParams(prevState, plan, isEdit: isEdit),
      );

      ref.invalidate(homeCardStateProvider);
      await ref.read(settingAlarmUseCaseProvider).execute(savedPlan);

      state = AsyncValue.data(
        prevState.copyWith(
          isSaving: false,
          existingPlanId: planId,
          originalPlan: savedPlan,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        prevState.copyWith(
          isSaving: false,
          errorMessage: e.toString(),
          // Keep whatever id we had if the failure landed before the write —
          // `existingPlanId` takes an explicit null, so passing `createdPlanId`
          // straight through would clear it on an edit retry.
          existingPlanId: createdPlanId ?? prevState.existingPlanId,
          originalPlan: savedPlan,
        ),
      );
      rethrow;
    }
  }

  /// The couple link is known to be gone (the relation stream says none).
  bool _linkConfirmedGone() {
    try {
      return ref.read(connectionStatusStreamProvider).value ==
          ConnectionStatus.none;
    } catch (_) {
      return false;
    }
  }

  /// The saved version of the plan being edited.
  ///
  /// A running (active) plan keeps its period, state and history: editing the
  /// promise must not restart the 4 weeks or ask for approval again. A legacy
  /// pending or rejected plan has not really started, so it becomes active
  /// with a fresh period from today (the same reset as approving it).
  Plan _editedPlan(
    PlanCreateState prevState,
    PlanItem planItem, {
    required String userId,
    required List<ConnectedUser>? partners,
    required DateTime now,
  }) {
    final planId = prevState.existingPlanId!;
    final original = prevState.originalPlan?.id == planId
        ? prevState.originalPlan
        : null;

    final DateTime startDate;
    final DateTime endDate;
    final PlanState planState;
    if (original == null ||
        original.state == PlanState.pendingApproval ||
        original.state == PlanState.rejected ||
        original.state == PlanState.draft) {
      final period = Plan.periodStartingOn(now);
      startDate = period.start;
      endDate = period.end;
      planState = PlanState.active;
    } else {
      startDate = original.startDate;
      endDate = original.endDate;
      planState = original.state;
    }
    // Use the partner as connected now; keep the stored one when the
    // connection list could not be loaded — or came back empty while the link
    // itself isn't confirmed gone (an empty list must never silently detach
    // the partner from a running promise).
    final connected = partners?.firstOrNull?.user.uid;
    final String? managerId;
    if (connected != null) {
      managerId = connected;
    } else if (partners != null && _linkConfirmedGone()) {
      managerId = null;
    } else {
      managerId = original?.managerId;
    }

    return Plan(
      id: planId,
      userId: userId,
      managerId: managerId,
      startDate: startDate,
      endDate: endDate,
      state: planState,
      items: [planItem],
      createdAt: original?.createdAt ?? now,
      completedDates: original?.completedDates ?? const [],
      skippedDates: original?.skippedDates ?? const [],
      verifiedDates: original?.verifiedDates ?? const [],
      rescuedDates: original?.rescuedDates ?? const [],
      restedDates: original?.restedDates ?? const [],
      lastCheerMessage: original?.lastCheerMessage,
      lastCheerType: original?.lastCheerType,
      lastCheerAt: original?.lastCheerAt,
      lastPokeMessage: original?.lastPokeMessage,
      lastPokeAt: original?.lastPokeAt,
      lastPokeAcknowledgedAt: original?.lastPokeAcknowledgedAt,
      lastMissedNotifiedAt: original?.lastMissedNotifiedAt,
      lastMissedItemTitle: original?.lastMissedItemTitle,
      lastActionNote: original?.lastActionNote,
      lastComment: original?.lastComment,
      // The partner gets the "promise changed" push only when the editor is
      // recorded as the last writer.
      lastUpdatedBy: userId,
      pilotNextPlanIntent: original?.pilotNextPlanIntent,
      pilotExitReason: original?.pilotExitReason,
      pilotSettledAt: original?.pilotSettledAt,
      promise: original?.promise,
      lastActionId: original?.lastActionId,
      workoutType: prevState.workoutType?.id ?? original?.workoutType,
    );
  }
}
