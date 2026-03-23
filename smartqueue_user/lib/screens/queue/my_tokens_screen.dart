import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../models/token_model.dart';
import '../../app/app_theme.dart';
import '../../widgets/modern_card.dart';

class MyTokensScreen extends StatelessWidget {
  const MyTokensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final queue = context.read<QueueProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Tokens')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_rounded, size: 64, color: Colors.black12),
              const SizedBox(height: 16),
              const Text('Please log in to view your tokens'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.background,
      appBar: AppBar(title: const Text('My Tokens')),
      body: StreamBuilder<List<TokenModel>>(
        stream: queue.streamUserActiveTokens(auth.user!.uid),
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
                    child: Icon(Icons.confirmation_num_outlined, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No active tokens',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate a token to start queuing',
                    style: Theme.of(context).textTheme.bodyMedium,
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
              return _ActiveTokenCard(token: token);
            },
          );
        },
      ),
    );
  }
}

class _ActiveTokenCard extends StatelessWidget {
  final TokenModel token;
  const _ActiveTokenCard({required this.token});

  @override
  Widget build(BuildContext context) {
    final isServing = token.status == TokenStatus.serving;

    return ModernCard(
      onTap: () => context.push('/live-queue/${token.id}'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: isServing ? AppTheme.secondaryGradient : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isServing ? AppTheme.success : AppTheme.primary).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              token.tokenNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
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
                ),
                Text(
                  token.branchName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          _buildStatusBadge(token.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TokenStatus status) {
    final isServing = status == TokenStatus.serving;
    final color = isServing ? AppTheme.success : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
