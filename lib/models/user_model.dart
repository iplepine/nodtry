import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String? profileImageUrl;
  final String? statusMessage;
  final String? inviteCode;
  final LoginType loginType;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAnonymous => loginType == LoginType.guest;

  UserModel({
    required this.uid,
    this.displayName,
    this.email,
    this.profileImageUrl,
    this.statusMessage,
    this.inviteCode,
    this.loginType = LoginType.guest,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'],
      email: data['email'],
      profileImageUrl: data['profileImageUrl'],
      statusMessage: data['statusMessage'],
      inviteCode: data['inviteCode'],
      loginType: LoginType.values.byName(data['loginType'] ?? 'guest'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      displayName: json['displayName'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      statusMessage: json['statusMessage'],
      inviteCode: json['inviteCode'],
      loginType: LoginType.values.byName(json['loginType'] ?? 'guest'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (statusMessage != null) 'statusMessage': statusMessage,
      if (inviteCode != null) 'inviteCode': inviteCode,
      'loginType': loginType.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (statusMessage != null) 'statusMessage': statusMessage,
      if (inviteCode != null) 'inviteCode': inviteCode,
      'loginType': loginType.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? statusMessage,
    String? profileImageUrl,
    LoginType? loginType,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      inviteCode: inviteCode,
      loginType: loginType ?? this.loginType,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum LoginType { guest, google, apple, email }
