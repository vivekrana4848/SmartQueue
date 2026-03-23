import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../app/admin_theme.dart';
import '../../models/admin_model.dart';
import '../../models/branch_model.dart';
import '../../models/counter_model.dart';
import '../../providers/admin_providers.dart';
import '../../services/admin_firestore_service.dart';
import '../../widgets/admin_scaffold.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AdminUserProvider>();
    return AdminScaffold(
      title: 'Admin Management',
      currentRoute: '/dashboard/admins',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, prov),
        icon: const Icon(Icons.add),
        label: const Text('Add Admin'),
        backgroundColor: AdminTheme.accent,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by name, email, branch or counter...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear), 
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        }
                      )
                    : null,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AdminModel>>(
              stream: prov.stream,
              builder: (context, adminSnap) {
                return StreamBuilder<List<CounterModel>>(
                  stream: AdminFirestoreService().streamAllCounters(),
                  builder: (context, counterSnap) {
                    return StreamBuilder<List<BranchModel>>(
                      stream: AdminFirestoreService().streamAllBranches(),
                      builder: (context, branchSnap) {
                        if (adminSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final admins = adminSnap.data ?? [];
                        final counters = counterSnap.data ?? [];
                        final branches = branchSnap.data ?? [];

                        if (admins.isEmpty) return const _EmptyState();

                        // Grouping Logic
                        final superAdmins = <AdminModel>[];
                        final branchAdmins = <String, List<AdminModel>>{}; // branchId -> List<Admin>
                        final branchMap = {for (var b in branches) b.id: b};
                        final counterMap = {for (var c in counters) c.id: c};

                        for (var admin in admins) {
                          // Apply Search Filter
                          bool matches = admin.name.toLowerCase().contains(_searchQuery) ||
                              admin.email.toLowerCase().contains(_searchQuery);
                          
                          if (admin.counterName != null && admin.counterName!.toLowerCase().contains(_searchQuery)) {
                            matches = true;
                          }

                          String? bName;
                          if (admin.counterId != null) {
                            final c = counterMap[admin.counterId];
                            if (c != null) {
                              final b = branchMap[c.branchId];
                              if (b != null) {
                                bName = b.name;
                                if (bName.toLowerCase().contains(_searchQuery)) matches = true;
                              }
                            }
                          }

                          if (!matches && _searchQuery.isNotEmpty) continue;

                          if (admin.isSuperAdmin) {
                            superAdmins.add(admin);
                          } else if (admin.counterId != null) {
                            final c = counterMap[admin.counterId];
                            final bId = c?.branchId ?? 'unassigned';
                            branchAdmins.putIfAbsent(bId, () => []).add(admin);
                          }
                        }

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (superAdmins.isNotEmpty) ...[
                              _SectionHeader(title: 'Super Admins', icon: Icons.shield_outlined),
                              ...superAdmins.map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _AdminTile(
                                  admin: a,
                                  onToggle: (val) => prov.toggle(a.id, val),
                                  onDelete: () => _confirmDelete(context, prov, a),
                                ),
                              )),
                              const SizedBox(height: 20),
                            ],
                            if (branchAdmins.isNotEmpty) ...[
                              _SectionHeader(title: 'Branches', icon: Icons.account_tree_outlined),
                              ...branchAdmins.entries.map((entry) {
                                final bId = entry.key;
                                final bAdmins = entry.value;
                                final branch = branchMap[bId];
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                      child: ExpansionTile(
                                        initiallyExpanded: _searchQuery.isNotEmpty,
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AdminTheme.accent.withAlpha(15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.location_on_outlined, color: AdminTheme.accent, size: 20),
                                        ),
                                        title: Text(branch?.name ?? 'Unassigned Branch', 
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                        subtitle: Text('${bAdmins.length} Admin(s)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        children: bAdmins.map((a) => Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                          child: _AdminTile(
                                            admin: a,
                                            onToggle: (val) => prov.toggle(a.id, val),
                                            onDelete: () => _confirmDelete(context, prov, a),
                                          ),
                                        )).toList(),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                            if (superAdmins.isEmpty && branchAdmins.isEmpty && _searchQuery.isNotEmpty)
                              const Center(child: Padding(
                                padding: EdgeInsets.all(40),
                                child: Text('No admins match your search.'),
                              )),
                          ],
                        );
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

  void _showCreateDialog(BuildContext context, AdminUserProvider prov) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final searchCounterCtrl = TextEditingController();
    String selectedRole = 'counterAdmin';
    String? selectedCounterId;
    String? selectedCounterName;
    String counterQuery = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Create Admin Account'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon:
                              Icon(Icons.admin_panel_settings_outlined)),
                      items: const [
                        DropdownMenuItem(
                            value: 'counterAdmin',
                            child: Text('Counter Admin')),
                        DropdownMenuItem(
                            value: 'superAdmin', child: Text('Super Admin')),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          selectedRole = v ?? 'counterAdmin';
                          if (selectedRole != 'counterAdmin') {
                            selectedCounterId = null;
                            selectedCounterName = null;
                          }
                        });
                      },
                    ),
                    if (selectedRole == 'counterAdmin') ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),
                      // Search Bar for Counters
                      TextField(
                        controller: searchCounterCtrl,
                        onChanged: (v) => setDialogState(() => counterQuery = v.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search counters...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<AdminModel>>(
                        stream: prov.stream,
                        builder: (context, adminSnap) {
                          return StreamBuilder<List<CounterModel>>(
                            stream: AdminFirestoreService().streamAllCounters(),
                            builder: (context, counterSnap) {
                              return StreamBuilder<List<BranchModel>>(
                                stream: AdminFirestoreService().streamAllBranches(),
                                builder: (context, branchSnap) {
                                  if (adminSnap.connectionState == ConnectionState.waiting ||
                                      counterSnap.connectionState == ConnectionState.waiting ||
                                      branchSnap.connectionState == ConnectionState.waiting) {
                                    return const Center(child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ));
                                  }

                                  final admins = adminSnap.data ?? [];
                                  final allCounters = counterSnap.data ?? [];
                                  final branches = branchSnap.data ?? [];

                                  // Extract assigned counter IDs
                                  final assignedIds = admins
                                      .where((a) => a.isCounterAdmin && a.counterId != null)
                                      .map((a) => a.counterId!)
                                      .toSet();

                                  // Filter available counters
                                  var availableCounters = allCounters
                                      .where((c) => !assignedIds.contains(c.id))
                                      .toList();

                                  // Apply search query
                                  if (counterQuery.isNotEmpty) {
                                    availableCounters = availableCounters
                                        .where((c) => c.name.toLowerCase().contains(counterQuery))
                                        .toList();
                                  }

                                  if (availableCounters.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AdminTheme.danger.withAlpha(10),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "No counters available. All counters already have admins assigned.",
                                        style: TextStyle(color: AdminTheme.danger, fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }

                                  return DropdownButtonFormField<String>(
                                    value: selectedCounterId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Assign to Counter',
                                        prefixIcon: Icon(Icons.storefront_outlined)),
                                    hint: const Text('Select counter'),
                                    items: availableCounters.map((c) {
                                      final branch = branches.firstWhere((b) => b.id == c.branchId, orElse: () => BranchModel(id: '', sectorId: '', name: 'Unknown', address: '', status: ''));
                                      return DropdownMenuItem(
                                        value: c.id,
                                        child: Text('${c.name} — ${branch.name}', overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        final c = allCounters.firstWhere((c) => c.id == v);
                                        setDialogState(() {
                                          selectedCounterId = v;
                                          selectedCounterName = c.name;
                                        });
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: (selectedRole == 'counterAdmin' && selectedCounterId == null)
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _createAdmin(
                          context,
                          prov,
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text.trim(),
                          role: selectedRole,
                          counterId: selectedCounterId,
                          counterName: selectedCounterName,
                        );
                      },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createAdmin(
    BuildContext context,
    AdminUserProvider prov, {
    required String name,
    required String email,
    required String password,
    required String role,
    String? counterId,
    String? counterName,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      final appName = 'secondary-${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
          email: email, password: password);

      final adminModel = AdminModel(
        id: cred.user!.uid,
        email: email,
        name: name,
        role: role,
        counterId: counterId,
        counterName: counterName,
        status: 'active',
      );

      await prov.createAdminDoc(cred.user!.uid, adminModel);
      await secondaryAuth.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Admin account created successfully'),
            backgroundColor: AdminTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: AdminTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      await secondaryApp?.delete();
    }
  }

  void _confirmDelete(
      BuildContext context, AdminUserProvider prov, AdminModel admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Admin'),
        content: Text('Remove "${admin.name}" from the system?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AdminTheme.danger),
            onPressed: () {
              prov.delete(admin.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final AdminModel admin;
  final void Function(bool) onToggle;
  final VoidCallback onDelete;

  const _AdminTile({
    required this.admin,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = admin.isSuperAdmin;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isSuperAdmin
                  ? AdminTheme.primaryGradient
                  : AdminTheme.accentGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
                isSuperAdmin
                    ? Icons.shield_outlined
                    : Icons.storefront_outlined,
                color: Colors.white,
                size: 22),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  admin.email,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _RoleBadge(isSuperAdmin: isSuperAdmin),
                    if (admin.counterName != null) _CounterBadge(name: admin.counterName!),
                    _StatusBadge(isActive: admin.isActive),
                  ],
                ),
              ],
            ),
          ),
          // Toggle + Delete
          Column(
            children: [
              Switch(
                value: admin.isActive,
                activeColor: AdminTheme.success,
                onChanged: onToggle,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AdminTheme.danger, size: 20),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool isSuperAdmin;
  const _RoleBadge({required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isSuperAdmin
            ? AdminTheme.primary.withAlpha(15)
            : AdminTheme.accent.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(isSuperAdmin ? 'Super Admin' : 'Counter Admin',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isSuperAdmin ? AdminTheme.primary : AdminTheme.accent)),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  final String name;
  const _CounterBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AdminTheme.success.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(name,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AdminTheme.success)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? AdminTheme.success.withAlpha(20)
            : AdminTheme.danger.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(isActive ? 'Active' : 'Disabled',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? AdminTheme.success : AdminTheme.danger)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.manage_accounts_outlined,
              size: 64, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text('No Admins Yet',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.primary)),
          const SizedBox(height: 6),
          Text('Use the + button to create an admin account.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }
}
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AdminTheme.primary.withAlpha(180)),
          const SizedBox(width: 8),
          Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AdminTheme.primary.withAlpha(180),
                  letterSpacing: 1.2)),
          const SizedBox(width: 10),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
