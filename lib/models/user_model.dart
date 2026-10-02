import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? displayName;

  /// Only from the local cache ([UserModel.fromJson]) of builds that stored
  /// it. Never read from or written to Firestore any more: users docs are
  /// readable by any signed-in user (a partner's email must not travel), and
  /// the account's own email comes from FirebaseAuth.
  final String? email;
  final String? profileImageUrl;
  final String? statusMessage;
  final String? inviteCode;
  final LoginType loginType;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Client metadata the app keeps current on `users/{uid}` (see
  /// lib/core/services/client_metadata_sync.dart). All optional: documents
  /// written by older app versions do not have them.
  final int? clientBuild; // installed build number (version x.y.z+BUILD)
  final String? timezone; // IANA id, e.g. Asia/Seoul
  final String? locale; // 'ko' | 'en'

  /// What I call my partner (spec §4.2), at most 10 characters. Shown instead
  /// of the partner's display name on screen and in pushes; cleared when the
  /// couple disconnects. Optional — older documents don't have it.
  final String? partnerNickname;

  /// The one-time "그래,해봐가 둘운완이 됐어요" notice was seen. Optional; the
  /// device keeps its own flag first (spec §9).
  final bool? pivotNoticeSeen;

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
    this.clientBuild,
    this.timezone,
    this.locale,
    this.partnerNickname,
    this.pivotNoticeSeen,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'],
      profileImageUrl: data['profileImageUrl'],
      statusMessage: data['statusMessage'],
      inviteCode: data['inviteCode'],
      loginType: LoginType.values.byName(data['loginType'] ?? 'guest'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      clientBuild: (data['clientBuild'] as num?)?.toInt(),
      timezone: data['timezone'] as String?,
      locale: data['locale'] as String?,
      partnerNickname: _nicknameOf(data['partnerNickname']),
      pivotNoticeSeen: data['pivotNoticeSeen'] is bool
          ? data['pivotNoticeSeen'] as bool
          : null,
    );
  }

  /// A stored nickname, or null for a missing, empty or non-string value.
  static String? _nicknameOf(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
      clientBuild: (json['clientBuild'] as num?)?.toInt(),
      timezone: json['timezone'] as String?,
      locale: json['locale'] as String?,
      partnerNickname: _nicknameOf(json['partnerNickname']),
      pivotNoticeSeen: json['pivotNoticeSeen'] is bool
          ? json['pivotNoticeSeen'] as bool
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (displayName != null) 'displayName': displayName,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (statusMessage != null) 'statusMessage': statusMessage,
      if (inviteCode != null) 'inviteCode': inviteCode,
      'loginType': loginType.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (clientBuild != null) 'clientBuild': clientBuild,
      if (timezone != null) 'timezone': timezone,
      if (locale != null) 'locale': locale,
      if (partnerNickname != null) 'partnerNickname': partnerNickname,
      if (pivotNoticeSeen != null) 'pivotNoticeSeen': pivotNoticeSeen,
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
      if (clientBuild != null) 'clientBuild': clientBuild,
      if (timezone != null) 'timezone': timezone,
      if (locale != null) 'locale': locale,
      if (partnerNickname != null) 'partnerNickname': partnerNickname,
      if (pivotNoticeSeen != null) 'pivotNoticeSeen': pivotNoticeSeen,
    };
  }

  /// [clearPartnerNickname] drops the nickname (copyWith can't pass null).
  UserModel copyWith({
    String? displayName,
    String? statusMessage,
    String? profileImageUrl,
    LoginType? loginType,
    DateTime? updatedAt,
    String? partnerNickname,
    bool clearPartnerNickname = false,
    bool? pivotNoticeSeen,
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
      clientBuild: clientBuild,
      timezone: timezone,
      locale: locale,
      partnerNickname: clearPartnerNickname
          ? null
          : (partnerNickname ?? this.partnerNickname),
      pivotNoticeSeen: pivotNoticeSeen ?? this.pivotNoticeSeen,
    );
  }
}

enum LoginType { guest, google, apple, email }
