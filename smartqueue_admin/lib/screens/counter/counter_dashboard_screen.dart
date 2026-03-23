import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app/admin_theme.dart';
import '../../models/queue_model.dart';
import '../../models/token_model.dart';
import '../../providers/admin_providers.dart';
import '../../services/admin_firestore_service.dart';
import '../../widgets/admin_scaffold.dart';

/// CounterDashboardScreen — for counterAdmin role only.
/// Displays the assigned counter's live queue with NEXT/SKIP/RECALL/COMPLETE.
class CounterDashboardScreen extends StatelessWidget {
  const CounterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthProvider>();
    final counterId = auth.counterId;
    final counterName = auth.counterName ?? 'Counter';
    final adminName = auth.adminModel?.name ?? 'Staff';

    if (counterId == null) {
      return AdminScaffold(
        title: 'Counter Dashboard',
        currentRoute: '/counter',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_outlined,
                  size: 64, color: AdminTheme.warning),
              const SizedBox(height: 16),
              const Text('No Counter Assigned',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.primary)),
              const SizedBox(height: 8),
              Text('Please contact your Super Admin.',
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    final queueProv = context.read<QueueAdminProvider>();

    return AdminScaffold(
      title: counterName,
      currentRoute: '/counter',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AdminTheme.success.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AdminTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(adminName,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminTheme.success)),
              ],
            ),
          ),
        ),
      ],
      body: StreamBuilder<QueueModel?>(
        stream: queueProv.streamQueue(counterId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final queue = snap.data;
          return Column(
            children: [
              // NOW SERVING card
              _NowServingCard(
                queue: queue,
                queueProv: queueProv,
                counterId: counterId,
              ),
              // Queue list
              _QueueListSection(queue: queue),
            ],
          );
        },
      ),
    );
  }
}

// ── Now Serving Card ──────────────────────────────────────────────────────
class _NowServingCard extends StatefulWidget {
  final QueueModel? queue;
  final QueueAdminProvider queueProv;
  final String counterId;

  const _NowServingCard({
    required this.queue,
    required this.queueProv,
    required this.counterId,
  });

  @override
  State<_NowServingCard> createState() => _NowServingCardState();
}

class _NowServingCardState extends State<_NowServingCard> {
  bool _busy = false;

  Future<void> _action(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenId = widget.queue?.currentToken;
    final waitCount = widget.queue?.waitList.length ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF2D3E52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1E293B).withAlpha(60),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NOW SERVING',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    if (tokenId != null)
                      StreamBuilder<TokenModel?>(
                        stream: AdminFirestoreService().streamToken(tokenId),
                        builder: (context, snap) {
                          final token = snap.data;
                          return _TokenDisplay(token: token, tokenId: tokenId);
                        },
                      )
                    else
                      const _EmptyTokenDisplay(),
                  ],
                ),
                const Spacer(),
                // Queue depth badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('$waitCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                      const Text('Waiting',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _busy
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Colors.white),
                  ))
                : Row(
                    children: [
                      _BigBtn(
                        label: 'NEXT',
                        icon: Icons.skip_next_rounded,
                        color: const Color(0xFF10B981),
                        onTap: () => _action(
                            () => widget.queueProv.next(widget.counterId)),
                      ),
                      const SizedBox(width: 8),
                      _BigBtn(
                        label: 'RECALL',
                        icon: Icons.replay_rounded,
                        color: const Color(0xFFF59E0B),
                        onTap: () => _action(
                            () => widget.queueProv.recall(widget.counterId)),
                      ),
                      const SizedBox(width: 8),
                      _BigBtn(
                        label: 'SKIP',
                        icon: Icons.fast_forward_rounded,
                        color: const Color(0xFF64748B),
                        onTap: () => _action(
                            () => widget.queueProv.skip(widget.counterId)),
                      ),
                      const SizedBox(width: 8),
                      _BigBtn(
                        label: 'DONE',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF6C63FF),
                        onTap: () => _action(
                            () => widget.queueProv.complete(widget.counterId)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TokenDisplay extends StatelessWidget {
  final TokenModel? token;
  final String tokenId;
  const _TokenDisplay({required this.token, required this.tokenId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          token?.tokenNumber ?? '#${tokenId.substring(0, 6).toUpperCase()}',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: 2),
        ),
        if (token != null) ...[
          Text(token!.userName ?? 'Customer',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          Text(token!.serviceName,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ],
    );
  }
}

class _EmptyTokenDisplay extends StatelessWidget {
  const _EmptyTokenDisplay();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('— — —',
            style: TextStyle(
                color: Colors.white38,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 4)),
        Text('No token serving',
            style: TextStyle(color: Colors.white30, fontSize: 13)),
      ],
    );
  }
}

class _BigBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BigBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Queue List Section ─────────────────────────────────────────────────────
class _QueueListSection extends StatelessWidget {
  final QueueModel? queue;

  const _QueueListSection({required this.queue});

  @override
  Widget build(BuildContext context) {
    final waitList = queue?.waitList ?? [];

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Text('Queue (${waitList.length} waiting)',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AdminTheme.primary)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AdminTheme.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: AdminTheme.accent),
                      SizedBox(width: 4),
                      Text('LIVE',
                          style: TextStyle(
                              color: AdminTheme.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: waitList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.done_all_rounded,
                            size: 48, color: AdminTheme.success),
                        const SizedBox(height: 12),
                        const Text('Queue is empty!',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AdminTheme.primary)),
                        const SizedBox(height: 4),
                        Text('All caught up.',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: waitList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _QueueCard(
                      tokenId: waitList[i],
                      position: i + 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final String tokenId;
  final int position;

  const _QueueCard({required this.tokenId, required this.position});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TokenModel?>(
      stream: AdminFirestoreService().streamToken(tokenId),
      builder: (context, snap) {
        final token = snap.data;
        return Container(
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: position == 1
                      ? AdminTheme.accentGradient
                      : const LinearGradient(colors: [
                          Color(0xFFF1F5F9),
                          Color(0xFFE2E8F0)
                        ]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('$position',
                      style: TextStyle(
                          color: position == 1
                              ? Colors.white
                              : AdminTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        token?.tokenNumber ??
                            '#${tokenId.substring(0, 6).toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    if (token != null)
                      Text(
                          '${token.userName ?? 'Customer'} · ${token.serviceName}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (token != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(DateFormat('hh:mm a').format(token.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Waiting',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B))),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
