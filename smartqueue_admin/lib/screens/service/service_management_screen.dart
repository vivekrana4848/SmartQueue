import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/admin_theme.dart';
import '../../models/service_model.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/admin_scaffold.dart';

import 'package:go_router/go_router.dart';
import '../../models/sector_model.dart';
import '../../models/branch_model.dart';

class ServiceManagementScreen extends StatefulWidget {
  final String? sectorId;
  final String? sectorName;
  final String? branchId;
  final String? branchName;
  const ServiceManagementScreen(
      {super.key,
      this.sectorId,
      this.sectorName,
      this.branchId,
      this.branchName});

  @override
  State<ServiceManagementScreen> createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sectorId == null) {
      return _buildSectorSelection(context);
    }
    if (widget.branchId == null) {
      return _buildBranchSelection(context);
    }
    return _buildServiceList(context);
  }

  Widget _buildSectorSelection(BuildContext context) {
    final prov = context.read<SectorAdminProvider>();
    return AdminScaffold(
      title: 'Services',
      currentRoute: '/dashboard/services',
      body: Column(
        children: [
          _Breadcrumbs(parts: const [('Services', null)]),
          Expanded(
            child: StreamBuilder<List<SectorModel>>(
              stream: prov.stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sectors = snap.data ?? [];
                if (sectors.isEmpty) {
                  return const Center(child: _EmptyState(label: 'No sectors found'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sectors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    leading: Text(sectors[i].icon,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(sectors[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Select sector to view services'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go(
                        '/dashboard/services/${sectors[i].id}?sectorName=${Uri.encodeComponent(sectors[i].name)}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBranchSelection(BuildContext context) {
    final prov = context.read<BranchAdminProvider>();
    return AdminScaffold(
      title: 'Select Branch',
      currentRoute: '/dashboard/services',
      body: Column(
        children: [
          _Breadcrumbs(parts: [
            ('Services', () => context.go('/dashboard/services')),
            (widget.sectorName ?? 'Sector', null),
          ]),
          Expanded(
            child: StreamBuilder<List<BranchModel>>(
              stream: prov.stream(sectorId: widget.sectorId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final branches = snap.data ?? [];
                if (branches.isEmpty) {
                  return const Center(
                      child: _EmptyState(label: 'No branches found in this sector'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    leading: const CircleAvatar(
                      backgroundColor: AdminTheme.accent,
                      child: Icon(Icons.location_on, color: Colors.white, size: 20),
                    ),
                    title: Text(branches[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(branches[i].address),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go(
                        '/dashboard/services/${widget.sectorId}/${branches[i].id}?sectorName=${Uri.encodeComponent(widget.sectorName!)}&branchName=${Uri.encodeComponent(branches[i].name)}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildServiceList(BuildContext context) {
    final prov = context.read<ServiceAdminProvider>();
    return AdminScaffold(
      title: 'Services – ${widget.branchName}',
      currentRoute: '/dashboard/services',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context, prov),
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
        backgroundColor: AdminTheme.accent,
      ),
      body: Column(
        children: [
          _Breadcrumbs(parts: [
            ('Services', () => context.go('/dashboard/services')),
            (widget.sectorName ?? 'Sector', () => context.go('/dashboard/services/${widget.sectorId}?sectorName=${Uri.encodeComponent(widget.sectorName!)}')),
            (widget.branchName ?? 'Branch', null),
          ]),
          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF94A3B8)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0), width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0), width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AdminTheme.accent, width: 1.8),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ServiceModel>>(
              stream: prov.stream(widget.branchId!),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data ?? [];
                final services = _query.isEmpty
                    ? all
                    : all
                        .where((s) => s.name.toLowerCase().contains(_query))
                        .toList();

                if (all.isEmpty) {
                  return const Center(
                      child: _EmptyState(label: 'No services yet'));
                }
                if (services.isEmpty) {
                  return Center(
                      child: _EmptyState(
                          label: 'No services match "${_searchCtrl.text}"'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _ServiceTile(
                    service: services[i],
                    onToggle: (v) => prov.toggle(services[i].id, v),
                    onEdit: () =>
                        _showDialog(context, prov, service: services[i]),
                    onDelete: () => prov.delete(services[i].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, ServiceAdminProvider prov,
      {ServiceModel? service}) {
    final nameCtrl = TextEditingController(text: service?.name ?? '');
    final descCtrl = TextEditingController(text: service?.description ?? '');
    final waitCtrl =
        TextEditingController(text: '${service?.avgWaitMinutes ?? 5}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(service == null ? 'Add Service' : 'Edit Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Service Name')),
            const SizedBox(height: 10),
            TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 10),
            TextField(
              controller: waitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Avg Wait (minutes)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final s = ServiceModel(
                id: service?.id ?? '',
                sectorId: widget.sectorId!,
                branchId: widget.branchId!,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                avgWaitMinutes: int.tryParse(waitCtrl.text.trim()) ?? 5,
                status: service?.status ?? 'active',
              );
              if (service == null)
                prov.add(s);
              else
                prov.update(s);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  final List<(String, VoidCallback?)> parts;
  const _Breadcrumbs({required this.parts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white.withAlpha(128),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: parts.expand((p) {
          final isLast = parts.last == p;
          return [
            InkWell(
              onTap: p.$2,
              child: Text(
                p.$1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                  color: isLast ? AdminTheme.primary : Colors.grey[600],
                ),
              ),
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right_rounded,
                    size: 14, color: Colors.grey),
              ),
          ];
        }).toList(),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final ServiceModel service;
  final void Function(bool) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ServiceTile(
      {required this.service,
      required this.onToggle,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: service.isActive
                ? const Color(0xFFE2E8F0)
                : const Color(0xFFFECACA)),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: service.isActive
                  ? AdminTheme.successGradient
                  : const LinearGradient(
                      colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.design_services_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text('~${service.avgWaitMinutes} min wait',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Switch(
            value: service.isActive,
            onChanged: onToggle,
            activeColor: AdminTheme.success,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: TextStyle(color: AdminTheme.danger))),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inbox_outlined, size: 56, color: Color(0xFFCBD5E1)),
        const SizedBox(height: 12),
        Text(label,
            style: const TextStyle(
                color: AdminTheme.primary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
