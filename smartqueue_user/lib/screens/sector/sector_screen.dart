import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/sector_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/sector_card.dart';

class SectorScreen extends StatelessWidget {
  const SectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Sector'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: StreamBuilder<List<SectorModel>>(
        stream: FirestoreService().streamSectors(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sectors = snap.data ?? [];
          if (sectors.isEmpty) {
            return const Center(child: Text('No sectors available'));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemCount: sectors.length,
              itemBuilder: (context, i) => SectorCard(
                sector: sectors[i],
                colorIndex: i,
                onTap: () => context.go(
                  '/dashboard/sectors/${sectors[i].id}/branches',
                  extra: sectors[i].name,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
