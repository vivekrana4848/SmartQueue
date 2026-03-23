import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/queue_provider.dart';
import '../../models/branch_model.dart';
import '../../app/app_theme.dart';
import '../../widgets/modern_card.dart';

class BranchSelectionScreen extends StatefulWidget {
  final String sectorId;
  final String sectorName;

  const BranchSelectionScreen({
    super.key,
    required this.sectorId,
    required this.sectorName,
  });

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final queue = context.read<QueueProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.background,
      appBar: AppBar(
        title: Text(widget.sectorName),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search branches...',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.textSecondary.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white38 : AppTheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BranchModel>>(
              stream: queue.streamBranches(widget.sectorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No branches available'));
                }

                final branches = snapshot.data!
                    .where((b) => b.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    return _BranchCard(branch: branch, sectorId: widget.sectorId, sectorName: widget.sectorName);
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

class _BranchCard extends StatelessWidget {
  final BranchModel branch;
  final String sectorId;
  final String sectorName;

  const _BranchCard({required this.branch, required this.sectorId, required this.sectorName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ModernCard(
      onTap: () {
        context.read<QueueProvider>().selectBranch(branch);
        context.push('/services/${branch.id}?name=${Uri.encodeComponent(branch.name)}&sectorId=$sectorId&sectorName=${Uri.encodeComponent(sectorName)}');
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  branch.address,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white24 : Colors.black12),
        ],
      ),
    );
  }
}
