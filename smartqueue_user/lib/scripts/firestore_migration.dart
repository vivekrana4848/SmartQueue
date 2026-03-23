import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// One-time migration script to fix SmartQueue Firestore relationships.
/// Usage: Call [FirestoreMigration.run()] from a temporary button or main().
class FirestoreMigration {
  static final _db = FirebaseFirestore.instance;

  static Future<void> run() async {
    debugPrint('🚀 Starting Firestore Migration...');
    final batch = _db.batch();

    try {
      // 1. Get Sectors Map (Name -> ID)
      final sectorsSnap = await _db.collection('sectors').get();
      final sectorMap = {
        for (var doc in sectorsSnap.docs)
          (doc.data()['name'] as String).toLowerCase(): doc.id
      };
      debugPrint('✅ Scanned ${sectorMap.length} sectors');

      // 2. Fix Branches & Map (Name -> ID)
      final branchesSnap = await _db.collection('branches').get();
      final branchMap = <String, String>{};
      
      for (var bDoc in branchesSnap.docs) {
        final data = bDoc.data();
        final name = data['name'] as String;
        branchMap[name.toLowerCase()] = bDoc.id;

        // Ensure branch points to actual sector ID
        final currentSectorId = data['sectorId'] as String;
        if (!sectorMap.values.contains(currentSectorId)) {
          final mappedId = sectorMap[currentSectorId.toLowerCase()];
          if (mappedId != null) {
            batch.update(bDoc.reference, {'sectorId': mappedId});
          }
        }
      }
      debugPrint('✅ Scanned ${branchMap.length} branches');

      // 3. Fix Services
      final servicesSnap = await _db.collection('services').get();
      int servicesFixed = 0;
      for (var sDoc in servicesSnap.docs) {
        final data = sDoc.data();
        final currentBranchId = data['branchId'] as String;
        final currentStatus = data['status']?.toString().toLowerCase() ?? '';
        
        Map<String, dynamic> updates = {};

        // Fix Status
        if (currentStatus == 'on' || currentStatus == 'enabled' || currentStatus == 'active') {
          updates['status'] = 'active';
        }

        // Fix Branch Relationship
        if (!branchMap.values.contains(currentBranchId)) {
          // It's likely a name/slug, try to find the real ID
          final realBranchId = branchMap[currentBranchId.toLowerCase()];
          if (realBranchId != null) {
            updates['branchId'] = realBranchId;
            
            // Also inject sectorId for optimized queries if possible
            final branchDoc = await _db.collection('branches').doc(realBranchId).get();
            final sectorId = branchDoc.data()?['sectorId'];
            if (sectorId != null) updates['sectorId'] = sectorId;
          }
        }

        if (updates.isNotEmpty) {
          batch.update(sDoc.reference, updates);
          servicesFixed++;
        }
      }
      debugPrint('✅ Optimized $servicesFixed service documents');

      // 4. Fix Counters
      final countersSnap = await _db.collection('counters').get();
      int countersFixed = 0;
      for (var cDoc in countersSnap.docs) {
        final data = cDoc.data();
        final currentBranchId = data['branchId'] as String;
        
        if (!branchMap.values.contains(currentBranchId)) {
          final realBranchId = branchMap[currentBranchId.toLowerCase()];
          if (realBranchId != null) {
            batch.update(cDoc.reference, {'branchId': realBranchId});
            countersFixed++;
          }
        }
      }
      debugPrint('✅ Fixed $countersFixed counter relationships');

      await batch.commit();
      debugPrint('🏁 Migration Complete! All relationships normalized.');
    } catch (e) {
      debugPrint('❌ Migration Failed: $e');
    }
  }
}
