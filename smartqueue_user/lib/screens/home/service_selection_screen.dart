import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/queue_provider.dart';

import '../../models/service_model.dart';
import '../../app/app_theme.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/queue_indicator.dart';

class ServiceSelectionScreen extends StatelessWidget {
  final String branchId;
  final String branchName;
  final String sectorId;
  final String sectorName;

  const ServiceSelectionScreen({
    super.key,
    required this.branchId,
    required this.branchName,
    required this.sectorId,
    required this.sectorName,
  });

  @override
  Widget build(BuildContext context) {
    final queue = context.read<QueueProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.background,
      appBar: AppBar(
        title: Text(branchName),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Text(
              'Select Service',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ServiceModel>>(
              stream: queue.streamServices(branchId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No services available'));
                }

                final services = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _ServiceCard(
                      service: service,
                      onTap: () async {
                        queue.selectService(service);
                        // Navigate to token form first for confirmation if needed
                        // or generate directly if that's the current flow.
                        // The user prompt says "Upgrade TokenConfirmationScreen", 
                        // so I'll navigate to it.
                        context.push('/token-confirm?sectorId=$sectorId&branchId=$branchId&serviceId=${service.id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ModernCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.settings_suggest_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                ),
              ),
              QueueIndicator(waitMinutes: service.avgWaitMinutes),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            service.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: isDark ? Colors.white38 : AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Avg. Wait: ${service.avgWaitMinutes} min',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              Text(
                'Select',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
