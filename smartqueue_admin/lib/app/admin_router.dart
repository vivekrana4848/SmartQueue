import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/admin_providers.dart';
import '../screens/auth/admin_login_screen.dart';
import '../screens/dashboard/admin_dashboard_screen.dart';
import '../screens/sector/sector_management_screen.dart';
import '../screens/branch/branch_management_screen.dart';
import '../screens/service/service_management_screen.dart';
import '../screens/counter/counter_management_screen.dart';
import '../screens/counter/service_assignment_screen.dart';
import '../screens/counter/counter_dashboard_screen.dart';
import '../screens/queue/queue_management_screen.dart';
import '../screens/queue/queue_monitor_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/admin/admin_management_screen.dart';
import '../screens/dashboard/admin_tokens_screen.dart';

class AdminRouter {
  static GoRouter router(BuildContext context) {
    final auth = context.read<AdminAuthProvider>();
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final status = auth.status;
        final isAuth = status == AdminAuthStatus.authenticated;
        final isLoading = status == AdminAuthStatus.loading;
        final loc = state.matchedLocation;

        if (isLoading) return null;

        // Not authenticated → login
        if (!isAuth && !loc.startsWith('/login')) {
          return '/login';
        }

        // Authenticated → role-based redirect
        if (isAuth && loc == '/login') {
          if (auth.isCounterAdmin) return '/counter';
          return '/dashboard';
        }

        // Counter admin trying to access /dashboard → bounce to /counter
        if (isAuth && auth.isCounterAdmin && loc.startsWith('/dashboard')) {
          return '/counter';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const AdminLoginScreen(),
        ),
        // ── Counter Admin Route ───────────────────────────────────────────
        GoRoute(
          path: '/counter',
          builder: (_, __) => const CounterDashboardScreen(),
        ),
        // ── Super Admin Routes ────────────────────────────────────────────
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const AdminDashboardScreen(),
          routes: [
            GoRoute(
              path: 'sectors',
              builder: (_, __) => const SectorManagementScreen(),
            ),
            GoRoute(
              path: 'branches',
              builder: (_, __) => const BranchManagementScreen(),
              routes: [
                GoRoute(
                  path: ':sectorId',
                  builder: (context, state) => BranchManagementScreen(
                    sectorId: state.pathParameters['sectorId'],
                    sectorName: state.uri.queryParameters['sectorName'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'services',
              builder: (context, state) => const ServiceManagementScreen(),
              routes: [
                GoRoute(
                  path: ':sectorId',
                  builder: (context, state) => ServiceManagementScreen(
                    sectorId: state.pathParameters['sectorId'],
                    sectorName: state.uri.queryParameters['sectorName'],
                  ),
                  routes: [
                    GoRoute(
                      path: ':branchId',
                      builder: (context, state) => ServiceManagementScreen(
                        sectorId: state.pathParameters['sectorId'],
                        sectorName: state.uri.queryParameters['sectorName'],
                        branchId: state.pathParameters['branchId'],
                        branchName: state.uri.queryParameters['branchName'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: 'counters',
              builder: (context, state) => const CounterManagementScreen(),
              routes: [
                GoRoute(
                  path: ':sectorId',
                  builder: (context, state) => CounterManagementScreen(
                    sectorId: state.pathParameters['sectorId'],
                    sectorName: state.uri.queryParameters['sectorName'],
                  ),
                  routes: [
                    GoRoute(
                      path: ':branchId',
                      builder: (context, state) => CounterManagementScreen(
                        sectorId: state.pathParameters['sectorId'],
                        sectorName: state.uri.queryParameters['sectorName'],
                        branchId: state.pathParameters['branchId'],
                        branchName: state.uri.queryParameters['branchName'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: 'assign/:counterId',
              builder: (context, state) => ServiceAssignmentScreen(
                counterId: state.pathParameters['counterId']!,
                branchId: state.uri.queryParameters['branchId'] ?? '',
                counterName: state.uri.queryParameters['name'] ?? '',
              ),
            ),
            GoRoute(
              path: 'queue/:counterId',
              builder: (context, state) => QueueManagementScreen(
                counterId: state.pathParameters['counterId']!,
                counterName: state.uri.queryParameters['name'] ?? '',
              ),
            ),
            GoRoute(
              path: 'monitor',
              builder: (_, __) => const QueueMonitorScreen(),
            ),
            GoRoute(
              path: 'analytics',
              builder: (_, __) => const AnalyticsScreen(),
            ),
            GoRoute(
              path: 'tokens',
              builder: (context, state) => AdminTokensScreen(
                filter: state.uri.queryParameters['filter'] ?? '',
              ),
            ),
            GoRoute(
              path: 'admins',
              builder: (_, __) => const AdminManagementScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
