import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/admin_theme.dart';
import '../../models/sector_model.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/admin_scaffold.dart';

class SectorManagementScreen extends StatelessWidget {
  const SectorManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<SectorAdminProvider>();
    return AdminScaffold(
      title: 'Sectors',
      currentRoute: '/dashboard/sectors',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context, prov),
        icon: const Icon(Icons.add),
        label: const Text('Add Sector'),
        backgroundColor: AdminTheme.accent,
      ),
      body: StreamBuilder<List<SectorModel>>(
        stream: prov.stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sectors = snap.data ?? [];
          if (sectors.isEmpty) {
            return const _EmptyState(
                label: 'No sectors yet.\nAdd your first sector to get started.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sectors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _SectorTile(
              sector: sectors[i],
              onEdit: () => _showDialog(context, prov, sector: sectors[i]),
              onDelete: () => _confirmDelete(context, prov, sectors[i].id),
              onViewBranches: () => context.go(
                '/dashboard/branches/${sectors[i].id}?sectorName=${Uri.encodeComponent(sectors[i].name)}',
              ),
              onViewServices: () => context.go(
                '/dashboard/services/${sectors[i].id}?sectorName=${Uri.encodeComponent(sectors[i].name)}',
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDialog(BuildContext context, SectorAdminProvider prov,
      {SectorModel? sector}) {
    final nameCtrl = TextEditingController(text: sector?.name ?? '');
    final iconCtrl = TextEditingController(text: sector?.icon ?? '🏢');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(sector == null ? 'Add Sector' : 'Edit Sector'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Sector Name',
                  hintText: 'e.g. Banking, Hospital, Government'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconCtrl,
              decoration: const InputDecoration(
                  labelText: 'Icon (emoji)',
                  hintText: '🏥, 🏦, 🏛, 💇, 🎟'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final s = SectorModel(
                id: sector?.id ?? '',
                name: nameCtrl.text.trim(),
                icon: iconCtrl.text.trim(),
                color: '#6C63FF',
                status: 'active',
                order: sector?.order ?? 0,
              );
              if (sector == null) prov.add(s);
              else prov.update(s);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, SectorAdminProvider prov, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Sector'),
        content: const Text('This will permanently delete the sector.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger),
            onPressed: () {
              prov.delete(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectorTile extends StatelessWidget {
  final SectorModel sector;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewBranches;
  final VoidCallback onViewServices;

  const _SectorTile({
    required this.sector,
    required this.onEdit,
    required this.onDelete,
    required this.onViewBranches,
    required this.onViewServices,
  });

  @override
  Widget build(BuildContext context) {
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
      child: InkWell(
        onTap: onViewBranches,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AdminTheme.accentGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(sector.icon,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sector.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: sector.isActive
                                    ? AdminTheme.success
                                    : const Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sector.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: sector.isActive
                                      ? AdminTheme.success
                                      : const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Options',
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (v) {
                      if (v == 'branches') onViewBranches();
                      if (v == 'services') onViewServices();
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'branches',
                          child: Row(
                            children: [
                              Icon(Icons.location_city_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('View Branches'),
                            ],
                          )),
                      PopupMenuItem(
                          value: 'services',
                          child: Row(
                            children: [
                              Icon(Icons.design_services_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('View Services'),
                            ],
                          )),
                      PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          )),
                      PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: AdminTheme.danger),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: AdminTheme.danger)),
                            ],
                          )),
                    ],
                  ),
                ],
              ),
            ),
            // Quick action bar
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  _QuickBtn(
                    label: 'View Branches',
                    icon: Icons.location_city_outlined,
                    onTap: onViewBranches,
                  ),
                  const VerticalDivider(width: 1),
                  _QuickBtn(
                    label: 'Services',
                    icon: Icons.design_services_outlined,
                    onTap: onViewServices,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickBtn(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: AdminTheme.accent),
      label: Text(
        label,
        style: const TextStyle(
            fontSize: 12,
            color: AdminTheme.accent,
            fontWeight: FontWeight.w600),
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
          const Icon(Icons.business_outlined,
              size: 64, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
