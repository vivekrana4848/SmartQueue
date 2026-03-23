import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/admin_theme.dart';
import '../../models/analytics_model.dart';
import '../../models/token_model.dart';
import '../../providers/admin_providers.dart';
import '../../services/admin_firestore_service.dart';
import '../../widgets/admin_scaffold.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthProvider>();
    final userName = auth.adminModel?.name ?? auth.user?.email ?? 'Admin';
    final isSuperAdmin = auth.isSuperAdmin;

    return AdminScaffold(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AdminTheme.accentGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      isSuperAdmin ? 'Super Admin' : 'Counter Admin',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome banner
              _WelcomeBanner(name: userName),
              const SizedBox(height: 24),

              // Analytics Stat Cards
              Text("Today's Overview",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              StreamBuilder<AnalyticsModel?>(
                stream: context.read<AnalyticsProvider>().todayStream,
                builder: (context, snap) {
                  final a = snap.data;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount:
                        MediaQuery.of(context).size.width >= 900 ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: MediaQuery.of(context).size.width < 400 ? 1.2 : 1.4,
                    children: [
                      _StatCard(
                        label: "Today's Tokens",
                        value: '${a?.totalTokens ?? 0}',
                        icon: Icons.confirmation_number_outlined,
                        gradient: AdminTheme.accentGradient,
                        onTap: () => context.go('/dashboard/tokens?filter=today'),
                      ),
                      _StatCard(
                        label: 'Completed',
                        value: '${a?.completedTokens ?? 0}',
                        icon: Icons.check_circle_outline,
                        gradient: AdminTheme.successGradient,
                        onTap: () => context.go('/dashboard/tokens?filter=completed'),
                      ),
                      _StatCard(
                        label: 'Pending',
                        value: '${a?.pendingTokens ?? 0}',
                        icon: Icons.hourglass_empty_outlined,
                        gradient: AdminTheme.warningGradient,
                        onTap: () => context.go('/dashboard/tokens?filter=pending'),
                      ),
                      _StatCard(
                        label: 'Avg Wait',
                        value: '${a?.avgWaitMinutes ?? 0} min',
                        icon: Icons.timer_outlined,
                        gradient: AdminTheme.dangerGradient,
                        onTap: () => context.go('/dashboard/analytics'),
                      ),
                    ],
                  );
                },
              ),

              // System stats (super admin only)
              if (isSuperAdmin) ...[
                const SizedBox(height: 24),
                Text('System Overview',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                const _SystemStatsRow(),
              ],

              // Quick Actions
              const SizedBox(height: 24),
              Text('Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _QuickActionsGrid(isSuperAdmin: isSuperAdmin),

              // Recent tokens
              const SizedBox(height: 24),
              Text("Recent Tokens",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              const _RecentTokensList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Welcome Banner ─────────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  final String name;
  const _WelcomeBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String greeting;
    if (now.hour < 12) {
      greeting = 'Good Morning ☀️';
    } else if (now.hour < 17) {
      greeting = 'Good Afternoon 👋';
    } else {
      greeting = 'Good Evening 🌙';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: AdminTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('SmartQueue Admin Console',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withAlpha(60),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// icon
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),

              const SizedBox(height: 8),

              /// value
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 1),

              /// label
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withAlpha(220),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ── System Stats ────────────────────────────────────────────────────────────
class _SystemStatsRow extends StatelessWidget {
  const _SystemStatsRow();

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardStatsProvider>(
      builder: (context, stats, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SystemStatCard(
                  label: 'Sectors',
                  value: '${stats.sectorsCount}',
                  icon: Icons.business_outlined,
                  color: AdminTheme.accent,
                  onTap: () => context.go('/dashboard/sectors')),
              const SizedBox(width: 10),
              _SystemStatCard(
                  label: 'Branches',
                  value: '${stats.branchesCount}',
                  icon: Icons.location_on_outlined,
                  color: AdminTheme.success,
                  onTap: () => context.go('/dashboard/branches')),
              const SizedBox(width: 10),
              _SystemStatCard(
                  label: 'Counters',
                  value: '${stats.countersCount}',
                  icon: Icons.storefront_outlined,
                  color: AdminTheme.warning,
                  onTap: () => context.go('/dashboard/counters')),
            ],
          ),
        );
      },
    );
  }
}

class _SystemStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SystemStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(value,
                          style: TextStyle(
                              color: color,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quick Actions ────────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final bool isSuperAdmin;
  const _QuickActionsGrid({required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    final items = isSuperAdmin
        ? [
            _QAItem('Sectors', Icons.business_outlined, AdminTheme.accentGradient,
                () => context.go('/dashboard/sectors')),
            _QAItem('Services', Icons.design_services_outlined, AdminTheme.successGradient,
                () => context.go('/dashboard/services')),
            _QAItem('Counters', Icons.storefront_outlined, AdminTheme.warningGradient,
                () => context.go('/dashboard/counters')),
            _QAItem('Queue Monitor', Icons.monitor_heart_outlined, AdminTheme.primaryGradient,
                () => context.go('/dashboard/monitor')),
            _QAItem('Analytics', Icons.bar_chart_outlined, AdminTheme.accentGradient,
                () => context.go('/dashboard/analytics')),
            _QAItem('Admins', Icons.manage_accounts_outlined, AdminTheme.dangerGradient,
                () => context.go('/dashboard/admins')),
          ]
        : [
            _QAItem('My Queue', Icons.queue_outlined, AdminTheme.accentGradient,
                () => context.go('/counter')),
          ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            MediaQuery.of(context).size.width >= 900 ? 5 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _QACard(item: items[i]),
    );
  }
}

class _QAItem {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  _QAItem(this.label, this.icon, this.gradient, this.onTap);
}

class _QACard extends StatelessWidget {
  final _QAItem item;
  const _QACard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: item.gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: Colors.white, size: 20),
            ),
            Text(item.label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AdminTheme.primary)),
          ],
        ),
      ),
    );
  }
}

// ── Recent Tokens ────────────────────────────────────────────────────────────
class _RecentTokensList extends StatelessWidget {
  const _RecentTokensList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TokenModel>>(
      stream: AdminFirestoreService().streamTodayTokens(),
      builder: (context, snap) {
        final tokens = (snap.data ?? []).take(5).toList();
        if (tokens.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('No tokens today yet',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          );
        }
        return Column(
          children: tokens
              .map((t) => _TokenRow(token: t))
              .toList(),
        );
      },
    );
  }
}

class _TokenRow extends StatelessWidget {
  final TokenModel token;
  const _TokenRow({required this.token});

  Color get _statusColor {
    switch (token.status) {
      case TokenStatus.serving:
        return AdminTheme.accent;
      case TokenStatus.completed:
        return AdminTheme.success;
      case TokenStatus.skipped:
        return const Color(0xFF94A3B8);
      case TokenStatus.recalled:
        return AdminTheme.warning;
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${token.tokenNumber} · ${token.serviceName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                    '${token.counterName} · ${token.branchName}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(token.statusLabel,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor)),
          ),
        ],
      ),
    );
  }
}
