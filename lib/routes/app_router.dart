import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/connect_screen.dart';
import '../screens/home_screen.dart';
import '../screens/developer_screen.dart';
import '../screens/plan/plan_action_selection_screen.dart';
import '../screens/plan/plan_frequency_screen.dart';
import '../screens/plan/plan_description_screen.dart';
import '../screens/plan/plan_day_selection_screen.dart';
import '../screens/plan/plan_summary_screen.dart';
import '../screens/settings_screen.dart';

/// 앱 라우팅 경로 상수
class AppRoutes {
  AppRoutes._();
  
  static const String splash = '/';
  static const String login = '/login';
  static const String connect = '/connect';
  static const String home = '/home';
  static const String developer = '/developer';
  static const String settings = '/settings';
  
  // 계획 생성 플로우
  static const String planActionSelection = '/plan/action';
  static const String planFrequency = '/plan/frequency';
  static const String planDescription = '/plan/description';
  static const String planDaySelection = '/plan/days';
  static const String planSummary = '/plan/summary';
  
  // 딥링크 경로
  static const String deepLinkSplash = '/splash';
  static const String deepLinkLogin = '/login';
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
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
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
    // 계획 생성 플로우
    GoRoute(
      path: AppRoutes.planActionSelection,
      name: 'plan-action',
      builder: (context, state) => const PlanActionSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.planFrequency,
      name: 'plan-frequency',
      builder: (context, state) {
        final action = state.uri.queryParameters['action'];
        return PlanFrequencyScreen(action: action);
      },
    ),
    GoRoute(
      path: AppRoutes.planDescription,
      name: 'plan-description',
      builder: (context, state) {
        final action = state.uri.queryParameters['action'];
        final frequency = int.tryParse(state.uri.queryParameters['frequency'] ?? '');
        return PlanDescriptionScreen(
          action: action,
          frequency: frequency,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.planDaySelection,
      name: 'plan-days',
      builder: (context, state) {
        final action = state.uri.queryParameters['action'];
        final frequency = int.tryParse(state.uri.queryParameters['frequency'] ?? '');
        final description = state.uri.queryParameters['description'];
        return PlanDaySelectionScreen(
          action: action,
          frequency: frequency,
          description: description,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.planSummary,
      name: 'plan-summary',
      builder: (context, state) {
        final action = state.uri.queryParameters['action'];
        final frequency = int.tryParse(state.uri.queryParameters['frequency'] ?? '');
        final description = state.uri.queryParameters['description'];
        final days = state.uri.queryParameters['days'];
        return PlanSummaryScreen(
          action: action,
          frequency: frequency,
          description: description,
          days: days,
        );
      },
    ),
  ],
);

