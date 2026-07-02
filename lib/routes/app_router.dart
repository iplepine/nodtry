import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/connect/presentation/screens/connect_screen.dart';
import '../screens/home_screen.dart';
import '../screens/developer_screen.dart';
import '../features/plan/presentation/screens/plan_create_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/notification_settings_screen.dart';
import '../features/tutorial/presentation/tutorial_screen.dart';
import '../features/auth/presentation/screens/email_login_screen.dart';
import '../models/plan_model.dart';
import '../features/plan/presentation/screens/plan_detail_screen.dart';
import '../features/plan/presentation/screens/all_plans_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/repository_provider.dart';
import '../models/user_model.dart';
import '../models/connected_user.dart';
import '../utils/analytics.dart';
import '../utils/error_reporter.dart';

/// 앱 라우팅 경로 상수
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String connect = '/connect';
  static const String home = '/home';
  static const String developer = '/developer';
  static const String settings = '/settings';
  static const String tutorial = '/tutorial';

  // 계획 생성 및 조회 플로우
  static const String planCreate = '/plan/create';
  static const String allPlans = '/plan/all';

  // 로그인
  static const String emailLogin = '/login/email';

  // 딥링크 경로
  static const String deepLinkSplash = '/splash';
  static const String deepLinkConnect = '/connect';
  static const String deepLinkHome = '/home';
  static const String deepLinkDeveloper = '/developer';
}

/// Firebase [User]의 인증 제공자에서 로그인 방식을 추론한다.
String _loginMethod(User? user) {
  if (user == null) return 'none';
  if (user.isAnonymous) return 'anonymous';
  for (final p in user.providerData) {
    switch (p.providerId) {
      case 'google.com':
        return 'google';
      case 'apple.com':
        return 'apple';
      case 'password':
        return 'email';
    }
  }
  return user.providerData.isNotEmpty
      ? user.providerData.first.providerId
      : 'unknown';
}

/// 라우터의 리다이렉션을 트리거하기 위한 Notifier.
/// 더불어 인증/연결 상태가 바뀔 때 Analytics·Crashlytics의 사용자 식별과
/// 세그먼트 프로퍼티(login_method, has_partner)를 동기화한다.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(authStateChangesProvider, (_, next) {
      final uid = next.value?.uid;
      AnalyticsService.setUserId(uid);
      ErrorReporter.setUser(uid);
      AnalyticsService.setUserProperty(
        AnalyticsUserProperty.loginMethod,
        _loginMethod(next.value),
      );
      notifyListeners();
    }, fireImmediately: true);
    _ref.listen<AsyncValue<UserModel?>>(
      myProfileProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<AsyncValue<List<ConnectedUser>>>(connectedProfilesProvider, (
      _,
      next,
    ) {
      // 로딩/에러 상태에서는 아직 모르므로 데이터가 있을 때만 갱신한다.
      if (next is AsyncData<List<ConnectedUser>>) {
        AnalyticsService.setUserProperty(
          AnalyticsUserProperty.hasPartner,
          next.value.isNotEmpty ? 'true' : 'false',
        );
      }
    });
  }
}

/// GoRouter Provider
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    // Auto-logs `screen_view` for every route push.
    observers: [AnalyticsService.observer()],
    redirect: (context, state) {
      // 1. 인증 상태 및 프로필 감시
      final authAsync = ref.read(authStateChangesProvider);
      final profileAsync = ref.read(myProfileProvider);

      // 로딩 중일 때는 리다이렉션 유보
      if (authAsync.isLoading || profileAsync.isLoading) return null;

      final user = authAsync.value;
      final profile = profileAsync.value;

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isEmailLogin = state.matchedLocation == AppRoutes.emailLogin;
      final isTutorial = state.matchedLocation == AppRoutes.tutorial;

      // 로그인이 안 되어 있거나 프로필이 없는 경우
      if (user == null || profile == null) {
        // 이미 스플래시나 로그인 화면이면 그대로 둠
        if (isSplash || isEmailLogin || isTutorial) return null;
        // 다른 보호된 화면이면 스플래시로 강제 이동
        return AppRoutes.splash;
      }

      // 로그인이 되어 있는 상태인데 스플래시나 로그인 화면에 머물러 있으면 홈으로 이동
      if (isSplash || isEmailLogin) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.connect,
        name: 'connect',
        builder: (context, state) => const ConnectScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.developer,
        name: 'developer',
        builder: (context, state) => const DeveloperScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        name: 'tutorial',
        builder: (context, state) => const TutorialScreen(),
      ),
      // 통합 계획 생성 화면
      GoRoute(
        path: AppRoutes.planCreate,
        name: 'plan-create',
        builder: (context, state) {
          final planToEdit = state.extra as Plan?;
          final startAtLastStep =
              state.uri.queryParameters['startAtLastStep'] == 'true';
          return PlanCreateScreen(
            planToEdit: planToEdit,
            startAtLastStep: startAtLastStep,
          );
        },
      ),
      // 계획 상세 화면
      GoRoute(
        path: '/plan/detail',
        name: 'plan-detail',
        builder: (context, state) {
          final plan = state.extra as Plan;
          return PlanDetailScreen(plan: plan);
        },
      ),
      GoRoute(
        path: AppRoutes.emailLogin,
        name: 'email-login',
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.allPlans,
        name: 'all-plans',
        builder: (context, state) {
          final userId = state.extra as String;
          return AllPlansScreen(userId: userId);
        },
      ),
    ],
  );
});

// Deprecated: Use routerProvider instead
@Deprecated('Use ref.watch(routerProvider) instead')
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [], // Empty to avoid confusion, but kept for symbol compatibility
);
