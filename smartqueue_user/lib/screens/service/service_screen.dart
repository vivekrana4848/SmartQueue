import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_theme.dart';
import '../../models/service_model.dart';
import '../../services/firestore_service.dart';

class ServiceScreen extends StatelessWidget {
  final String branchId;
  final String sectorId;
  final Map<String, String> extra;
  const ServiceScreen(
      {super.key,
      required this.branchId,
      required this.sectorId,
      required this.extra});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(extra['branchName'] ?? 'Services')),
      body: StreamBuilder<List<ServiceModel>>(
        stream: FirestoreService().streamServices(branchId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final services = snap.data;
          if (services == null || services.isEmpty) {
            return const Center(child: Text('No services available'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final service = services[i];
              return _ServiceCard(
                service: service,
                sectorId: sectorId,
                branchId: branchId,
                extra: extra,
              );
            },
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final String sectorId;
  final String branchId;
  final Map<String, String> extra;
  const _ServiceCard(
      {required this.service,
      required this.sectorId,
      required this.branchId,
      required this.extra});

  @override
  Widget build(BuildContext context) {
    final isActive = service.isActive;
    return GestureDetector(
      onTap: isActive
          ? () => context.go('/dashboard/token-form', extra: {
                'sectorId': sectorId,
                'sectorName': extra['sectorName'] ?? 'Unknown Sector',
                'branchId': branchId,
                'branchName': extra['branchName'] ?? 'Unknown Branch',
                'serviceId': service.id,
                'serviceName': service.name.isNotEmpty ? service.name : 'Unknown Service',
              })
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: isActive
                    ? AppTheme.greenGradient
                    : const LinearGradient(
                        colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.miscellaneous_services_outlined,
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                  size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name.isNotEmpty ? service.name : 'Unnamed Service',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('~${service.avgWaitMinutes} min wait',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getLoadColor(service.avgWaitMinutes),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getLoadLabel(service.avgWaitMinutes),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getLoadColor(service.avgWaitMinutes),
                        ),
                      ),
                    ],
                  ),
                  if (!isActive) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Service Unavailable',
                          style: TextStyle(
                              color: Color(0xFF856404),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Select',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Color _getLoadColor(int wait) {
    if (wait < 10) return Colors.green;
    if (wait < 20) return Colors.amber;
    return Colors.red;
  }

  String _getLoadLabel(int wait) {
    if (wait < 10) return 'Low Traffic';
    if (wait < 20) return 'Moderate Traffic';
    return 'Busy';
  }
}
