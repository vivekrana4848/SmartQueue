import 'package:flutter/foundation.dart';
import '../models/token_model.dart';
import '../models/sector_model.dart';
import '../models/branch_model.dart';
import '../models/service_model.dart';
import '../services/firestore_service.dart';

class TokenProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();

  bool _isGenerating = false;
  String? _error;
  TokenModel? _lastToken;

  bool get isGenerating => _isGenerating;
  String? get error => _error;
  TokenModel? get lastToken => _lastToken;

  Stream<List<TokenModel>> streamUserTokens(String userId) =>
      _fs.streamUserTokens(userId);

  Stream<TokenModel?> streamToken(String tokenId) =>
      _fs.streamToken(tokenId);

  Future<TokenModel?> generateToken({
    required String userId,
    required SectorModel sector,
    required BranchModel branch,
    required ServiceModel service,
    String? userName,
    String? userPhone,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      // Step 5: Add loading timeout protection (5 seconds)
      final token = await Future.any([
        _fs.generateToken(
          userId: userId,
          sector: sector,
          branch: branch,
          service: service,
          userName: userName,
          userPhone: userPhone,
        ),
        Future.delayed(const Duration(seconds: 10)).then((_) {
          throw Exception('Token generation timed out. Please try again.');
        }),
      ]);
      
      if (token == null) {
        _error = 'No counter available for this service right now.';
        notifyListeners();
        return null;
      }

      _lastToken = token;
      return token;
    } catch (e) {
      _error = e.toString().contains('timed out') 
          ? 'Token generation failed. Please try again.' 
          : 'Token generation failed: ${e.toString()}';
      notifyListeners();
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
