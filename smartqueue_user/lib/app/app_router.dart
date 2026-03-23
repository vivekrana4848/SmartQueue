import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/sector/sector_screen.dart';
import '../screens/branch/branch_screen.dart';
import '../screens/service/service_screen.dart';
import '../screens/token/token_form_screen.dart';
import '../screens/queue/live_queue_screen.dart';
import '../screens/queue/my_tokens_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final status = authProvider.status;
        final isAuth = status == AuthStatus.authenticated;
        final isLoading = status == AuthStatus.loading;
        final isAuthRoute = state.matchedLocation.startsWith('/auth');

        if (isLoading) return null;
        if (!isAuth && !isAuthRoute) return '/auth/login';
        if (isAuth && isAuthRoute) return '/dashboard';
        return null;
      },
      refreshListenable: authProvider,
      routes: [
        GoRoute(path: '/', redirect: (_, __) => '/auth/login'),

        // Auth routes
        GoRoute(
          path: '/auth/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/signup',
          builder: (_, __) => const SignupScreen(),
        ),
        GoRoute(
          path: '/auth/otp',
          builder: (context, state) {
            final phone = state.extra as String? ?? '';
            return OtpScreen(phone: phone);
          },
        ),

        // Main routes
        ShellRoute(
          builder: (context, state, child) => DashboardScreen(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              redirect: (_, __) => '/dashboard/sectors',
            ),
            GoRoute(
              path: '/dashboard/sectors',
              builder: (_, __) => const SectorScreen(),
              routes: [
                GoRoute(
                  path: ':sectorId/branches',
                  builder: (context, state) {
                    return BranchScreen(
                      sectorId: state.pathParameters['sectorId']!,
                      sectorName: state.extra as String? ?? '',
                    );
                  },
                  routes: [
                    GoRoute(
                      path: ':branchId/services',
                      builder: (context, state) {
                        final extra =
                            state.extra as Map<String, String>? ?? {};
                        return ServiceScreen(
                          branchId: state.pathParameters['branchId']!,
                          sectorId: state.pathParameters['sectorId']!,
                          extra: extra,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/dashboard/token-form',
              builder: (context, state) {
                return const TokenFormScreen();
              },
            ),
            GoRoute(
              path: '/dashboard/queue/:tokenId',
              builder: (context, state) {
                return LiveQueueScreen(
                    tokenId: state.pathParameters['tokenId']!);
              },
            ),
            GoRoute(
              path: '/dashboard/my-tokens',
              builder: (_, __) => const MyTokensScreen(),
            ),
            GoRoute(
              path: '/dashboard/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Page not found: ${state.error}')),
      ),
    );
  }
}
