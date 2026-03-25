import 'package:cloud_firestore/cloud_firestore.dart';

enum PromiseStatus {
  proposed,
  active,
  settled,
  rejected;

  String toMap() {
    switch (this) {
      case PromiseStatus.proposed:
        return 'proposed';
      case PromiseStatus.active:
        return 'active';
      case PromiseStatus.settled:
        return 'settled';
      case PromiseStatus.rejected:
        return 'rejected';
    }
  }

  static PromiseStatus fromMap(String value) {
    switch (value) {
      case 'proposed':
        return PromiseStatus.proposed;
      case 'active':
        return PromiseStatus.active;
      case 'settled':
        return PromiseStatus.settled;
      case 'rejected':
        return PromiseStatus.rejected;
      default:
        return PromiseStatus.proposed;
    }
  }
}

enum SettlementResult {
  rewardAchieved,
  penaltyTriggered,
  neitherMet,
  bothMet;

  String toMap() {
    switch (this) {
      case SettlementResult.rewardAchieved:
        return 'reward_achieved';
      case SettlementResult.penaltyTriggered:
        return 'penalty_triggered';
      case SettlementResult.neitherMet:
        return 'neither_met';
      case SettlementResult.bothMet:
        return 'both_met';
    }
  }

  static SettlementResult fromMap(String value) {
    switch (value) {
      case 'reward_achieved':
        return SettlementResult.rewardAchieved;
      case 'penalty_triggered':
        return SettlementResult.penaltyTriggered;
      case 'neither_met':
        return SettlementResult.neitherMet;
      case 'both_met':
        return SettlementResult.bothMet;
      default:
        return SettlementResult.neitherMet;
    }
  }
}

class PromiseReward {
  final String description;
  final int targetDays;

  PromiseReward({
    required this.description,
    required this.targetDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'targetDays': targetDays,
    };
  }

  factory PromiseReward.fromMap(Map<String, dynamic> map) {
    return PromiseReward(
      description: map['description'] ?? '',
      targetDays: map['targetDays']?.toInt() ?? 1,
    );
  }
}

class PromisePenalty {
  final String description;
  final int targetDays;

  PromisePenalty({
    required this.description,
    required this.targetDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'targetDays': targetDays,
    };
  }

  factory PromisePenalty.fromMap(Map<String, dynamic> map) {
    return PromisePenalty(
      description: map['description'] ?? '',
      targetDays: map['targetDays']?.toInt() ?? 1,
    );
  }
}

class Promise {
  final PromiseStatus status;
  final String proposerId;
  final PromiseReward? reward;
  final PromisePenalty? penalty;
  final DateTime proposedAt;
  final DateTime? acceptedAt;
  final DateTime? settledAt;
  final int? settledSuccessDays;
  final int? settledFailDays;
  final SettlementResult? settlementResult;

  Promise({
    required this.status,
    required this.proposerId,
    this.reward,
    this.penalty,
    required this.proposedAt,
    this.acceptedAt,
    this.settledAt,
    this.settledSuccessDays,
    this.settledFailDays,
    this.settlementResult,
  });

  Promise copyWith({
    PromiseStatus? status,
    String? proposerId,
    PromiseReward? reward,
    PromisePenalty? penalty,
    DateTime? proposedAt,
    DateTime? acceptedAt,
    DateTime? settledAt,
    int? settledSuccessDays,
    int? settledFailDays,
    SettlementResult? settlementResult,
  }) {
    return Promise(
      status: status ?? this.status,
      proposerId: proposerId ?? this.proposerId,
      reward: reward ?? this.reward,
      penalty: penalty ?? this.penalty,
      proposedAt: proposedAt ?? this.proposedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      settledAt: settledAt ?? this.settledAt,
      settledSuccessDays: settledSuccessDays ?? this.settledSuccessDays,
      settledFailDays: settledFailDays ?? this.settledFailDays,
      settlementResult: settlementResult ?? this.settlementResult,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.toMap(),
      'proposerId': proposerId,
      if (reward != null) 'reward': reward!.toMap(),
      if (penalty != null) 'penalty': penalty!.toMap(),
      'proposedAt': Timestamp.fromDate(proposedAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (settledAt != null) 'settledAt': Timestamp.fromDate(settledAt!),
      if (settledSuccessDays != null) 'settledSuccessDays': settledSuccessDays,
      if (settledFailDays != null) 'settledFailDays': settledFailDays,
      if (settlementResult != null)
        'settlementResult': settlementResult!.toMap(),
    };
  }

  factory Promise.fromMap(Map<String, dynamic> map) {
    return Promise(
      status: PromiseStatus.fromMap(map['status'] ?? 'proposed'),
      proposerId: map['proposerId'] ?? '',
      reward: map['reward'] != null
          ? PromiseReward.fromMap(map['reward'] as Map<String, dynamic>)
          : null,
      penalty: map['penalty'] != null
          ? PromisePenalty.fromMap(map['penalty'] as Map<String, dynamic>)
          : null,
      proposedAt: (map['proposedAt'] as Timestamp).toDate(),
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      settledAt: map['settledAt'] != null
          ? (map['settledAt'] as Timestamp).toDate()
          : null,
      settledSuccessDays: map['settledSuccessDays']?.toInt(),
      settledFailDays: map['settledFailDays']?.toInt(),
      settlementResult: map['settlementResult'] != null
          ? SettlementResult.fromMap(map['settlementResult'])
          : null,
    );
  }
}
