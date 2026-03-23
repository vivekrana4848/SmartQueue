import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../providers/token_provider.dart';
import '../../models/sector_model.dart';
import '../../models/token_model.dart';
import '../../app/app_theme.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/token_display_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final queue = context.read<QueueProvider>();
    final tokenProvider = context.watch<TokenProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, auth),
          _buildActiveTokens(context, auth, tokenProvider),
          _buildSectionTitle(context, 'Industries'),
          _buildSectorsGrid(queue),
          const SliverToBoxAdapter(child: SizedBox(height: 120)), // Space for floating nav
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    String greetingName = 'Guest';
    if (auth.userProfile != null && auth.userProfile!.name.isNotEmpty) {
      greetingName = auth.userProfile!.name.trim().split(' ').first;
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 64, left: 24, right: 24, bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $greetingName!',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Start your queue experience',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }

  Widget _buildActiveTokens(BuildContext context, AuthProvider auth, TokenProvider tokenProvider) {
    if (auth.user == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return StreamBuilder<List<TokenModel>>(
      stream: tokenProvider.streamUserTokens(auth.user!.uid),
      builder: (context, snapshot) {
        final activeTokens = snapshot.data?.where((t) => t.status == TokenStatus.waiting || t.status == TokenStatus.serving).toList() ?? [];
        if (activeTokens.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text('Active Tokens', style: Theme.of(context).textTheme.titleLarge),
              ),
              SizedBox(
                height: 260,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: activeTokens.length,
                  itemBuilder: (context, index) {
                    final token = activeTokens[index];
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () => context.push('/live-queue/${token.id}'),
                        child: TokenDisplayCard(
                          tokenNumber: token.tokenNumber,
                          status: token.status.name,
                          peopleAhead: token.position - 1,
                          estWaitMinutes: (token.position - 1) * 5,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectorsGrid(QueueProvider queue) {
    return StreamBuilder<List<SectorModel>>(
      stream: queue.streamSectors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(child: Center(child: Text('No sectors available')));
        }

        final sectors = snapshot.data!;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _SectorCard(sector: sectors[index]),
              childCount: sectors.length,
            ),
          ),
        );
      },
    );
  }
}

class _SectorCard extends StatelessWidget {
  final SectorModel sector;
  const _SectorCard({required this.sector});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(sector.color.replaceAll('#', '0xFF')));

    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      onTap: () {
        context.read<QueueProvider>().selectSector(sector);
        context.push('/branches/${sector.id}?name=${Uri.encodeComponent(sector.name)}');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sector.icon,
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sector.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Explore',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
