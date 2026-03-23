import 'package:flutter/material.dart';
import '../../models/branch_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../widgets/saas_widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class BranchScreen extends StatefulWidget {
  final String sectorId;
  final String sectorName;
  const BranchScreen(
      {super.key, required this.sectorId, required this.sectorName});

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  String _query = '';
  Position? _userPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userPosition = pos;
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sectorName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search branches...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withAlpha(40)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withAlpha(40)),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BranchModel>>(
              stream: FirestoreService().streamBranches(widget.sectorId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting || _isLoadingLocation) {
                  return Center(child: CircularProgressIndicator());
                }
                var branches = snap.data ?? [];
                
                // 1. Calculate Distances
                final branchData = branches.map((b) {
                  double? dist;
                  if (_userPosition != null && b.latitude != 0) {
                    dist = LocationService.calculateDistance(
                      _userPosition!.latitude,
                      _userPosition!.longitude,
                      b.latitude,
                      b.longitude,
                    );
                  }
                  return (branch: b, distance: dist);
                }).toList();

                // 2. Sort by Nearest First
                branchData.sort((a, b) {
                  if (a.distance == null) return 1;
                  if (b.distance == null) return -1;
                  return a.distance!.compareTo(b.distance!);
                });

                // 3. Filter
                var filtered = branchData;
                if (_query.isNotEmpty) {
                  filtered = branchData
                      .where((item) => item.branch.name.toLowerCase().contains(_query))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text('No branches found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    return BranchCard(
                      name: item.branch.name,
                      address: item.branch.address,
                      distanceMeters: item.distance,
                      isActive: item.branch.isActive,
                      onTap: () => context.go(
                        '/dashboard/sectors/${widget.sectorId}/branches/${item.branch.id}/services',
                        extra: {
                          'branchName': item.branch.name,
                          'sectorId': widget.sectorId,
                        },
                      ),
                      onMapTap: () async {
                        final url = 'https://www.google.com/maps/search/?api=1&query=${item.branch.latitude},${item.branch.longitude}';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }
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
