// Fictional couple + workout fixtures for the store screenshots.
//
// Dates are relative to the real today, because the app's cards read
// DateTime.now() directly ("today's" record, hero, knock). Times of day are
// fixed so every run tells the same evening story.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nod_try/features/history/presentation/history_state.dart';
import 'package:nod_try/features/history/presentation/history_viewmodel.dart';
import 'package:nod_try/features/now/presentation/now_tab_intent.dart';
import 'package:nod_try/features/now/presentation/now_tab_state.dart';
import 'package:nod_try/features/now/presentation/now_tab_viewmodel.dart';
import 'package:nod_try/features/proof/data/proof_photo_cache.dart';
import 'package:nod_try/features/us/presentation/us_state.dart';
import 'package:nod_try/features/us/presentation/us_viewmodel.dart';
import 'package:nod_try/models/connected_user.dart';
import 'package:nod_try/models/history_item.dart';
import 'package:nod_try/models/home_state.dart';
import 'package:nod_try/models/plan_model.dart';
import 'package:nod_try/models/promise_model.dart';
import 'package:nod_try/models/user_model.dart';
import 'package:nod_try/providers/notification_permission_provider.dart';
import 'package:nod_try/providers/repository_provider.dart';
import 'package:nod_try/repositories/record_repository.dart';
import 'package:nod_try/widgets/quiet_header.dart';

const kMeUid = 'me';
const kPartnerUid = 'partner';
const kMyPlanId = 'plan_me_run';
const kPartnerPlanId = 'plan_partner_gym';
const kPartnerActionId = 'act_partner_today';
const kPartnerPhotoPath =
    'proofs/$kPartnerUid/$kPartnerPlanId/$kPartnerActionId.jpg';

/// The people and the copy that is not app copy (names, promise lines,
/// notes) for one locale.
class ShotCast {
  ShotCast(this.locale, {required this.now});

  final Locale locale;
  final DateTime now;

  bool get ko => locale.languageCode == 'ko';

  String get myName => ko ? '지민' : 'Mia';
  String get partnerName => ko ? '도윤' : 'Leo';

  String get myRunTitle => ko ? '한강 30분 달리기' : '30-min evening run';
  String get partnerGymTitle => ko ? '퇴근하고 헬스 1시간' : 'Gym after work, 1 hour';
  String get partnerNote =>
      ko ? '하체 끝! 내일 계단 조심해야지 😂' : 'Leg day done! Stairs tomorrow 😂';

  DateTime get today => DateTime(now.year, now.month, now.day);

  /// Fixed times of day, so the screenshots read like one evening whenever
  /// they are generated (the day itself is the real today).
  DateTime at(int hour, int minute) =>
      DateTime(today.year, today.month, today.day, hour, minute);

  /// When the partner's proof photo was taken.
  DateTime get partnerProofAt => at(19, 42);

  UserModel get me => UserModel(
    uid: kMeUid,
    displayName: myName,
    statusMessage: ko ? '오늘도 둘운완 가보자 🔥' : 'Going for another DuoDone 🔥',
    inviteCode: 'DUO7K3PX',
    loginType: LoginType.apple,
    createdAt: today.subtract(const Duration(days: 40)),
    updatedAt: now,
  );

  UserModel get partner => UserModel(
    uid: kPartnerUid,
    displayName: partnerName,
    statusMessage: ko ? '하체는 배신하지 않는다' : 'Never skip leg day',
    loginType: LoginType.google,
    createdAt: today.subtract(const Duration(days: 40)),
    updatedAt: now,
  );

  List<ConnectedUser> get connected => [
    ConnectedUser(user: partner, isSupported: true, isCheering: true),
  ];

  /// Weekdays (1 = Monday) that include today, [offsets] days apart.
  List<int> _daysFromToday(List<int> offsets) {
    final days = {
      for (final offset in offsets) ((now.weekday - 1 + offset) % 7) + 1,
    }.toList()..sort();
    return days;
  }

  ({DateTime start, DateTime end}) get _period =>
      Plan.periodStartingOn(today.subtract(const Duration(days: 19)));

  List<DateTime> _scheduledBefore(
    List<int> weekdays,
    DateTime start,
    int hour,
  ) {
    final dates = <DateTime>[];
    for (
      var d = start;
      d.isBefore(today);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      if (weekdays.contains(d.weekday)) {
        dates.add(DateTime(d.year, d.month, d.day, hour, 12));
      }
    }
    return dates;
  }

  Promise chickenBet({required String proposerId}) => Promise(
    status: PromiseStatus.active,
    proposerId: proposerId,
    penalty: PromisePenalty(
      description: ko ? '🍗 치킨 쏘기' : '🍗 Buy the chicken',
      targetDays: 3,
    ),
    reward: PromiseReward(
      description: ko ? '🍣 같이 오마카세' : '🍣 Omakase together',
      targetDays: 10,
    ),
    proposedAt: today.subtract(const Duration(days: 12)),
    acceptedAt: today.subtract(const Duration(days: 12)),
  );

  /// My running promise (3×/week including today, 21:00 deadline).
  Plan myRunPlan({
    bool doneToday = false,
    bool verifiedToday = false,
    bool knockedToday = false,
    Promise? promise,
  }) {
    final period = _period;
    final days = _daysFromToday(const [0, 2, 4]);
    final past = _scheduledBefore(days, period.start, 20);
    final doneAt = at(20, 35);
    final completed = [...past, if (doneToday) doneAt];
    return Plan(
      id: kMyPlanId,
      userId: kMeUid,
      managerId: kPartnerUid,
      startDate: period.start,
      endDate: period.end,
      state: PlanState.active,
      createdAt: period.start,
      workoutType: 'running',
      completedDates: completed,
      verifiedDates: [...past, if (doneToday && verifiedToday) doneAt],
      lastPokeAt: knockedToday ? at(21, 3) : null,
      lastPokeMessage: knockedToday
          ? (ko
                ? '똑똑! 오늘 약속 기다리고 있어 🙂'
                : "Knock knock! Waiting on today's promise 🙂")
          : null,
      promise: promise,
      items: [
        PlanItem(
          title: myRunTitle,
          days: days,
          count: days.length,
          notificationTime: NotificationTime.custom(21, 0),
        ),
      ],
    );
  }

  /// The partner's gym promise (4×/week including today, 22:00 deadline).
  Plan partnerGymPlan({
    bool doneToday = true,
    bool verifiedToday = false,
    Promise? promise,
  }) {
    final period = _period;
    final days = _daysFromToday(const [0, 1, 3, 5]);
    final past = _scheduledBefore(days, period.start, 21);
    final proofAt = partnerProofAt;
    return Plan(
      id: kPartnerPlanId,
      userId: kPartnerUid,
      managerId: kMeUid,
      startDate: period.start,
      endDate: period.end,
      state: PlanState.active,
      createdAt: period.start,
      workoutType: 'gym',
      completedDates: [...past, if (doneToday) proofAt],
      verifiedDates: [...past, if (doneToday && verifiedToday) proofAt],
      lastActionId: doneToday ? kPartnerActionId : null,
      lastActionNote: doneToday ? partnerNote : null,
      lastProofPhotoPath: doneToday ? kPartnerPhotoPath : null,
      lastProofAt: doneToday ? proofAt : null,
      lastUpdatedBy: kPartnerUid,
      promise: promise,
      items: [
        PlanItem(
          title: partnerGymTitle,
          days: days,
          count: days.length,
          notificationTime: NotificationTime.custom(22, 0),
        ),
      ],
    );
  }

  /// The action behind the partner's photo (for its 📸 source badge).
  HistoryItem get partnerAction => HistoryItem(
    id: kPartnerActionId,
    planId: kPartnerPlanId,
    date: partnerProofAt,
    title: partnerGymTitle,
    status: HistoryStatus.done,
    executorId: kPartnerUid,
    note: partnerNote,
    proofPhotoPath: kPartnerPhotoPath,
    proofSource: 'camera',
    proofTakenAt: partnerProofAt,
  );
}

/// Repository reads the screens make, answered from fixtures.
class ShotRecords extends Fake implements RecordRepository {
  ShotRecords({
    required this.plansByUser,
    required this.photos,
    this.actions = const {},
  });

  final Map<String, List<Plan>> plansByUser;
  final Map<String, Uint8List> photos;
  final Map<String, HistoryItem> actions;

  List<Plan> _active(String uid) => (plansByUser[uid] ?? const [])
      .where((p) => p.state == PlanState.active)
      .toList();

  @override
  Future<List<Plan>> getPlansByUserId(String userId) async =>
      plansByUser[userId] ?? const [];

  @override
  Stream<List<Plan>> getPlansByUserIdStream(String userId) =>
      Stream.value(_active(userId));

  @override
  Stream<List<Plan>> getAllPlansByUserIdStream(String userId) =>
      Stream.value(plansByUser[userId] ?? const []);

  @override
  Future<HistoryItem?> getHistoryItem(String actionId) async =>
      actions[actionId];

  @override
  Future<Uint8List?> downloadProofPhoto(String path) async => photos[path];

  @override
  Future<List<String>> completeOverduePlans() async => const [];

  @override
  Future<void> acknowledgePoke(String planId) async {}

  @override
  Stream<List<HistoryItem>> getHistoryItemsStream({List<String>? userIds}) =>
      Stream.value(const []);
}

class StaticNowTabViewModel extends NowTabViewModel {
  StaticNowTabViewModel(this.shotState);

  final NowTabState shotState;

  @override
  Stream<NowTabState> build() => Stream.value(shotState);

  @override
  Future<void> dispatch(NowTabIntent intent) async {}
}

class StaticHistoryViewModel extends HistoryViewModel {
  StaticHistoryViewModel(this.shotState);

  final HistoryState shotState;

  @override
  Stream<HistoryState> build() => Stream.value(shotState);
}

class StaticUsViewModel extends UsViewModel {
  StaticUsViewModel(this.shotState);

  final UsState shotState;

  @override
  FutureOr<UsState> build() => shotState;
}

/// What one screenshot's app instance sees.
class ShotWorld {
  ShotWorld({
    required this.cast,
    required this.nowState,
    required this.photoCache,
    required this.records,
  });

  final ShotCast cast;
  final NowTabState nowState;
  final ProofPhotoCache photoCache;
  final ShotRecords records;

  List<Override> get overrides => [
    recordRepositoryProvider.overrideWithValue(records),
    myProfileProvider.overrideWith((ref) => Stream.value(cast.me)),
    connectedProfilesProvider.overrideWith((ref) async => cast.connected),
    notificationPermissionProvider.overrideWith((ref) async => true),
    proofPhotoCacheProvider.overrideWithValue(photoCache),
    nowTabViewModelProvider.overrideWith(() => StaticNowTabViewModel(nowState)),
    historyViewModelProvider.overrideWith(
      () => StaticHistoryViewModel(
        HistoryState(
          partnerName: cast.partnerName,
          headerPeriodState: HeaderPeriodState.inProgress,
        ),
      ),
    ),
    usViewModelProvider.overrideWith(
      () => StaticUsViewModel(
        UsState(myProfile: cast.me, connectedProfiles: cast.connected),
      ),
    ),
  ];
}

/// Builds the world for a screenshot from the plans both people have.
ShotWorld buildWorld({
  required ShotCast cast,
  required Plan myPlan,
  required Plan partnerPlan,
  required NowTabState Function(Plan myPlan, Plan partnerPlan) now,
  required ProofPhotoCache photoCache,
  required Map<String, Uint8List> photos,
}) {
  final records = ShotRecords(
    plansByUser: {
      kMeUid: [myPlan],
      kPartnerUid: [partnerPlan],
    },
    photos: photos,
    actions: {kPartnerActionId: cast.partnerAction},
  );
  return ShotWorld(
    cast: cast,
    nowState: now(myPlan, partnerPlan),
    photoCache: photoCache,
    records: records,
  );
}

/// Now-tab state with my card on top (or none) and the partner's card below.
NowTabState nowTabState({
  required ShotCast cast,
  HomeCardModel? primary,
  List<HomeCardModel> manager = const [],
}) {
  return NowTabState(
    allCards: [?primary, ...manager],
    primaryCard: primary,
    primaryCarouselCards: primary == null ? const [] : [primary],
    managerCards: manager,
    partnerProfile: cast.partner,
    headerPeriodState: HeaderPeriodState.inProgress,
  );
}
