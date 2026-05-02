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
  final String? lastActionNote; // 마지막 실천 한마디 (실천자)
  final String? lastComment; // 마지막 피드백/응원 메시지 (매니저)
  final String? lastUpdatedBy; // 마지막으로 문서를 수정한 사람의 UID
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
    this.lastActionNote,
    this.lastComment,
    this.lastUpdatedBy,
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
    String? lastActionNote,
    String? lastComment,
    String? lastUpdatedBy,
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
      lastActionNote: lastActionNote ?? this.lastActionNote,
      lastComment: lastComment ?? this.lastComment,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
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
      if (lastActionNote != null) 'lastActionNote': lastActionNote,
      if (lastComment != null) 'lastComment': lastComment,
      if (lastUpdatedBy != null) 'lastUpdatedBy': lastUpdatedBy,
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
      lastActionNote: map['lastActionNote'],
      lastComment: effectiveLastComment,
      lastUpdatedBy: map['lastUpdatedBy'],
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

  NotificationTime({
    required this.type,
    required this.value,
    required this.hour,
    required this.minute,
    this.alertOffset = 0,
  });

  NotificationTime copyWith({
    String? type,
    String? value,
    int? hour,
    int? minute,
    int? alertOffset,
  }) {
    return NotificationTime(
      type: type ?? this.type,
      value: value ?? this.value,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      alertOffset: alertOffset ?? this.alertOffset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
      'hour': hour,
      'minute': minute,
      'alertOffset': alertOffset,
    };
  }

  factory NotificationTime.fromMap(Map<String, dynamic> map) {
    return NotificationTime(
      type: map['type'] ?? 'preset',
      value: map['value'] ?? 'dinner',
      hour: map['hour']?.toInt() ?? 20,
      minute: map['minute']?.toInt() ?? 0,
      alertOffset: map['alertOffset']?.toInt() ?? 0,
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
