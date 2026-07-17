import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_localizations.dart';
import '../providers/notification_permission_provider.dart';
import '../theme/app_colors.dart';
import '../utils/analytics.dart';

/// Home-top warning banner shown when OS notification permission is off.
///
/// Partner check-ins and reminders depend on notifications, so when they're
/// disabled the whole accountability loop silently breaks. This nudges the user
/// back to Settings. It renders zero-size while permission is granted (or still
/// unknown), so there's no flash on cold start.
class NotificationPermissionBanner extends ConsumerStatefulWidget {
  const NotificationPermissionBanner({super.key});

  @override
  ConsumerState<NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends ConsumerState<NotificationPermissionBanner> {
  bool _loggedImpression = false;

  @override
  Widget build(BuildContext context) {
    // Treat "unknown" (loading/error) as enabled so the banner never flashes in
    // before we actually know permission is off.
    final enabled = ref.watch(notificationPermissionProvider).value ?? true;
    if (enabled) {
      _loggedImpression = false;
      return const SizedBox.shrink();
    }

    if (!_loggedImpression) {
      _loggedImpression = true;
      AnalyticsService.log(AnalyticsEvent.notificationBannerShown);
    }

    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      bottom: false,
      child: Material(
        color: AppColors.warningSoft,
        child: InkWell(
          onTap: _openSettings,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.warningBorder),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 22,
                    color: AppColors.warningStrong,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.notifyBannerTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warningStrong,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.notifyBannerBody,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.notifyBannerAction,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    AnalyticsService.log(AnalyticsEvent.notificationBannerTapped);
    await openAppSettings();
    if (!mounted) return;
    // Re-check after the user comes back; the home also re-checks on resume,
    // but invalidating here refreshes immediately when settings closes in-app.
    ref.invalidate(notificationPermissionProvider);
  }
}
