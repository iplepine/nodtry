import 'package:cloud_functions/cloud_functions.dart';

/// Calls the HTTPS callable [name] with [data] and returns the result's
/// `data`. Injectable so the repositories can be tested without Firebase.
typedef CallableInvoker =
    Future<Object?> Function(String name, Map<String, Object?> data);

/// The production [CallableInvoker] (default region, like functions/src).
Future<Object?> firebaseCallableInvoker(
  String name,
  Map<String, Object?> data,
) async {
  final result = await FirebaseFunctions.instance
      .httpsCallable(name)
      .call<Object?>(data);
  return result.data;
}

/// `resolveInviteCode({code})`: who holds a code, for the confirm sheet.
const String kResolveInviteCodeCallable = 'resolveInviteCode';

/// `redeemInviteCode({code})`: links me with the code's owner (server-side).
const String kRedeemInviteCodeCallable = 'redeemInviteCode';

/// Why an invite-code callable refused, from the server's `details.reason`
/// (functions/src/index.ts), plus [unavailable] for a backend that doesn't
/// have the callables yet.
enum InviteCallableFailure {
  /// The callable isn't deployed (`not-found` / `unimplemented` without a
  /// reason): the app falls back to the direct Firestore path, which works
  /// while firestore.rules (not rules.next) is deployed.
  unavailable,
  codeFormat,
  notFound,
  selfCode,
  selfTaken,
  ownerTaken,
  rateLimited,
}

/// Classifies [error] thrown by an invite-code callable, or returns null for
/// any other failure (offline, internal, unauthenticated), which the caller
/// surfaces as a plain failure.
InviteCallableFailure? inviteCallableFailureOf(Object error) {
  if (error is! FirebaseFunctionsException) return null;
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  switch (reason) {
    case 'code_format':
      return InviteCallableFailure.codeFormat;
    case 'not_found':
      return InviteCallableFailure.notFound;
    case 'self_code':
      return InviteCallableFailure.selfCode;
    case 'self_taken':
      return InviteCallableFailure.selfTaken;
    case 'owner_taken':
      return InviteCallableFailure.ownerTaken;
    case 'rate_limited':
      return InviteCallableFailure.rateLimited;
  }
  // The server always sends a reason with its own errors, so a bare
  // not-found (HTTP 404) or unimplemented means the function isn't there.
  if (reason == null &&
      (error.code == 'not-found' || error.code == 'unimplemented')) {
    return InviteCallableFailure.unavailable;
  }
  return null;
}

/// The owner of a code as `resolveInviteCode` returns it.
class ResolvedInviter {
  const ResolvedInviter({
    required this.uid,
    this.displayName,
    this.profileImageUrl,
  });

  /// Parses the callable's `{uid, displayName, profileImageUrl}`.
  factory ResolvedInviter.fromData(Object? data) {
    if (data is! Map) {
      throw const FormatException('resolveInviteCode: not a map');
    }
    final uid = data['uid'];
    if (uid is! String || uid.isEmpty) {
      throw const FormatException('resolveInviteCode: no uid');
    }
    return ResolvedInviter(
      uid: uid,
      displayName: _nonEmptyString(data['displayName']),
      profileImageUrl: _nonEmptyString(data['profileImageUrl']),
    );
  }

  final String uid;
  final String? displayName;
  final String? profileImageUrl;
}

/// The result of `redeemInviteCode`: the partner (code owner) and whether
/// we were already linked (then nothing was written).
class RedeemedInvite {
  const RedeemedInvite({required this.partnerId, required this.alreadyLinked});

  factory RedeemedInvite.fromData(Object? data) {
    if (data is! Map) {
      throw const FormatException('redeemInviteCode: not a map');
    }
    final partnerId = data['partnerId'];
    if (partnerId is! String || partnerId.isEmpty) {
      throw const FormatException('redeemInviteCode: no partnerId');
    }
    return RedeemedInvite(
      partnerId: partnerId,
      alreadyLinked: data['alreadyLinked'] == true,
    );
  }

  final String partnerId;
  final bool alreadyLinked;
}

String? _nonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
