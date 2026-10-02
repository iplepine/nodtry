import 'package:cloud_firestore/cloud_firestore.dart';

enum RelationStatus { pending, active, rejected }

class RelationModel {
  final String id;
  final String executorId; // 관리받는 사람 (Me if I am supported)
  final String managerId; // 관리하는 사람 (Me if I am cheering)
  final RelationStatus status;
  final DateTime createdAt;
  final DateTime? connectedAt;

  /// When this link was made: `connectedAt ?? createdAt` as stored, or null
  /// when the document has neither (legacy) — unlike [createdAt], which
  /// falls back to "now".
  final DateTime? linkedAt;

  RelationModel({
    required this.id,
    required this.executorId,
    required this.managerId,
    required this.status,
    required this.createdAt,
    this.connectedAt,
    DateTime? linkedAt,
  }) : linkedAt = linkedAt ?? connectedAt ?? createdAt;

  RelationModel._fromStored({
    required this.id,
    required this.executorId,
    required this.managerId,
    required this.status,
    required this.createdAt,
    required this.connectedAt,
    required this.linkedAt,
  });

  factory RelationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final storedCreatedAt = (data['createdAt'] as Timestamp?)?.toDate();
    final connectedAt = data['connectedAt'] != null
        ? (data['connectedAt'] as Timestamp).toDate()
        : null;
    return RelationModel._fromStored(
      id: doc.id,
      executorId: data['executorId'],
      managerId: data['managerId'],
      status: RelationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RelationStatus.pending,
      ),
      createdAt: storedCreatedAt ?? DateTime.now(),
      connectedAt: connectedAt,
      linkedAt: connectedAt ?? storedCreatedAt,
    );
  }
}
