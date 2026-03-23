import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/admin_theme.dart';
import '../../models/token_model.dart';
import '../../services/admin_firestore_service.dart';
import '../../widgets/admin_scaffold.dart';

class AdminTokensScreen extends StatefulWidget {
  final String filter;
  const AdminTokensScreen({super.key, this.filter = ''});

  @override
  State<AdminTokensScreen> createState() => _AdminTokensScreenState();
}

class _AdminTokensScreenState extends State<AdminTokensScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = '';
  String _selectedBranch = '';
  String _selectedService = '';

  @override
  void initState() {
    super.initState();
    if (widget.filter.isNotEmpty) {
      if (widget.filter == 'completed') _selectedStatus = 'completed';
      if (widget.filter == 'pending') _selectedStatus = 'waiting';
    }
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Tokens',
      currentRoute: '/dashboard',
      body: Column(
        children: [
          // Breadcrumbs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white.withAlpha(128),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InkWell(
                  onTap: () => context.go('/dashboard'),
                  child: const Text('Dashboard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.chevron_right_rounded, size: 14, color: Colors.grey),
                ),
                Text('Tokens (${widget.filter.isEmpty ? 'All' : widget.filter})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.primary)),
              ],
            ),
          ),
          
          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search token number...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AdminTheme.accent, width: 1.8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    value: _selectedStatus.isEmpty ? null : _selectedStatus,
                    hint: 'All Statuses',
                    items: ['waiting', 'serving', 'completed', 'skipped', 'recalled'],
                    onChanged: (val) => setState(() => _selectedStatus = val ?? ''),
                  ),
                ),
                // Other dropdowns (Branches, Services) could be added here later
                const Spacer(),
              ],
            ),
          ),
          
          // Data Table
          Expanded(
            child: StreamBuilder<List<TokenModel>>(
              stream: AdminFirestoreService().streamFilteredTokens(
                filter: widget.filter,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var tokens = snap.data ?? [];
                
                // Client-side filtering for search & additional dropdowns
                if (_searchQuery.isNotEmpty) {
                  tokens = tokens.where((t) => t.tokenNumber.toLowerCase().contains(_searchQuery)).toList();
                }
                if (_selectedStatus.isNotEmpty && widget.filter != 'pending' && widget.filter != 'completed') {
                  tokens = tokens.where((t) => t.status.name == _selectedStatus).toList();
                }
                
                if (tokens.isEmpty) {
                  return const Center(child: Text('No tokens found.'));
                }
                
                return SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                        columns: const [
                          DataColumn(label: Text('Token Number')),
                          DataColumn(label: Text('User')),
                          DataColumn(label: Text('Service')),
                          DataColumn(label: Text('Branch')),
                          DataColumn(label: Text('Counter')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Created Time')),
                        ],
                        rows: tokens.map((t) {
                          return DataRow(cells: [
                            DataCell(Text(t.tokenNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(t.userName ?? 'Guest')),
                            DataCell(Text(t.serviceName)),
                            DataCell(Text(t.branchName)),
                            DataCell(Text(t.counterName)),
                            DataCell(_StatusBadge(status: t.status)),
                            DataCell(Text(DateFormat('MMM d, h:mm a').format(t.createdAt))),
                          ]);
                        }).toList(),
                      ),
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

  Widget _buildDropdown({required String? value, required String hint, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Color(0xFF94A3B8))),
          isExpanded: true,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TokenStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case TokenStatus.serving: color = AdminTheme.accent; break;
      case TokenStatus.completed: color = AdminTheme.success; break;
      case TokenStatus.skipped: color = const Color(0xFF94A3B8); break;
      case TokenStatus.recalled: color = AdminTheme.warning; break;
      default: color = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(6)),
      child: Text(status.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
