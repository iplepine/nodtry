import 'package:cloud_firestore/cloud_firestore.dart';

enum RelationStatus { pending, active, rejected }

class RelationModel {
  final String id;
  final String executorId; // 관리받는 사람 (Me if I am supported)
  final String managerId; // 관리하는 사람 (Me if I am cheering)
  final RelationStatus status;
  final DateTime createdAt;
  final DateTime? connectedAt;

  RelationModel({
    required this.id,
    required this.executorId,
    required this.managerId,
    required this.status,
    required this.createdAt,
    this.connectedAt,
  });

  factory RelationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RelationModel(
      id: doc.id,
      executorId: data['executorId'],
      managerId: data['managerId'],
      status: RelationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RelationStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      connectedAt: data['connectedAt'] != null
          ? (data['connectedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
