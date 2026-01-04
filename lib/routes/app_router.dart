import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/connect/presentation/screens/connect_screen.dart';
import '../screens/home_screen.dart';
import '../screens/developer_screen.dart';
import '../features/plan/presentation/screens/plan_create_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/auth/presentation/screens/email_login_screen.dart';
import '../models/plan_model.dart';
import '../features/plan/presentation/screens/plan_detail_screen.dart';

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

/// GoRouter 설정
///
/// 딥링크 지원:
/// - onmybehalf://splash
/// - onmybehalf://login
/// - onmybehalf://connect
/// - onmybehalf://home
/// - onmybehalf://developer
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
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
    // 계획 생성 플로우 (기존 단계별 화면 - 하위 호환성 유지)
    GoRoute(
      path: AppRoutes.emailLogin,
      name: 'email-login',
      builder: (context, state) => const EmailLoginScreen(),
    ),
  ],
);
