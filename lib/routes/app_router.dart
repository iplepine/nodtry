import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/connect_screen.dart';
import '../screens/home_screen.dart';
import '../screens/developer_screen.dart';

/// 앱 라우팅 경로 상수
class AppRoutes {
  AppRoutes._();
  
  static const String splash = '/';
  static const String login = '/login';
  static const String connect = '/connect';
  static const String home = '/home';
  static const String developer = '/developer';
  
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
  ],
);

