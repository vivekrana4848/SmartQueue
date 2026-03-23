import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../models/token_model.dart';
import '../../app/app_theme.dart';
import '../../widgets/modern_card.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final queue = context.read<QueueProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Queue History')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.black12),
              const SizedBox(height: 16),
              const Text('Please log in to view history'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.background,
      appBar: AppBar(title: const Text('Queue History')),
      body: StreamBuilder<List<TokenModel>>(
        stream: queue.streamUserHistory(auth.user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.history_rounded, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No history found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          final tokens = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
            physics: const BouncingScrollPhysics(),
            itemCount: tokens.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final token = tokens[index];
              return _HistoryItem(token: token);
            },
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final TokenModel token;
  const _HistoryItem({required this.token});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(token.status);

    return ModernCard(
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(Icons.confirmation_num_outlined, color: AppTheme.primary, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token.serviceName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${token.branchName} • ${DateFormat('dd MMM').format(token.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Text(
              token.status.name.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TokenStatus status) {
    switch (status) {
      case TokenStatus.completed: return AppTheme.success;
      case TokenStatus.skipped: return Colors.orange;
      case TokenStatus.recalled: return Colors.blue;
      case TokenStatus.cancelled: return AppTheme.danger;
      default: return const Color(0xFF64748B);
    }
  }
}
