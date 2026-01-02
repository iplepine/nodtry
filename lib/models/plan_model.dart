import 'package:cloud_firestore/cloud_firestore.dart';

enum PlanState {
  draft,
  pendingApproval,
  active,
  completed,
  rejected;

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

  Plan({
    this.id,
    required this.userId,
    this.managerId,
    required this.startDate,
    required this.endDate,
    required this.state,
    required this.items,
    required this.createdAt,
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
    };
  }

  factory Plan.fromMap(Map<String, dynamic> map, String id) {
    return Plan(
      id: id,
      userId: map['userId'] ?? '',
      managerId: map['managerId'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      state: PlanState.fromMap(map['state'] ?? 'draft'),
      items: List<PlanItem>.from(
        (map['items'] as List<dynamic>).map<PlanItem>(
          (x) => PlanItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
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

  NotificationTime({
    required this.type,
    required this.value,
    required this.hour,
    required this.minute,
  });

  Map<String, dynamic> toMap() {
    return {'type': type, 'value': value, 'hour': hour, 'minute': minute};
  }

  factory NotificationTime.fromMap(Map<String, dynamic> map) {
    return NotificationTime(
      type: map['type'] ?? 'preset',
      value: map['value'] ?? 'dinner',
      hour: map['hour']?.toInt() ?? 20,
      minute: map['minute']?.toInt() ?? 0,
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
    );
  }

  static NotificationTime custom(int hour, int minute) {
    return NotificationTime(
      type: 'custom',
      value:
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      hour: hour,
      minute: minute,
    );
  }

  static NotificationTime none() {
    return NotificationTime(type: 'none', value: 'none', hour: 0, minute: 0);
  }
}
