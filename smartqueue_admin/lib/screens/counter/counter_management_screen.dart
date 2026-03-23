import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/admin_theme.dart';
import '../../models/counter_model.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/admin_scaffold.dart';

import '../../models/sector_model.dart';
import '../../models/branch_model.dart';

class CounterManagementScreen extends StatefulWidget {
  final String? sectorId;
  final String? sectorName;
  final String? branchId;
  final String? branchName;

  const CounterManagementScreen({
    super.key,
    this.sectorId,
    this.sectorName,
    this.branchId,
    this.branchName,
  });

  @override
  State<CounterManagementScreen> createState() =>
      _CounterManagementScreenState();
}

class _CounterManagementScreenState extends State<CounterManagementScreen> {
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
    return _buildCounterList(context);
  }

  Widget _buildSectorSelection(BuildContext context) {
    final prov = context.read<SectorAdminProvider>();
    return AdminScaffold(
      title: 'Counters',
      currentRoute: '/dashboard/counters',
      body: Column(
        children: [
          _Breadcrumbs(parts: const [('Counters', null)]),
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
                    subtitle: const Text('Select sector to view branches'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go(
                        '/dashboard/counters/${sectors[i].id}?sectorName=${Uri.encodeComponent(sectors[i].name)}'),
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
      title: 'Branches – ${widget.sectorName}',
      currentRoute: '/dashboard/counters',
      body: Column(
        children: [
          _Breadcrumbs(parts: [
            ('Counters', () => context.go('/dashboard/counters')),
            (widget.sectorName ?? 'Unknown', null),
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
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AdminTheme.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_on_outlined,
                          color: AdminTheme.success, size: 20),
                    ),
                    title: Text(branches[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(branches[i].address),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go(
                        '/dashboard/counters/${widget.sectorId}/${branches[i].id}?sectorName=${Uri.encodeComponent(widget.sectorName ?? '')}&branchName=${Uri.encodeComponent(branches[i].name)}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterList(BuildContext context) {
    final prov = context.read<CounterAdminProvider>();
    return AdminScaffold(
      title: 'Counters — ${widget.branchName}',
      currentRoute: '/dashboard/counters',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context, prov),
        icon: const Icon(Icons.add),
        label: const Text("Add Counter"),
        backgroundColor: AdminTheme.accent,
      ),
      body: Column(
        children: [
          _Breadcrumbs(parts: [
            ('Counters', () => context.go('/dashboard/counters')),
            (widget.sectorName ?? 'Unknown',
                () => context.go('/dashboard/counters/${widget.sectorId}?sectorName=${Uri.encodeComponent(widget.sectorName ?? '')}')),
            (widget.branchName ?? 'Unknown', null),
          ]),
          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search counters...',
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
          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<CounterModel>>(
              stream: prov.stream(widget.branchId!),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data ?? [];
                final counters = _query.isEmpty
                    ? all
                    : all
                        .where((c) => c.name.toLowerCase().contains(_query))
                        .toList();

                if (all.isEmpty) {
                  return const Center(
                      child: _EmptyState(label: 'No counters yet'));
                }
                if (counters.isEmpty) {
                  return Center(
                      child: _EmptyState(
                          label: 'No counters match "${_searchCtrl.text}"'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: counters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _CounterTile(
                    counter: counters[i],
                    onToggle: (v) => prov.toggle(counters[i].id, v),
                    onEdit: () =>
                        _showDialog(context, prov, counter: counters[i]),
                    onDelete: () => prov.delete(counters[i].id),
                    onAssign: () => context.go(
                      '/dashboard/assign/${counters[i].id}?branchId=${widget.branchId}&name=${Uri.encodeComponent(counters[i].name)}',
                    ),
                    onQueue: () => context.go(
                      '/dashboard/queue/${counters[i].id}?name=${Uri.encodeComponent(counters[i].name)}',
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

  void _showDialog(BuildContext context, CounterAdminProvider prov,
      {CounterModel? counter}) {
    final nameCtrl = TextEditingController(text: counter?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(counter == null ? 'Add Counter' : 'Edit Counter'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Counter Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final c = CounterModel(
                id: counter?.id ?? '',
                branchId: widget.branchId!,
                name: nameCtrl.text.trim(),
                status: counter?.status ?? 'active',
                serviceIds: counter?.serviceIds ?? [],
              );
              if (counter == null)
                prov.add(c);
              else
                prov.update(c);
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

class _CounterTile extends StatelessWidget {
  final CounterModel counter;
  final void Function(bool) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssign;
  final VoidCallback onQueue;
  const _CounterTile(
      {required this.counter,
      required this.onToggle,
      required this.onEdit,
      required this.onDelete,
      required this.onAssign,
      required this.onQueue});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
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
                    gradient: counter.isActive
                        ? AdminTheme.warningGradient
                        : const LinearGradient(
                            colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_outlined,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(counter.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(
                          '${counter.serviceIds.length} service(s) assigned',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Switch(
                  value: counter.isActive,
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
                _ActionBtn(label: 'Assign', onTap: onAssign),
                _ActionBtn(label: 'Queue', onTap: onQueue),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inbox_outlined, size: 56, color: Color(0xFFCBD5E1)),
        const SizedBox(height: 12),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AdminTheme.primary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
