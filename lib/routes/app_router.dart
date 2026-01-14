import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/connect/presentation/screens/connect_screen.dart';
import '../screens/home_screen.dart';
import '../screens/developer_screen.dart';
import '../features/plan/presentation/screens/plan_create_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/notification_settings_screen.dart';
import '../features/auth/presentation/screens/email_login_screen.dart';
import '../models/plan_model.dart';
import '../features/plan/presentation/screens/plan_detail_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../providers/repository_provider.dart';

/// 앱 라우팅 경로 상수
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String connect = '/connect';
  static const String home = '/home';
  static const String developer = '/developer';
  static const String settings = '/settings';

  // 계획 생성 플로우
  static const String planCreate = '/plan/create';

  // 로그인
  static const String emailLogin = '/login/email';

  // 딥링크 경로
  static const String deepLinkSplash = '/splash';
  static const String deepLinkConnect = '/connect';
  static const String deepLinkHome = '/home';
  static const String deepLinkDeveloper = '/developer';
}

/// 라우터의 리다이렉션을 트리거하기 위한 Notifier
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<void>>(
      authStateChangesProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<AsyncValue<void>>(
      myProfileProvider,
      (_, __) => notifyListeners(),
    );
  }
}

/// GoRouter Provider
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,
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

      // 로그인이 안 되어 있거나 프로필이 없는 경우
      if (user == null || profile == null) {
        // 이미 스플래시나 로그인 화면이면 그대로 둠
        if (isSplash || isEmailLogin) return null;
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
      // 통합 계획 생성 화면
      GoRoute(
        path: AppRoutes.planCreate,
        name: 'plan-create',
        builder: (context, state) {
          final planToEdit = state.extra as Plan?;
          return PlanCreateScreen(planToEdit: planToEdit);
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
    ],
  );
});

// Deprecated: Use routerProvider instead
@Deprecated('Use ref.watch(routerProvider) instead')
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [], // Empty to avoid confusion, but kept for symbol compatibility
);
