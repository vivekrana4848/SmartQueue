import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../app/app_theme.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/gradient_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(context, auth),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ModernCard(
                    child: Column(
                      children: [
                        _buildInfoRow(context, Icons.person_outline_rounded, 'Full Name', auth.userProfile?.name ?? 'Guest'),
                        const Divider(height: 1, thickness: 1, color: Colors.black12),
                        _buildInfoRow(context, Icons.email_outlined, 'Email', auth.userProfile?.email ?? 'N/A'),
                        const Divider(height: 1, thickness: 1, color: Colors.black12),
                        _buildInfoRow(context, Icons.phone_outlined, 'Phone', auth.userProfile?.phone ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Application Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ModernCard(
                    child: Column(
                      children: [
                        _buildSwitchRow(
                          context,
                          Icons.notifications_active_outlined,
                          'Push Notifications',
                          true,
                          (v) {},
                        ),
                        const Divider(height: 1, thickness: 1, color: Colors.black12),
                        Consumer<ThemeProvider>(
                          builder: (context, theme, _) => _buildSwitchRow(
                            context,
                            Icons.dark_mode_outlined,
                            'Dark Appearance',
                            theme.themeMode == ThemeMode.dark,
                            (v) => theme.toggleTheme(v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  GradientButton(
                    label: 'Sign Out',
                    onPressed: () async {
                      await auth.signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: Icons.logout_rounded,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'App Version 2.0.0',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    final profile = auth.userProfile;
    final initials = (profile?.name.isNotEmpty == true) 
        ? profile!.name.trim().substring(0, 1).toUpperCase() 
        : 'G';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: (profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty)
                  ? NetworkImage(profile.photoUrl!)
                  : null,
              child: (profile?.photoUrl == null || profile!.photoUrl!.isEmpty)
                  ? Text(
                      initials,
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.primary),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            profile?.name ?? 'Guest User',
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            profile?.email ?? 'Sync your profile',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(BuildContext context, IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
