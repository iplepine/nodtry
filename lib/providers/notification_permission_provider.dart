import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/notification_service.dart';

/// Whether the OS currently grants notification permission.
///
/// The app's core loop (partner check-ins, missed-action nudges, reminders) is
/// delivered via notifications, so the UI watches this to nudge the user to
/// re-enable when it's off. Invalidate this on app resume to re-check after the
/// user returns from OS settings.
final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  return ref.read(notificationServiceProvider).hasPermission();
});
