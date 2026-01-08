import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../routes/app_router.dart';
import '../l10n/app_localizations.dart';
import '../providers/repository_provider.dart';
import '../services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import '../models/plan_model.dart';
import 'dart:io';

/// 개발자 화면 - 모든 화면으로 이동할 수 있는 디버그 화면
class DeveloperScreen extends ConsumerStatefulWidget {
  const DeveloperScreen({super.key});

  @override
  ConsumerState<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends ConsumerState<DeveloperScreen> {
  final TextEditingController _alarmTimesController = TextEditingController(
    text: '5, 10',
  );

  @override
  void dispose() {
    _alarmTimesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.developerTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 내 정보 섹션
              _buildUserInfoSection(context, ref),
              SizedBox(height: 32),

              // 데이터 소스 섹션
              _buildRepositorySection(context, ref),
              SizedBox(height: 32),

              // 알람 디버그 섹션
              _buildAlarmDebugSection(context, ref),
              SizedBox(height: 32),

              // 메인 화면 섹션
              _buildScreenSection(
                context,
                title: l10n.developerMainSection,
                screens: [
                  _ScreenInfo(
                    name: l10n.developerScreenHome,
                    route: AppRoutes.home,
                    description: l10n.developerScreenHomeDesc,
                    icon: Icons.home,
                  ),
                  _ScreenInfo(
                    name: l10n.developerScreenSettings,
                    route: AppRoutes.settings,
                    description: l10n.developerScreenSettingsDesc,
                    icon: Icons.settings,
                  ),
                ],
              ),
              SizedBox(height: 32),
              // 계획 생성 섹션
              _buildScreenSection(
                context,
                title: l10n.developerPlanSection,
                screens: [
                  _ScreenInfo(
                    name: l10n.developerScreenActionSelection,
                    route: AppRoutes.planCreate,
                    description: l10n.developerScreenActionSelectionDesc,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
              SizedBox(height: 32),

              // 인증 & 연결 섹션
              _buildScreenSection(
                context,
                title: l10n.developerAuthSection,
                screens: [
                  _ScreenInfo(
                    name: l10n.developerScreenSplash,
                    route: AppRoutes.splash,
                    description: l10n.developerScreenSplashDesc,
                    icon: Icons.rocket_launch,
                  ),
                  _ScreenInfo(
                    name: l10n.developerScreenConnect,
                    route: AppRoutes.connect,
                    description: l10n.developerScreenConnectDesc,
                    icon: Icons.link,
                  ),
                ],
              ),
              SizedBox(height: 32),

              // 딥링크 섹션
              Divider(height: 32),
              Text(
                l10n.developerDeepLink,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.developerDeepLinkFormat,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildDeepLinkItem(
                      l10n.developerScreenSplash,
                      'onmybehalf://splash',
                    ),
                    _buildDeepLinkItem(
                      l10n.developerScreenConnect,
                      'onmybehalf://connect',
                    ),
                    _buildDeepLinkItem(
                      l10n.developerScreenHome,
                      'onmybehalf://home',
                    ),
                    _buildDeepLinkItem(
                      l10n.developerScreenDeveloper,
                      'onmybehalf://developer',
                    ),
                    _buildDeepLinkItem(
                      l10n.developerScreenSettings,
                      'onmybehalf://settings',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // 푸시 테스트 섹션
              _buildPushTestSection(context, ref),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: profileAsync.when(
            data: (user) {
              if (user == null) return Text('로그인 정보가 없습니다.');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(context, 'UID', user.uid),
                  _buildInfoRow(context, 'Name', user.displayName ?? 'N/A'),
                  _buildInfoRow(context, 'Email', user.email ?? 'N/A'),
                  _buildInfoRow(
                    context,
                    'Invite Code',
                    user.inviteCode ?? 'N/A',
                  ),
                  FutureBuilder<String?>(
                    future: FirebaseMessaging.instance.getToken(),
                    builder: (context, snapshot) {
                      return _buildInfoRow(
                        context,
                        'FCM Token',
                        snapshot.data ?? 'Loading...',
                      );
                    },
                  ),
                ],
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: TextStyle(fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 16, color: AppColors.primary),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label 복사되었습니다.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          Divider(height: 1, color: AppColors.divider.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildPushTestSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Push Notification Test',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _buildPushTestButton(
                context,
                title: '나에게 약속 제안 푸시 보내기',
                subtitle: 'onPlanCreated 트리거 테스트',
                icon: Icons.assignment_turned_in,
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  final now = DateTime.now();
                  final plan = Plan(
                    userId: 'DEBUG_SENDER',
                    managerId: user.uid,
                    state: PlanState.pendingApproval,
                    createdAt: now,
                    startDate: now,
                    endDate: now.add(Duration(days: 30)),
                    items: [
                      PlanItem(
                        title: '테스트 약속입니다! ✉️',
                        days: [1, 2, 3, 4, 5, 6, 7],
                        count: 1,
                      ),
                    ],
                  );

                  try {
                    await ref.read(recordRepositoryProvider).createPlan(plan);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('약속 생성 완료! 잠시 후 푸시가 도착합니다.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
                  }
                },
              ),
              Divider(height: 24),
              _buildPushTestButton(
                context,
                title: '나에게 응원 푸시 보내기',
                subtitle: 'onCheerCreated 트리거 테스트',
                icon: Icons.favorite,
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  try {
                    // cheers 컬렉션에 임의의 문서 생성
                    await FirebaseFirestore.instance.collection('cheers').add({
                      'fromUserId': 'DEBUG_SENDER',
                      'toUserId': user.uid,
                      'message': '잘 하고 있어요! 화이팅! 💪',
                      'reactionType': 'heart',
                      'planId': 'test_plan_id',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('응원 생성 완료! 잠시 후 푸시가 도착합니다.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
                  }
                },
              ),
              Divider(height: 24),
              _buildPushTestButton(
                context,
                title: '나에게 실천 완료 푸시 보내기',
                subtitle: 'onActionCompleted 트리거 테스트',
                icon: Icons.check_circle,
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  try {
                    final plans = await FirebaseFirestore.instance
                        .collection('plans')
                        .where('managerId', isEqualTo: user.uid)
                        .limit(1)
                        .get();

                    if (plans.docs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('매니저로 등록된 계획이 없습니다.')),
                      );
                      return;
                    }

                    final planId = plans.docs.first.id;
                    final planTitle =
                        (plans.docs.first.data()['items'] as List?)
                            ?.firstOrNull?['title'] ??
                        '테스트 계획';

                    await FirebaseFirestore.instance.collection('actions').add({
                      'userId': 'DEBUG_SENDER',
                      'planId': planId,
                      'date': Timestamp.now(),
                      'type': 'done',
                      'title': planTitle,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('실천 기록 생성 완료! 푸시를 확인하세요.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
                  }
                },
              ),
              Divider(height: 24),
              _buildPushTestButton(
                context,
                title: '나에게 계획 수정 푸시 보내기',
                subtitle: 'onPlanUpdated 트리거 테스트',
                icon: Icons.edit_note,
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  try {
                    final plans = await FirebaseFirestore.instance
                        .collection('plans')
                        .where('managerId', isEqualTo: user.uid)
                        .limit(1)
                        .get();

                    if (plans.docs.isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('수정할 계획이 없습니다.')));
                      return;
                    }

                    final docRef = plans.docs.first.reference;
                    final currentData = plans.docs.first.data();
                    final currentItems = List.from(currentData['items'] ?? []);

                    if (currentItems.isNotEmpty) {
                      currentItems[0]['title'] =
                          '${currentItems[0]['title']} (수정됨)';
                    }

                    await docRef.update({
                      'items': currentItems,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('계획 수정 완료! 푸시를 확인하세요.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPushTestButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Icon(Icons.send, size: 16, color: AppColors.textSecondary),
      onTap: onPressed,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRepositorySection(BuildContext context, WidgetRef ref) {
    final currentTypeAsync = ref.watch(repositoryTypeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Source',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: currentTypeAsync.when(
            data: (type) => Column(
              children: [
                RadioListTile<RepositoryType>(
                  title: Text('Mock Data'),
                  subtitle: Text('사용자 정의 테스트 데이터를 사용합니다.'),
                  value: RepositoryType.mock,
                  groupValue: type,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(repositoryTypeProvider.notifier).setType(value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                ),
                RadioListTile<RepositoryType>(
                  title: Text('Real Data (Firestore)'),
                  subtitle: Text('실제 서버 데이터를 사용합니다.'),
                  value: RepositoryType.real,
                  groupValue: type,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(repositoryTypeProvider.notifier).setType(value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                ),
                if (type == RepositoryType.mock) ...[
                  Divider(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '디버그 상태 확인',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Now Tab의 플로팅 액션 버튼(버그 아이콘)을 사용하여 다양한 UI 상태를 테스트할 수 있습니다.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error loading settings: $err'),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenSection(
    BuildContext context, {
    required String title,
    required List<_ScreenInfo> screens,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        ...screens.map((screen) => _buildScreenCard(context, screen)),
      ],
    );
  }

  Widget _buildScreenCard(BuildContext context, _ScreenInfo screen) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(screen.route),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(screen.icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        screen.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        screen.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmDebugSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alarm Debug',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AlarmPermissionWidget(),
              const Divider(height: 32),
              _AlarmListWidget(),
              const Divider(height: 32),

              // 다중 시간 입력 필드
              Text(
                '예약 시간 (초, 콤마로 구분)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _alarmTimesController,
                decoration: InputDecoration(
                  hintText: '예: 5, 10, 15',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final input = _alarmTimesController.text;
                        final secondsList = input
                            .split(',')
                            .map((s) => int.tryParse(s.trim()))
                            .whereType<int>()
                            .toList();

                        if (secondsList.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('올바른 시간을 입력해주세요. (예: 5, 10)'),
                            ),
                          );
                          return;
                        }

                        // DateTime 배열로 변환 (현재 시간 + 입력 초)
                        final now = DateTime.now();
                        final scheduledDates = secondsList
                            .map((s) => now.add(Duration(seconds: s)))
                            .toList();

                        // SetAlarmUseCase 호출
                        await ref
                            .read(setAlarmUseCaseProvider)
                            .execute(scheduledDates);

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${secondsList.length}개의 알람이 예약되었습니다.',
                            ),
                          ),
                        );
                      },
                      child: const Text('알람 예약'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await ref
                            .read(showInstantNotificationUseCaseProvider)
                            .execute(
                              id: 88888,
                              title: '즉시 테스트 알람',
                              body: '즉시 울리는 테스트 알람입니다.',
                            );
                      },
                      child: const Text('즉시 테스트'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    onPressed: () async {
                      await ref
                          .read(cancelAllNotificationsUseCaseProvider)
                          .execute();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('모든 알람이 취소되었습니다.')),
                      );
                    },
                    tooltip: '모든 알람 취소',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeepLinkItem(String name, String url) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                SelectableText(
                  url,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 화면 정보 모델
class _ScreenInfo {
  final String name;
  final String route;
  final String description;
  final IconData icon;

  _ScreenInfo({
    required this.name,
    required this.route,
    required this.description,
    required this.icon,
  });
}

class _AlarmListWidget extends StatefulWidget {
  @override
  State<_AlarmListWidget> createState() => _AlarmListWidgetState();
}

class _AlarmListWidgetState extends State<_AlarmListWidget> {
  List<PendingNotificationRequest> _pending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    final pending = await NotificationService().getPendingNotifications();
    if (mounted) {
      setState(() {
        _pending = pending;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '대기 중인 알람 (${_pending.length})',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.refresh, size: 20),
              onPressed: _refresh,
            ),
          ],
        ),
        if (_pending.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('대기 중인 알람이 없습니다.', style: TextStyle(fontSize: 12)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _pending.length,
            itemBuilder: (context, index) {
              final req = _pending[index];
              return ListTile(
                dense: true,
                title: Text('[${req.id}] ${req.title ?? "No Title"}'),
                subtitle: Text(req.body ?? "No Body"),
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
      ],
    );
  }
}

class _AlarmPermissionWidget extends StatefulWidget {
  @override
  State<_AlarmPermissionWidget> createState() => _AlarmPermissionWidgetState();
}

class _AlarmPermissionWidgetState extends State<_AlarmPermissionWidget> {
  bool? _isGranted;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService().canScheduleExactAlarms();
    if (mounted) {
      setState(() {
        _isGranted = granted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGranted == null) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          _isGranted! ? Icons.check_circle : Icons.warning,
          color: _isGranted! ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isGranted! ? '정확한 알람 권한 허용됨' : '정확한 알람 권한 필요',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isGranted! ? Colors.green : Colors.orange,
                ),
              ),
              if (!_isGranted!)
                const Text(
                  'Android 13+에서는 이 권한이 있어야 정확한 시간에 알람이 울립니다.',
                  style: TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
        if (!_isGranted! && Platform.isAndroid)
          TextButton(
            onPressed: () async {
              await openAppSettings();
              _checkPermission();
            },
            child: const Text('설정 열기'),
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _checkPermission,
        ),
      ],
    );
  }
}
