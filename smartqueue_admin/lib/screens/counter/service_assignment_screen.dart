import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/admin_theme.dart';
import '../../models/branch_model.dart';
import '../../models/service_model.dart';
import '../../models/counter_model.dart';
import '../../providers/admin_providers.dart';

class ServiceAssignmentScreen extends StatelessWidget {
  final String counterId;
  final String branchId;
  final String counterName;
  const ServiceAssignmentScreen(
      {super.key,
      required this.counterId,
      required this.branchId,
      required this.counterName});

  @override
  Widget build(BuildContext context) {
    final counterProv = context.read<CounterAdminProvider>();
    final serviceProv = context.read<ServiceAdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Assign – $counterName'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AdminTheme.primary,
      ),
      // Step 3: Listen ONLY to the counter document stream
      body: StreamBuilder<CounterModel?>(
        stream: counterProv.streamOne(counterId),
        builder: (context, counterSnap) {
          if (counterSnap.connectionState == ConnectionState.waiting && !counterSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final counter = counterSnap.data;
          if (counter == null) return const Center(child: Text('Counter not found'));

          // Use a Future for services to avoid rebuilding the list when the toggle changes
          return FutureBuilder<List<ServiceModel>>(
            // We need the sectorId. In a real app, you might fetch it from counter's branch.
            // For now, we'll use a cached fetch from serviceProv.
            future: _fetchServices(context, counter.branchId),
            builder: (context, serviceSnap) {
              if (serviceSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final services = serviceSnap.data ?? [];
              if (services.isEmpty) {
                return const _EmptyState(label: 'No services found.');
              }

              return Column(
                children: [
                   _CounterChip(
                    name: counter.name, 
                    assignedCount: counter.serviceIds.length
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: services.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _ServiceToggleTile(
                        service: services[i],
                        // Step 5: Evaluate value from the stream
                        isAssigned: counter.serviceIds.contains(services[i].id),
                        onToggle: (val) {
                          // Step 4 & 5: Instant toggle service using atomic update
                          counterProv.toggleService(counter.id, services[i].id, val);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<List<ServiceModel>> _fetchServices(BuildContext context, String branchId) async {
    // Get services for that branch
    final serviceSnap = await FirebaseFirestore.instance.collection('services')
        .where('branchId', isEqualTo: branchId).get();
    return serviceSnap.docs.map((d) => ServiceModel.fromDoc(d)).toList();
  }
}

class _CounterChip extends StatelessWidget {
  final String name;
  final int assignedCount;
  const _CounterChip({required this.name, required this.assignedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AdminTheme.accentGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AdminTheme.accent.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                Text('$assignedCount service(s) assigned', 
                  style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceToggleTile extends StatelessWidget {
  final ServiceModel service;
  final bool isAssigned;
  final ValueChanged<bool> onToggle;

  const _ServiceToggleTile({
    required this.service,
    required this.isAssigned,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAssigned ? AdminTheme.accent : const Color(0xFFE2E8F0),
          width: isAssigned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isAssigned ? 8 : 4),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: isAssigned ? AdminTheme.accentGradient : null,
            color: isAssigned ? null : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.design_services_outlined,
            color: isAssigned ? Colors.white : const Color(0xFF64748B),
            size: 20,
          ),
        ),
        title: Text(service.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Row(
          children: [
            const Icon(Icons.timer_outlined, size: 12, color: Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text('~${service.avgWaitMinutes} min wait',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),
        trailing: Transform.scale(
          scale: 0.9,
          child: Switch(
            value: isAssigned,
            onChanged: onToggle,
            activeColor: AdminTheme.accent,
            activeTrackColor: AdminTheme.accent.withAlpha(60),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.layers_clear_outlined, size: 64, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
