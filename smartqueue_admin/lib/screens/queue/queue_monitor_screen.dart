import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/admin_theme.dart';
import '../../models/counter_model.dart';
import '../../models/queue_model.dart';
import '../../providers/admin_providers.dart';
import '../../services/admin_firestore_service.dart';
import '../../widgets/admin_scaffold.dart';

/// QueueMonitorScreen — Live view of ALL counters across the system.
/// Super admin only.
class QueueMonitorScreen extends StatelessWidget {
  const QueueMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final counterProv = context.read<CounterAdminProvider>();
    return AdminScaffold(
      title: 'Live Queue Monitor',
      currentRoute: '/dashboard/monitor',
      body: StreamBuilder<List<CounterModel>>(
        stream: counterProv.streamAll(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final counters = snap.data ?? [];
          if (counters.isEmpty) {
            return const _EmptyState();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary bar
              Container(
                margin: const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AdminTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _SummaryItem(
                        label: 'Total Counters',
                        value: '${counters.length}'),
                    const _Divider(),
                    _SummaryItem(
                        label: 'Active',
                        value: '${counters.where((c) => c.isActive).length}'),
                    const _Divider(),
                    _SummaryItem(
                        label: 'Offline',
                        value:
                            '${counters.where((c) => !c.isActive).length}'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    const Text('All Counters',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.primary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AdminTheme.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle,
                              size: 6, color: AdminTheme.success),
                          SizedBox(width: 4),
                          Text('LIVE',
                              style: TextStyle(
                                  color: AdminTheme.success,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width >= 900 ? 3 : 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio:
                        MediaQuery.of(context).size.width >= 900 ? 1.7 : 2.5,
                  ),
                  itemCount: counters.length,
                  itemBuilder: (ctx, i) =>
                      _CounterMonitorCard(counter: counters[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 32, color: Colors.white.withAlpha(30));
  }
}

class _CounterMonitorCard extends StatelessWidget {
  final CounterModel counter;

  const _CounterMonitorCard({required this.counter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueueModel?>(
      stream: AdminFirestoreService().streamQueue(counter.id),
      builder: (context, snap) {
        final queue = snap.data;
        final waiting = queue?.waitList.length ?? 0;
        final serving = queue?.currentToken;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.go(
                '/dashboard/queue/${counter.id}?name=${Uri.encodeComponent(counter.name)}',
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: counter.isActive
                      ? AdminTheme.accent.withAlpha(40)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: counter.isActive
                              ? AdminTheme.accentGradient
                              : const LinearGradient(
                                  colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.storefront_outlined,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(counter.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AdminTheme.primary),
                                overflow: TextOverflow.ellipsis),
                            _StatusPill(isActive: counter.isActive),
                          ],
                        ),
                      ),
                      // Queue count chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: waiting > 0
                              ? AdminTheme.warning.withAlpha(25)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$waiting',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: waiting > 0
                                    ? AdminTheme.warning
                                    : const Color(0xFF94A3B8))),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Serving info
                  Row(
                    children: [
                      const Icon(Icons.radio_button_checked_rounded,
                          size: 10,
                          color: AdminTheme.success),
                      const SizedBox(width: 5),
                      Text(
                          serving != null
                              ? 'Serving #${serving.substring(0, 6).toUpperCase()}'
                              : 'No token serving',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: serving != null
                                  ? AdminTheme.success
                                  : const Color(0xFF94A3B8))),
                      const Spacer(),
                      const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: isActive ? AdminTheme.success : const Color(0xFF94A3B8),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(isActive ? 'Online' : 'Offline',
            style: TextStyle(
                fontSize: 10,
                color: isActive ? AdminTheme.success : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart_outlined,
              size: 64, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text('No Counters Found',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.primary)),
          SizedBox(height: 6),
          Text('Create counters via Branch → Counters.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        ],
      ),
    );
  }
}
