import 'package:cloud_firestore/cloud_firestore.dart';
import 'promise_model.dart';

enum PlanState {
  draft,
  pendingApproval,
  active,
  completed,
  rejected,
  stopped;

  String toMap() {
    switch (this) {
      case PlanState.draft:
        return 'draft';
      case PlanState.pendingApproval:
        return 'pending_approval';
      case PlanState.active:
        return 'active';
      case PlanState.completed:
        return 'completed';
      case PlanState.rejected:
        return 'rejected';
      case PlanState.stopped:
        return 'stopped';
    }
  }

  static PlanState fromMap(String value) {
    switch (value) {
      case 'draft':
        return PlanState.draft;
      case 'pending_approval':
        return PlanState.pendingApproval;
      case 'active':
        return PlanState.active;
      case 'completed':
        return PlanState.completed;
      case 'rejected':
        return PlanState.rejected;
      case 'stopped':
        return PlanState.stopped;
      default:
        return PlanState.draft;
    }
  }
}

class Plan {
  final String? id;
  final String userId;
  final String? managerId;
  final DateTime startDate;
  final DateTime endDate;
  final PlanState state;
  final List<PlanItem> items;
  final DateTime createdAt;
  final List<DateTime> completedDates;
  final List<DateTime> skippedDates;
  final List<DateTime> verifiedDates;
  final List<DateTime> rescuedDates; // 파트너가 실천 인정한 날짜
  final List<DateTime> restedDates; // 휴식권 사용한 날짜
  final String? lastCheerMessage; // 마지막 응원 메시지
  final String? lastCheerType; // 마지막 응원 타입 (fire, heart etc)
  final DateTime? lastCheerAt; // 마지막 응원 시간
  final String? lastPokeMessage; // 마지막 똑똑 메시지
  final DateTime? lastPokeAt; // 마지막 똑똑 시간
  final DateTime? lastPokeAcknowledgedAt; // 마지막 똑똑 확인 시간
  final DateTime? lastMissedNotifiedAt; // 시스템이 놓친 약속을 알린 시간
  final String? lastMissedItemTitle; // 마지막 놓친 약속 제목
  final String? lastActionNote; // 마지막 실천 한마디 (실천자)
  final String? lastComment; // 마지막 피드백/응원 메시지 (매니저)
  final String? lastUpdatedBy; // 마지막으로 문서를 수정한 사람의 UID
  final String? pilotNextPlanIntent; // 4주 정산 후 다음 4주 의향
  final String? pilotExitReason; // 4주 정산 후 종료 사유
  final DateTime? pilotSettledAt; // 파일럿 정산 응답 시간
  final Promise? promise; // 보상/벌칙 약속

  Plan({
    this.id,
    required this.userId,
    this.managerId,
    required this.startDate,
    required this.endDate,
    required this.state,
    required this.items,
    required this.createdAt,
    this.completedDates = const [],
    this.skippedDates = const [],
    this.verifiedDates = const [],
    this.rescuedDates = const [],
    this.restedDates = const [],
    this.lastCheerMessage,
    this.lastCheerType,
    this.lastCheerAt,
    this.lastPokeMessage,
    this.lastPokeAt,
    this.lastPokeAcknowledgedAt,
    this.lastMissedNotifiedAt,
    this.lastMissedItemTitle,
    this.lastActionNote,
    this.lastComment,
    this.lastUpdatedBy,
    this.pilotNextPlanIntent,
    this.pilotExitReason,
    this.pilotSettledAt,
    this.promise,
  });

  Plan copyWith({
    String? id,
    String? userId,
    String? managerId,
    DateTime? startDate,
    DateTime? endDate,
    PlanState? state,
    List<PlanItem>? items,
    DateTime? createdAt,
    List<DateTime>? completedDates,
    List<DateTime>? skippedDates,
    List<DateTime>? verifiedDates,
    List<DateTime>? rescuedDates,
    List<DateTime>? restedDates,
    String? lastCheerMessage,
    String? lastCheerType,
    DateTime? lastCheerAt,
    String? lastPokeMessage,
    DateTime? lastPokeAt,
    DateTime? lastPokeAcknowledgedAt,
    DateTime? lastMissedNotifiedAt,
    String? lastMissedItemTitle,
    String? lastActionNote,
    String? lastComment,
    String? lastUpdatedBy,
    String? pilotNextPlanIntent,
    String? pilotExitReason,
    DateTime? pilotSettledAt,
    Promise? promise,
  }) {
    return Plan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      managerId: managerId ?? this.managerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      state: state ?? this.state,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
      skippedDates: skippedDates ?? this.skippedDates,
      verifiedDates: verifiedDates ?? this.verifiedDates,
      rescuedDates: rescuedDates ?? this.rescuedDates,
      restedDates: restedDates ?? this.restedDates,
      lastCheerMessage: lastCheerMessage ?? this.lastCheerMessage,
      lastCheerType: lastCheerType ?? this.lastCheerType,
      lastCheerAt: lastCheerAt ?? this.lastCheerAt,
      lastPokeMessage: lastPokeMessage ?? this.lastPokeMessage,
      lastPokeAt: lastPokeAt ?? this.lastPokeAt,
      lastPokeAcknowledgedAt:
          lastPokeAcknowledgedAt ?? this.lastPokeAcknowledgedAt,
      lastMissedNotifiedAt: lastMissedNotifiedAt ?? this.lastMissedNotifiedAt,
      lastMissedItemTitle: lastMissedItemTitle ?? this.lastMissedItemTitle,
      lastActionNote: lastActionNote ?? this.lastActionNote,
      lastComment: lastComment ?? this.lastComment,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      pilotNextPlanIntent: pilotNextPlanIntent ?? this.pilotNextPlanIntent,
      pilotExitReason: pilotExitReason ?? this.pilotExitReason,
      pilotSettledAt: pilotSettledAt ?? this.pilotSettledAt,
      promise: promise ?? this.promise,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'managerId': managerId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'state': state.toMap(),
      'items': items.map((x) => x.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'completedDates': completedDates
          .map((d) => Timestamp.fromDate(d))
          .toList(),
      'skippedDates': skippedDates.map((d) => Timestamp.fromDate(d)).toList(),
      'verifiedDates': verifiedDates.map((d) => Timestamp.fromDate(d)).toList(),
      'rescuedDates': rescuedDates.map((d) => Timestamp.fromDate(d)).toList(),
      'restedDates': restedDates.map((d) => Timestamp.fromDate(d)).toList(),
      if (lastCheerMessage != null) 'lastCheerMessage': lastCheerMessage,
      if (lastCheerType != null) 'lastCheerType': lastCheerType,
      if (lastCheerAt != null) 'lastCheerAt': Timestamp.fromDate(lastCheerAt!),
      if (lastPokeMessage != null) 'lastPokeMessage': lastPokeMessage,
      if (lastPokeAt != null) 'lastPokeAt': Timestamp.fromDate(lastPokeAt!),
      if (lastPokeAcknowledgedAt != null)
        'lastPokeAcknowledgedAt': Timestamp.fromDate(lastPokeAcknowledgedAt!),
      if (lastMissedNotifiedAt != null)
        'lastMissedNotifiedAt': Timestamp.fromDate(lastMissedNotifiedAt!),
      if (lastMissedItemTitle != null)
        'lastMissedItemTitle': lastMissedItemTitle,
      if (lastActionNote != null) 'lastActionNote': lastActionNote,
      if (lastComment != null) 'lastComment': lastComment,
      if (lastUpdatedBy != null) 'lastUpdatedBy': lastUpdatedBy,
      if (pilotNextPlanIntent != null)
        'pilotNextPlanIntent': pilotNextPlanIntent,
      if (pilotExitReason != null) 'pilotExitReason': pilotExitReason,
      if (pilotSettledAt != null)
        'pilotSettledAt': Timestamp.fromDate(pilotSettledAt!),
      if (promise != null) 'promise': promise!.toMap(),
    };
  }

  factory Plan.fromMap(Map<String, dynamic> map, String id) {
    final rawLastCheerMessage = map['lastCheerMessage'] as String?;
    final rawLastCheerType = map['lastCheerType'] as String?;
    final rawLastCheerAt = (map['lastCheerAt'] as Timestamp?)?.toDate();
    final isLegacyPoke =
        rawLastCheerType == 'poke' || rawLastCheerType == 'poke_acked';
    final effectiveLastComment =
        map['lastComment'] as String? ??
        (isLegacyPoke ? null : rawLastCheerMessage);

    return Plan(
      id: id,
      userId: map['userId'] ?? '',
      managerId: map['managerId'],
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      state: PlanState.fromMap(map['state'] ?? 'draft'),
      items: List<PlanItem>.from(
        (map['items'] as List<dynamic>).map<PlanItem>(
          (x) => PlanItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedDates:
          (map['completedDates'] as List<dynamic>?)
              ?.map((d) => (d as Timestamp).toDate())
              .toList() ??
          [],
      skippedDates:
          (map['skippedDates'] as List<dynamic>?)
              ?.map((d) => (d as Timestamp).toDate())
              .toList() ??
          [],
      verifiedDates:
          (map['verifiedDates'] as List<dynamic>?)
              ?.map((d) => (d as Timestamp).toDate())
              .toList() ??
          [],
      rescuedDates:
          (map['rescuedDates'] as List<dynamic>?)
              ?.map((d) => (d as Timestamp).toDate())
              .toList() ??
          [],
      restedDates:
          (map['restedDates'] as List<dynamic>?)
              ?.map((d) => (d as Timestamp).toDate())
              .toList() ??
          [],
      lastCheerMessage: isLegacyPoke ? null : rawLastCheerMessage,
      lastCheerType: isLegacyPoke ? null : rawLastCheerType,
      lastCheerAt: isLegacyPoke ? null : rawLastCheerAt,
      lastPokeMessage:
          map['lastPokeMessage'] as String? ??
          (isLegacyPoke ? rawLastCheerMessage : null),
      lastPokeAt:
          (map['lastPokeAt'] as Timestamp?)?.toDate() ??
          (rawLastCheerType == 'poke' ? rawLastCheerAt : null),
      lastPokeAcknowledgedAt:
          (map['lastPokeAcknowledgedAt'] as Timestamp?)?.toDate() ??
          (rawLastCheerType == 'poke_acked' ? rawLastCheerAt : null),
      lastMissedNotifiedAt: (map['lastMissedNotifiedAt'] as Timestamp?)
          ?.toDate(),
      lastMissedItemTitle: map['lastMissedItemTitle'] as String?,
      lastActionNote: map['lastActionNote'],
      lastComment: effectiveLastComment,
      lastUpdatedBy: map['lastUpdatedBy'],
      pilotNextPlanIntent: map['pilotNextPlanIntent'] as String?,
      pilotExitReason: map['pilotExitReason'] as String?,
      pilotSettledAt: (map['pilotSettledAt'] as Timestamp?)?.toDate(),
      promise: map['promise'] != null
          ? Promise.fromMap(map['promise'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 현재 연속 달성 횟수 (스트릭) 계산
  int get currentStreak {
    if (items.isEmpty) return 0;

    // 모든 아이템의 요일을 합산
    final scheduledDays = items.expand((i) => i.days).toSet();
    if (scheduledDays.isEmpty) return 0;

    int streak = 0;
    var checkDate = DateTime.now();
    final todayDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    // 오늘이 스케줄 날인데 아직 완료 안 했으면 어제부터 체크
    if (scheduledDays.contains(checkDate.weekday) &&
        !_isDateCovered(todayDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // 최대 365일 뒤로 탐색
    for (int i = 0; i < 365; i++) {
      final date = DateTime(checkDate.year, checkDate.month, checkDate.day);

      if (!scheduledDays.contains(checkDate.weekday)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      if (date.isBefore(
        DateTime(startDate.year, startDate.month, startDate.day),
      )) {
        break;
      }

      if (_isDateCovered(date)) {
        streak++;
      } else {
        break;
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  bool _isDateCovered(DateTime date) {
    return _containsDate(completedDates, date) ||
        _containsDate(rescuedDates, date) ||
        _containsDate(restedDates, date);
  }

  static bool _containsDate(List<DateTime> dates, DateTime target) {
    return dates.any(
      (d) =>
          d.year == target.year &&
          d.month == target.month &&
          d.day == target.day,
    );
  }

  /// 이번 주 휴식권 사용 가능 여부
  bool get canUseRestToday {
    final now = DateTime.now();
    // 이번 주 월요일 계산
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayDate = DateTime(monday.year, monday.month, monday.day);
    final sundayDate = mondayDate.add(const Duration(days: 7));

    final usedThisWeek = restedDates.where((d) {
      final date = DateTime(d.year, d.month, d.day);
      return !date.isBefore(mondayDate) && date.isBefore(sundayDate);
    }).length;

    return usedThisWeek < 1;
  }

  /// 플랜 시작일과 종료일을 포함한 전체 기간.
  int get calendarDurationDays {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    final days = end.difference(start).inDays + 1;
    return days < 1 ? 1 : days;
  }

  /// 보상/벌칙 정산 기준이 되는 실천 예정일 수.
  ///
  /// 요일 정보가 없으면 전체 기간을 기준으로 삼아 기존 데이터도 안전하게
  /// 처리한다.
  int get scheduledDayCount {
    final count = _scheduledDates.length;
    return count < 1 ? 1 : count;
  }

  /// 상/벌 약속에서 선택할 수 있는 targetDays의 최대값.
  int get promiseTargetDaysLimit => scheduledDayCount;

  /// 현재까지 보상 조건에 반영되는 성공일 수.
  int completedDayCount({DateTime? asOf}) {
    final start = _dateOnly(startDate);
    final cutoff = _cutoffDate(asOf);
    return _uniqueDatesInRange(completedDates, start, cutoff).length;
  }

  /// 현재 시점에서 실패로 확정된 예정일 수.
  int failedDayCount({DateTime? asOf}) {
    final today = _dateOnly(asOf ?? DateTime.now());
    final completed = _uniqueDatesInRange(
      completedDates,
      _dateOnly(startDate),
      _dateOnly(endDate),
    );
    return _scheduledDates.where((date) {
      return date.isBefore(today) && !completed.contains(date);
    }).length;
  }

  /// 아직 성공/실패 어느 쪽으로도 갈 수 있는 남은 예정일 수.
  int remainingScheduledDayCount({DateTime? asOf}) {
    final today = _dateOnly(asOf ?? DateTime.now());
    final completed = _uniqueDatesInRange(
      completedDates,
      _dateOnly(startDate),
      _dateOnly(endDate),
    );
    return _scheduledDates.where((date) {
      return !date.isBefore(today) && !completed.contains(date);
    }).length;
  }

  /// 현재 상태에서 도달 가능한 보상 성공일 목표의 최대값.
  int rewardTargetDaysLimit({DateTime? asOf}) {
    final limit =
        completedDayCount(asOf: asOf) + remainingScheduledDayCount(asOf: asOf);
    return limit < 1 ? 1 : limit;
  }

  /// 현재 상태에서 도달 가능한 벌칙 실패일 목표의 최대값.
  int penaltyTargetDaysLimit({DateTime? asOf}) {
    final limit =
        failedDayCount(asOf: asOf) + remainingScheduledDayCount(asOf: asOf);
    return limit < 1 ? 1 : limit;
  }

  DateTime _cutoffDate(DateTime? asOf) {
    final cutoff = _dateOnly(asOf ?? DateTime.now());
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    if (cutoff.isBefore(start)) return start.subtract(const Duration(days: 1));
    if (cutoff.isAfter(end)) return end;
    return cutoff;
  }

  List<DateTime> get _scheduledDates {
    final scheduledWeekdays = items
        .expand((item) => item.days)
        .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
        .toSet();
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    final dates = <DateTime>[];

    if (scheduledWeekdays.isEmpty) {
      var day = start;
      while (!day.isAfter(end)) {
        dates.add(day);
        day = day.add(const Duration(days: 1));
      }
      return dates;
    }

    var day = start;
    while (!day.isAfter(end)) {
      if (scheduledWeekdays.contains(day.weekday)) dates.add(day);
      day = day.add(const Duration(days: 1));
    }
    return dates;
  }

  static Set<DateTime> _uniqueDatesInRange(
    List<DateTime> dates,
    DateTime start,
    DateTime end,
  ) {
    if (end.isBefore(start)) return {};
    return dates
        .map(_dateOnly)
        .where((date) => !date.isBefore(start) && !date.isAfter(end))
        .toSet();
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class PlanItem {
  final String title;
  final List<int> days; // 1=Mon, 7=Sun
  final int count;
  final NotificationTime? notificationTime;
  final String? description;

  PlanItem({
    required this.title,
    required this.days,
    required this.count,
    this.notificationTime,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'days': days,
      'count': count,
      if (notificationTime != null)
        'notificationTime': notificationTime!.toMap(),
      if (description != null) 'description': description,
    };
  }

  factory PlanItem.fromMap(Map<String, dynamic> map) {
    return PlanItem(
      title: map['title'] ?? '',
      days: List<int>.from(map['days'] ?? []),
      count: map['count']?.toInt() ?? 0,
      notificationTime: map['notificationTime'] != null
          ? NotificationTime.fromMap(map['notificationTime'])
          : null,
      description: map['description'],
    );
  }
}

class NotificationTime {
  final String type; // 'preset' | 'custom'
  final String value; // 'morning' | 'lunch' | 'dinner' | 'bedtime' | 'HH:mm'
  final int hour;
  final int minute;
  final int alertOffset; // minutes before (0 means at time)

  /// 시간 단위 반복 간격(시간). 0이면 하루 한 번(기존 동작),
  /// 1 이상이면 [startHour]~[endHour] 사이에서 N시간마다 반복 알림.
  final int intervalHours;

  /// 시간 단위 반복 시 알림을 시작할 시각(포함). intervalHours가 0이면 무시.
  final int startHour;

  /// 시간 단위 반복 시 알림을 끝낼 시각(포함). intervalHours가 0이면 무시.
  final int endHour;

  NotificationTime({
    required this.type,
    required this.value,
    required this.hour,
    required this.minute,
    this.alertOffset = 0,
    this.intervalHours = 0,
    int? startHour,
    int? endHour,
  }) : startHour = startHour ?? hour,
       endHour = endHour ?? hour;

  /// 시간 단위 반복 알림 여부.
  bool get isHourly => intervalHours >= 1;

  /// 하루 동안 알림이 울릴 "시(hour)" 목록.
  ///
  /// - 하루 한 번(intervalHours == 0)이면 [targetHour] 하나만 반환한다.
  /// - 시간 단위 반복이면 [startHour]부터 [endHour]까지 간격만큼 나열한다.
  List<int> get scheduleHours {
    if (!isHourly) return [targetHour];
    final step = intervalHours < 1 ? 1 : intervalHours;
    final start = startHour.clamp(0, 23);
    final end = endHour.clamp(0, 23);
    if (end < start) return [start];
    final hours = <int>[];
    for (int h = start; h <= end; h += step) {
      hours.add(h);
    }
    return hours;
  }

  NotificationTime copyWith({
    String? type,
    String? value,
    int? hour,
    int? minute,
    int? alertOffset,
    int? intervalHours,
    int? startHour,
    int? endHour,
  }) {
    return NotificationTime(
      type: type ?? this.type,
      value: value ?? this.value,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      alertOffset: alertOffset ?? this.alertOffset,
      intervalHours: intervalHours ?? this.intervalHours,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
      'hour': hour,
      'minute': minute,
      'alertOffset': alertOffset,
      if (intervalHours > 0) 'intervalHours': intervalHours,
      if (intervalHours > 0) 'startHour': startHour,
      if (intervalHours > 0) 'endHour': endHour,
    };
  }

  factory NotificationTime.fromMap(Map<String, dynamic> map) {
    final hour = map['hour']?.toInt() ?? 20;
    return NotificationTime(
      type: map['type'] ?? 'preset',
      value: map['value'] ?? 'dinner',
      hour: hour,
      minute: map['minute']?.toInt() ?? 0,
      alertOffset: map['alertOffset']?.toInt() ?? 0,
      intervalHours: map['intervalHours']?.toInt() ?? 0,
      startHour: map['startHour']?.toInt() ?? hour,
      endHour: map['endHour']?.toInt() ?? hour,
    );
  }

  static NotificationTime preset(String value) {
    int hour = 20; // Default dinner
    int minute = 0;

    switch (value) {
      case 'morning':
        hour = 8;
        break;
      case 'lunch':
        hour = 12;
        break;
      case 'dinner':
        hour = 20;
        break;
      case 'bedtime':
        hour = 23;
        break;
    }

    return NotificationTime(
      type: 'preset',
      value: value,
      hour: hour,
      minute: minute,
      alertOffset: 0,
    );
  }

  static NotificationTime custom(int hour, int minute, {int alertOffset = 0}) {
    return NotificationTime(
      type: 'custom',
      value:
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      hour: hour,
      minute: minute,
      alertOffset: alertOffset,
    );
  }

  /// [startHour]~[endHour] 사이에서 [intervalHours]시간마다 반복되는 알림.
  /// 기간(계획의 startDate~endDate)은 그대로 두고 하루 안에서만 반복한다.
  static NotificationTime hourly({
    required int intervalHours,
    required int startHour,
    required int endHour,
    int minute = 0,
  }) {
    final interval = intervalHours < 1 ? 1 : intervalHours;
    return NotificationTime(
      type: 'custom',
      value:
          '${startHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}-${endHour.toString().padLeft(2, '0')}/$interval',
      hour: startHour,
      minute: minute,
      alertOffset: 0,
      intervalHours: interval,
      startHour: startHour,
      endHour: endHour,
    );
  }

  int get targetHour {
    final total = hour * 60 + minute + alertOffset;
    return (total % 1440) ~/ 60;
  }

  int get targetMinute {
    final total = hour * 60 + minute + alertOffset;
    return (total % 1440) % 60;
  }

  static NotificationTime none() {
    return NotificationTime(
      type: 'none',
      value: 'none',
      hour: 0,
      minute: 0,
      alertOffset: 0,
    );
  }
}
