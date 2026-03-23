import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../app/admin_theme.dart';
import '../providers/admin_providers.dart';

class AdminScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final String currentRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AdminScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    if (isWide) {
      return _WideLayout(
        body: body,
        title: title,
        currentRoute: currentRoute,
        actions: actions,
        floatingActionButton: floatingActionButton,
      );
    } else {
      return _NarrowLayout(
        body: body,
        title: title,
        currentRoute: currentRoute,
        actions: actions,
        floatingActionButton: floatingActionButton,
      );
    }
  }
}

// ── Wide (Sidebar) Layout ──────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final String currentRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const _WideLayout({
    required this.body,
    required this.title,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgLight,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          _Sidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: title, actions: actions),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Narrow (Drawer) Layout ─────────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final String currentRoute;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const _NarrowLayout({
    required this.body,
    required this.title,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.bgLight,
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AdminTheme.primary)),
        actions: actions,
        iconTheme: const IconThemeData(color: AdminTheme.primary),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      drawer: Drawer(
        backgroundColor: AdminTheme.primary,
        child: _SidebarContent(currentRoute: currentRoute),
      ),
      body: body,
    );
  }
}

// ── Top Bar for Wide Layout ────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const _TopBar({required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.primary)),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final String currentRoute;

  const _Sidebar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: AdminTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
              color: Color(0x22000000), blurRadius: 20, offset: Offset(4, 0)),
        ],
      ),
      child: _SidebarContent(currentRoute: currentRoute),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final String currentRoute;

  const _SidebarContent({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AdminAuthProvider>();
    final isSuperAdmin = auth.isSuperAdmin;

    return Column(
      children: [
        // Logo area
        const SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                _LogoIcon(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SmartQueue',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      Text('Admin Console',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(color: Colors.white12, height: 1),
        ),
        const SizedBox(height: 12),

        // Nav items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              _NavItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                route: '/dashboard',
                currentRoute: currentRoute,
              ),
              if (isSuperAdmin) ...[
                _NavItem(
                  icon: Icons.business_outlined,
                  label: 'Sectors',
                  route: '/dashboard/sectors',
                  currentRoute: currentRoute,
                ),
                _NavItem(
                  icon: Icons.location_on_outlined,
                  label: 'Branches',
                  route: '/dashboard/branches',
                  currentRoute: currentRoute,
                ),
                _NavItem(
                  icon: Icons.design_services_outlined,
                  label: 'Services',
                  route: '/dashboard/services',
                  currentRoute: currentRoute,
                ),
                _NavItem(
                  icon: Icons.storefront_outlined,
                  label: 'Counters',
                  route: '/dashboard/counters',
                  currentRoute: currentRoute,
                ),
                _NavItem(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Queue Monitor',
                  route: '/dashboard/monitor',
                  currentRoute: currentRoute,
                ),
                _NavItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Analytics',
                  route: '/dashboard/analytics',
                  currentRoute: currentRoute,
                ),
                _NavItem(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Admins',
                  route: '/dashboard/admins',
                  currentRoute: currentRoute,
                ),
              ],
            ],
          ),
        ),

        // User info + logout
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(color: Colors.white12, height: 1),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_outline,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(auth.adminModel?.name ?? 'Admin',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                          Text(
                              isSuperAdmin ? 'Super Admin' : 'Counter Admin',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.white.withAlpha(15),
                    ),
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Logout',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    onPressed: () async {
                      await auth.signOut();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoIcon extends StatelessWidget {
  const _LogoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final List<String>? matchPrefixes;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    this.matchPrefixes,
  });

  bool get isActive {
    if (currentRoute == route) return true;
    // Special case for dashboard to avoid matching everything
    if (route == '/dashboard' && currentRoute != '/dashboard') return false;
    return currentRoute.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withAlpha(25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? AdminTheme.accent.withAlpha(80)
                : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: isActive ? Colors.white : Colors.white60, size: 17),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        trailing: isActive
            ? Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AdminTheme.accentLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        onTap: () {
          if (Scaffold.of(context).hasDrawer) {
            Navigator.of(context).pop(); // close drawer
          }
          context.go(route);
        },
      ),
    );
  }
}
