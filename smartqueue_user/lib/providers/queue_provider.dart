import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/sector_model.dart';
import '../models/branch_model.dart';
import '../models/service_model.dart';
import '../models/token_model.dart';
import '../models/queue_model.dart';

class QueueProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();

  SectorModel? _selectedSector;
  BranchModel? _selectedBranch;
  ServiceModel? _selectedService;
  TokenModel? _generatedToken;
  bool _isGenerating = false;
  String? _generationError;

  SectorModel? get selectedSector => _selectedSector;
  BranchModel? get selectedBranch => _selectedBranch;
  ServiceModel? get selectedService => _selectedService;
  TokenModel? get generatedToken => _generatedToken;
  bool get isGenerating => _isGenerating;
  String? get generationError => _generationError;

  void selectSector(SectorModel sector) {
    _selectedSector = sector;
    _generationError = null;
    notifyListeners();
  }

  void selectBranch(BranchModel branch) {
    _selectedBranch = branch;
    _generationError = null;
    notifyListeners();
  }

  void selectService(ServiceModel service) {
    _selectedService = service;
    _generationError = null;
    notifyListeners();
  }

  Future<void> loadSelectionFromIds({
    String? sectorId,
    String? branchId,
    String? serviceId,
  }) async {
    if (sectorId != null && _selectedSector?.id != sectorId) {
      _selectedSector = await _fs.getSector(sectorId);
    }
    if (branchId != null && _selectedBranch?.id != branchId) {
      _selectedBranch = await _fs.getBranch(branchId);
    }
    if (serviceId != null && _selectedService?.id != serviceId) {
      _selectedService = await _fs.getService(serviceId);
    }
    notifyListeners();
  }

  Stream<List<SectorModel>> streamSectors() => _fs.streamSectors();
  Stream<List<BranchModel>> streamBranches(String sectorId) => _fs.streamBranches(sectorId);
  Stream<List<ServiceModel>> streamServices(String branchId) => _fs.streamServices(branchId);
  
  // Reactive Active Token (Chained Listen)
  Stream<List<TokenModel>> streamUserActiveTokens(String userId) => 
      _fs.streamUserActiveTokens(userId);

  // Filtered History
  Stream<List<TokenModel>> streamUserHistory(String userId) => 
      _fs.streamUserHistory(userId);

  Stream<TokenModel?> streamToken(String tokenId) => _fs.streamToken(tokenId);
  Stream<QueueModel?> streamQueue(String counterId) => _fs.streamQueue(counterId);
  Stream<int> streamPeopleAhead(String tokenId, String counterId) => 
      _fs.streamPeopleAhead(tokenId, counterId);

  Future<String?> generateToken(String userId) async {
    if (userId.isEmpty || _selectedSector == null || _selectedBranch == null || _selectedService == null) {
      _generationError = 'Required selections or User ID missing';
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _generationError = null;
    notifyListeners();

    try {
      final token = await _fs.generateToken(
        userId: userId,
        sector: _selectedSector!,
        branch: _selectedBranch!,
        service: _selectedService!,
      );
      
      if (token == null) {
        _generationError = 'No counter available for this service right now.';
        notifyListeners();
        return null;
      }

      _generatedToken = token;
      return token.id;
    } catch (e) {
      _generationError = 'Unexpected error: $e';
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> cancelToken(String tokenId, String counterId) async {
    try {
      await _fs.cancelToken(tokenId, counterId);
      _generationError = null;
    } catch (e) {
      _generationError = 'Failed to cancel token: $e';
    }
    notifyListeners();
  }

  void resetSelection() {
    _selectedSector = null;
    _selectedBranch = null;
    _selectedService = null;
    _generatedToken = null;
    _generationError = null;
    notifyListeners();
  }
}
