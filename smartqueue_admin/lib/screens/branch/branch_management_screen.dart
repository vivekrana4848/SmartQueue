import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../app/admin_theme.dart';
import '../../models/branch_model.dart';
import '../../models/sector_model.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/admin_scaffold.dart';
import 'map_picker_screen.dart';

class BranchManagementScreen extends StatefulWidget {
  final String? sectorId;
  final String? sectorName;

  const BranchManagementScreen({
    super.key,
    this.sectorId,
    this.sectorName,
  });

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
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

  String get _title {
    if (widget.sectorName != null && widget.sectorName!.isNotEmpty) {
      return 'Branches – ${widget.sectorName}';
    }
    return 'Branches';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sectorId == null) {
      return _buildSectorSelection(context);
    }
    return _buildBranchList(context);
  }

  Widget _buildSectorSelection(BuildContext context) {
    final prov = context.read<SectorAdminProvider>();
    return AdminScaffold(
      title: 'Branches',
      currentRoute: '/dashboard/branches',
      body: Column(
        children: [
          _Breadcrumbs(parts: [('Branches', null)]),
          Expanded(
            child: StreamBuilder<List<SectorModel>>(
              stream: prov.stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final sectors = snap.data ?? [];
                if (sectors.isEmpty) {
                  return Center(child: _EmptyState(label: 'No sectors found'));
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
                    subtitle: const Text('Select sector to view branches'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go(
                        '/dashboard/branches/${sectors[i].id}?sectorName=${Uri.encodeComponent(sectors[i].name)}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchList(BuildContext context) {
    final prov = context.read<BranchAdminProvider>();
    return AdminScaffold(
      title: _title,
      currentRoute: '/dashboard/branches',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context, prov),
        icon: const Icon(Icons.add),
        label: const Text('Add Branch'),
        backgroundColor: AdminTheme.accent,
      ),
      body: Column(
        children: [
          _Breadcrumbs(parts: [
            ('Branches', () => context.go('/dashboard/branches')),
            (widget.sectorName ?? 'Sector', null),
          ]),
          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search branches...',
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
                  borderSide: BorderSide(
                      color: const Color(0xFFE2E8F0), width: 1.2),
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
          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<BranchModel>>(
              stream: prov.stream(sectorId: widget.sectorId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final all = snap.data ?? [];
                final branches = _query.isEmpty
                    ? all
                    : all
                        .where((b) =>
                            b.name.toLowerCase().contains(_query) ||
                            b.address.toLowerCase().contains(_query))
                        .toList();

                if (all.isEmpty) {
                  return _EmptyState(label: 'No branches yet');
                }
                if (branches.isEmpty) {
                  return _EmptyState(
                      label: 'No branches match "${_searchCtrl.text}"');
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _BranchTile(
                    branch: branches[i],
                    onToggle: (val) => prov.toggle(branches[i].id, val),
                    onEdit: () =>
                        _showDialog(context, prov, branch: branches[i]),
                    onDelete: () => prov.delete(branches[i].id),
                    onServices: () => context.go(
                      '/dashboard/services/${branches[i].sectorId}/${branches[i].id}?sectorName=${Uri.encodeComponent(widget.sectorName ?? 'Sector')}&branchName=${Uri.encodeComponent(branches[i].name)}',
                    ),
                    onCounters: () => context.go(
                      '/dashboard/counters/${branches[i].sectorId}/${branches[i].id}?sectorName=${Uri.encodeComponent(widget.sectorName ?? 'Sector')}&branchName=${Uri.encodeComponent(branches[i].name)}',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, BranchAdminProvider prov,
      {BranchModel? branch}) {
    final nameCtrl = TextEditingController(text: branch?.name ?? '');
    final addrCtrl = TextEditingController(text: branch?.address ?? '');
    double lat = branch?.latitude ?? 0.0;
    double lng = branch?.longitude ?? 0.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(branch == null ? 'Add Branch' : 'Edit Branch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: 'Branch Name')),
              const SizedBox(height: 12),
              TextField(
                  controller: addrCtrl,
                  decoration: InputDecoration(labelText: 'Address')),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminTheme.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withAlpha(50)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AdminTheme.accent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lat == 0 && lng == 0
                                ? 'No location selected'
                                : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: lat == 0 ? Colors.grey : AdminTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.accent.withAlpha(40),
                        foregroundColor: AdminTheme.accent,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push<LatLng>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapPickerScreen(
                              initialLocation: (lat != 0 && lng != 0)
                                  ? LatLng(lat, lng)
                                  : null,
                            ),
                          ),
                        );
                        if (result != null) {
                          setDialogState(() {
                            lat = result.latitude;
                            lng = result.longitude;
                          });
                        }
                      },
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('Select on Map'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final b = BranchModel(
                  id: branch?.id ?? '',
                  sectorId: widget.sectorId ?? branch?.sectorId ?? '',
                  name: nameCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  status: branch?.status ?? 'active',
                  latitude: lat,
                  longitude: lng,
                );
                if (branch == null)
                  prov.add(b);
                else
                  prov.update(b);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: const Icon(Icons.chevron_right_rounded,
                    size: 14, color: Colors.grey),
              ),
          ];
        }).toList(),
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  final BranchModel branch;
  final void Function(bool) onToggle;
  final VoidCallback onEdit, onDelete, onServices, onCounters;

  const _BranchTile({
    required this.branch,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onServices,
    required this.onCounters,
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: branch.isActive
                        ? AdminTheme.accentGradient
                        : const LinearGradient(
                            colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_outlined,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(branch.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(branch.address,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Switch(
                  value: branch.isActive,
                  onChanged: onToggle,
                  activeColor: AdminTheme.success,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _ActionBtn(label: 'Services', onTap: onServices),
                _ActionBtn(label: 'Counters', onTap: onCounters),
                _ActionBtn(label: 'Edit', onTap: onEdit),
                _ActionBtn(label: 'Delete', onTap: onDelete, danger: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _ActionBtn(
      {required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: danger ? AdminTheme.danger : AdminTheme.accent,
                fontWeight: FontWeight.w600)),
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
          const Icon(Icons.inbox_outlined, size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AdminTheme.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
