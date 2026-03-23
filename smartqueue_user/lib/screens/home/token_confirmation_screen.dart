import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../models/token_model.dart';
import '../../app/app_theme.dart';
import '../../widgets/token_display_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/modern_card.dart';

class TokenConfirmationScreen extends StatefulWidget {
  final String? tokenId;
  final String? sectorId;
  final String? branchId;
  final String? serviceId;

  const TokenConfirmationScreen({
    super.key,
    this.tokenId,
    this.sectorId,
    this.branchId,
    this.serviceId,
  });

  @override
  State<TokenConfirmationScreen> createState() => _TokenConfirmationScreenState();
}

class _TokenConfirmationScreenState extends State<TokenConfirmationScreen> {
  bool _isSuccess = false;
  String? _generatedTokenId;

  @override
  void initState() {
    super.initState();
    if (widget.tokenId != null) {
      _isSuccess = true;
      _generatedTokenId = widget.tokenId;
    } else {
      // Load selection models from IDs if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<QueueProvider>().loadSelectionFromIds(
              sectorId: widget.sectorId,
              branchId: widget.branchId,
              serviceId: widget.serviceId,
            );
      });
    }
  }

  Future<void> _handleGenerateToken() async {
    final auth = context.read<AuthProvider>();
    final queue = context.read<QueueProvider>();

    if (auth.user == null) return;

    final tokenId = await queue.generateToken(auth.user!.uid);
    if (tokenId != null && mounted) {
      setState(() {
        _isSuccess = true;
        _generatedTokenId = tokenId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.background,
      appBar: AppBar(
        title: Text(_isSuccess ? 'Token Generated' : 'Confirm Selection'),
        leading: _isSuccess 
          ? IconButton(icon: const Icon(Icons.close), onPressed: () => context.go('/'))
          : null,
      ),
      body: _isSuccess ? _buildSuccessView() : _buildConfirmView(),
    );
  }

  Widget _buildConfirmView() {
    final queue = context.watch<QueueProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sector = queue.selectedSector;
    final branch = queue.selectedBranch;
    final service = queue.selectedService;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(3, 3),
          const SizedBox(height: 32),
          Text(
            'Review Your Selection',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Check your service and location details before confirming.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          ModernCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSummaryItem(
                  context,
                  'Industry',
                  sector?.name ?? 'Not selected',
                  _getIcon(sector?.icon ?? ''),
                  Colors.indigo,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                _buildSummaryItem(
                  context,
                  'Location',
                  branch?.name ?? 'Not selected',
                  Icons.location_on_rounded,
                  Colors.redAccent,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                _buildSummaryItem(
                  context,
                  'Service',
                  service?.name ?? 'Not selected',
                  Icons.settings_suggest_rounded,
                  AppTheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Guest Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.userProfile?.name ?? 'Guest User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        auth.userProfile?.email ?? auth.user?.email ?? '',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          if (queue.generationError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                queue.generationError!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          GradientButton(
            label: 'Generate My Token',
            isLoading: queue.isGenerating,
            onPressed: (branch == null || service == null) ? null : _handleGenerateToken,
            icon: Icons.qr_code_rounded,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final queue = context.read<QueueProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<TokenModel?>(
      stream: queue.streamToken(_generatedTokenId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Token not found'));
        }

        final token = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAnimatedCheck(),
              const SizedBox(height: 32),
              Text(
                'Spot Reserved!',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your token has been added to the queue.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TokenDisplayCard(
                tokenNumber: token.tokenNumber,
                status: token.status.name,
                peopleAhead: token.position - 1,
                estWaitMinutes: (token.position - 1) * 5,
              ),
              const SizedBox(height: 48),
              GradientButton(
                label: 'Track Live Progress',
                onPressed: () => context.go('/live-queue/${token.id}'),
                icon: Icons.track_changes_rounded,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(
                  'Back to Dashboard',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int current, int total) {
    return Row(
      children: List.generate(total, (index) {
        final isActive = index < current;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primary : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAnimatedCheck() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        size: 80,
        color: AppTheme.success,
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 80, height: 80, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(height: 32),
            Container(width: 200, height: 24, color: Colors.white),
            const SizedBox(height: 48),
            Container(width: double.infinity, height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'account_balance': return Icons.account_balance_rounded;
      case 'local_hospital': return Icons.local_hospital_rounded;
      case 'gavel': return Icons.gavel_rounded;
      case 'spa': return Icons.spa_rounded;
      case 'temple_hindu': return Icons.temple_hindu_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'school': return Icons.school_rounded;
      case 'confirmation_number': return Icons.confirmation_number_rounded;
      default: return Icons.category_rounded;
    }
  }
}
