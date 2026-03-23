import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/branch_selection_screen.dart';
import '../screens/home/service_selection_screen.dart';
import '../screens/home/token_confirmation_screen.dart';
import '../screens/queue/live_queue_screen.dart';
import '../screens/queue/my_tokens_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => DashboardScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/my-tokens',
            builder: (context, state) => const MyTokensScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/branches/:sectorId',
        builder: (context, state) => BranchSelectionScreen(
          sectorId: state.pathParameters['sectorId']!,
          sectorName: state.uri.queryParameters['name']!,
        ),
      ),
      GoRoute(
        path: '/services/:branchId',
        builder: (context, state) => ServiceSelectionScreen(
          branchId: state.pathParameters['branchId']!,
          branchName: state.uri.queryParameters['name']!,
          sectorId: state.uri.queryParameters['sectorId']!,
          sectorName: state.uri.queryParameters['sectorName']!,
        ),
      ),
      GoRoute(
        path: '/token-confirm',
        builder: (context, state) => TokenConfirmationScreen(
          tokenId: state.uri.queryParameters['tokenId'],
          sectorId: state.uri.queryParameters['sectorId'],
          branchId: state.uri.queryParameters['branchId'],
          serviceId: state.uri.queryParameters['serviceId'],
        ),
      ),
      GoRoute(
        path: '/live-queue/:tokenId',
        builder: (context, state) => LiveQueueScreen(
          tokenId: state.pathParameters['tokenId']!,
        ),
      ),
    ],
  );
}
