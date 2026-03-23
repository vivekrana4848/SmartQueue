import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../models/sector_model.dart';
import '../models/branch_model.dart';
import '../models/service_model.dart';

class SectorProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();
  Stream<List<SectorModel>> get sectorStream => _fs.streamSectors();
}

class BranchProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();
  Stream<List<BranchModel>> streamBranches(String sectorId) =>
      _fs.streamBranches(sectorId);
}

class ServiceProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();
  Stream<List<ServiceModel>> streamServices(String branchId) =>
      _fs.streamServices(branchId);
}
