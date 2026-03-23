import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app/admin_theme.dart';
import '../../models/queue_model.dart';
import '../../models/token_model.dart';
import '../../providers/admin_providers.dart';
import '../../services/admin_firestore_service.dart';
import '../../widgets/admin_scaffold.dart';

class QueueManagementScreen extends StatelessWidget {
  final String counterId;
  final String counterName;
  const QueueManagementScreen(
      {super.key, required this.counterId, required this.counterName});

  @override
  Widget build(BuildContext context) {
    final queueProv = context.read<QueueAdminProvider>();
    return AdminScaffold(
      title: 'Queue – $counterName',
      currentRoute: '/dashboard/branches',
      body: StreamBuilder<QueueModel?>(
        stream: queueProv.streamQueue(counterId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final queue = snap.data;
          final waitCount = queue?.waitList.length ?? 0;

          return Column(
            children: [
              // Current serving card
              _CurrentServingCard(
                queue: queue,
                onNext: () => queueProv.next(counterId),
                onRecall: () => queueProv.recall(counterId),
                onSkip: () => queueProv.skip(counterId),
                onComplete: () => queueProv.complete(counterId),
              ),
              // Wait list header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Queue ($waitCount waiting)',
                        style: Theme.of(context).textTheme.titleMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AdminTheme.accent.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('LIVE',
                          style: const TextStyle(
                              color: AdminTheme.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 11)),
                    ),
                  ],
                ),
              ),
              // Queue list
              Expanded(
                child: queue == null || queue.waitList.isEmpty
                    ? const Center(
                        child: Text('Queue is empty',
                            style: TextStyle(color: Color(0xFF64748B))))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: queue.waitList.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) => _QueueItem(
                          tokenId: queue.waitList[i],
                          position: i + 1,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CurrentServingCard extends StatelessWidget {
  final QueueModel? queue;
  final VoidCallback onNext;
  final VoidCallback onRecall;
  final VoidCallback onSkip;
  final VoidCallback onComplete;
  const _CurrentServingCard(
      {this.queue,
      required this.onNext,
      required this.onRecall,
      required this.onSkip,
      required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AdminTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NOW SERVING',
              style: TextStyle(
                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(
            queue?.currentToken != null
                ? '# ${queue!.currentToken!.substring(0, 6).toUpperCase()}'
                : '— —',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 3),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ControlBtn(
                label: 'Next',
                icon: Icons.skip_next,
                color: AdminTheme.success,
                onTap: onNext,
              ),
              const SizedBox(width: 8),
              _ControlBtn(
                label: 'Recall',
                icon: Icons.replay,
                color: AdminTheme.warning,
                onTap: onRecall,
              ),
              const SizedBox(width: 8),
              _ControlBtn(
                label: 'Skip',
                icon: Icons.skip_next_outlined,
                color: const Color(0xFF64748B),
                onTap: onSkip,
              ),
              const SizedBox(width: 8),
              _ControlBtn(
                label: 'Done',
                icon: Icons.check_circle_outline,
                color: AdminTheme.accent,
                onTap: onComplete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ControlBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  final String tokenId;
  final int position;
  const _QueueItem({required this.tokenId, required this.position});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TokenModel?>(
      stream: AdminFirestoreService().streamToken(tokenId),
      builder: (context, snap) {
        final token = snap.data;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AdminTheme.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('$position',
                      style: const TextStyle(
                          color: AdminTheme.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(token?.tokenNumber ?? tokenId.substring(0, 6),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    if (token != null)
                      Text('${token.userName ?? 'User'} · ${token.serviceName}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (token != null)
                Text(
                  DateFormat('hh:mm a').format(token.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B)),
                ),
            ],
          ),
        );
      },
    );
  }
}
