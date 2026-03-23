import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_firestore_service.dart';
import '../models/admin_model.dart';
import '../models/sector_model.dart';
import '../models/branch_model.dart';
import '../models/service_model.dart';
import '../models/counter_model.dart';
import '../models/queue_model.dart';
import '../models/analytics_model.dart';

// ── Auth ────────────────────────────────────────────────────────────────────
enum AdminAuthStatus { loading, authenticated, unauthenticated }

class AdminAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AdminFirestoreService _fs = AdminFirestoreService();

  AdminAuthStatus _status = AdminAuthStatus.loading;
  User? _user;
  AdminModel? _adminModel;
  bool _isLoading = false;
  String? _error;

  AdminAuthStatus get status => _status;
  User? get user => _user;
  AdminModel? get adminModel => _adminModel;
  String? get userRole => _adminModel?.role;
  String? get counterId => _adminModel?.counterId;
  String? get counterName => _adminModel?.counterName;
  bool get isSuperAdmin => _adminModel?.isSuperAdmin ?? false;
  bool get isCounterAdmin => _adminModel?.isCounterAdmin ?? false;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminAuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? u) async {
    _user = u;
    if (u != null) {
      _adminModel = await _fs.getAdminByUid(u.uid);
      _status = AdminAuthStatus.authenticated;
    } else {
      _adminModel = null;
      _status = AdminAuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (cred.user != null) {
        _adminModel = await _fs.getAdminByUid(cred.user!.uid);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _adminModel = null;
    await _auth.signOut();
  }
}

// ── Sector ──────────────────────────────────────────────────────────────────
class SectorAdminProvider extends ChangeNotifier {
  final AdminFirestoreService _fs = AdminFirestoreService();

  Stream<List<SectorModel>> get stream => _fs.streamAllSectors();

  Future<void> add(SectorModel s) => _fs.addSector(s);
  Future<void> update(SectorModel s) => _fs.updateSector(s);
  Future<void> delete(String id) => _fs.deleteSector(id);
}

// ── Branch ──────────────────────────────────────────────────────────────────
class BranchAdminProvider extends ChangeNotifier {
  final AdminFirestoreService _fs = AdminFirestoreService();

  Stream<List<BranchModel>> stream({String? sectorId}) =>
      _fs.streamAllBranches(sectorId: sectorId);

  Future<void> add(BranchModel b) => _fs.addBranch(b);
  Future<void> update(BranchModel b) => _fs.updateBranch(b);
  Future<void> delete(String id) => _fs.deleteBranch(id);
  Future<void> toggle(String id, bool on) =>
      _fs.toggleBranch(id, on ? 'active' : 'inactive');
}

// ── Service ─────────────────────────────────────────────────────────────────
class ServiceAdminProvider extends ChangeNotifier {
  final AdminFirestoreService _fs = AdminFirestoreService();

  Stream<List<ServiceModel>> stream(String branchId) =>
      _fs.streamServices(branchId);

  Future<void> add(ServiceModel s) => _fs.addService(s);
  Future<void> update(ServiceModel s) => _fs.updateService(s);
  Future<void> delete(String id) => _fs.deleteService(id);
  Future<void> toggle(String id, bool on) =>
      _fs.toggleService(id, on ? 'active' : 'inactive');
}

// ── Counter ─────────────────────────────────────────────────────────────────
class CounterAdminProvider extends ChangeNotifier {
  final AdminFirestoreService _fs = AdminFirestoreService();

  Stream<List<CounterModel>> stream(String branchId) =>
      _fs.streamCounters(branchId);

  Stream<List<CounterModel>> streamAll() => _fs.streamAllCounters();

  Stream<CounterModel?> streamOne(String id) => _fs.streamCounter(id);

  Future<void> add(CounterModel c) => _fs.addCounter(c);
  Future<void> update(CounterModel c) => _fs.updateCounter(c);
  Future<void> delete(String id) => _fs.deleteCounter(id);
  Future<void> toggle(String id, bool on) =>
      _fs.toggleCounter(id, on ? 'active' : 'inactive');
  Future<void> assignService(String counterId, String serviceId) =>
      _fs.assignServiceToCounter(counterId, serviceId);
  Future<void> removeService(String counterId, String serviceId) =>
      _fs.removeServiceFromCounter(counterId, serviceId);
  Future<void> toggleService(String counterId, String serviceId, bool enable) =>
      _fs.toggleCounterService(counterId, serviceId, enable);
}

// ── Queue ────────────────────────────────────────────────────────────────────
class QueueAdminProvider extends ChangeNotifier {
  final AdminFirestoreService _fs = AdminFirestoreService();

  Stream<QueueModel?> streamQueue(String counterId) =>
      _fs.streamQueue(counterId);

  Future<void> next(String counterId) => _fs.nextToken(counterId);
  Future<void> skip(String counterId) => _fs.skipToken(counterId);
  Future<void> recall(String counterId) => _fs.recallToken(counterId);
  Future<void> complete(String counterId) => _fs.completeToken(counterId);
}

// ── Analytics ────────────────────────────────────────────────────────────────
class AnalyticsProvider extends ChangeNotifier {
  final AdminFirestoreService _fs = AdminFirestoreService();

  Stream<AnalyticsModel?> get todayStream => _fs.streamTodayAnalytics();
  Stream<List<AnalyticsModel>> get weekStream => _fs.streamWeekAnalytics();
}

// ── Admin User Management ─────────────────────────────────────────────────────
class AdminUserProvider extends ChangeNotifier {
  final AdminFirestoreService _fs = AdminFirestoreService();

  Stream<List<AdminModel>> get stream => _fs.streamAllAdmins();

  Future<void> createAdminDoc(String uid, AdminModel admin) =>
      _fs.createAdminDoc(uid, admin);

  Future<void> update(AdminModel admin) => _fs.updateAdmin(admin);

  Future<void> toggle(String id, bool enabled) =>
      _fs.toggleAdmin(id, enabled ? 'active' : 'disabled');

  Future<void> delete(String id) => _fs.deleteAdmin(id);
}

// ── Dashboard Stats ──────────────────────────────────────────────────────────
class DashboardStatsProvider extends ChangeNotifier {
  final AdminFirestoreService _fs = AdminFirestoreService();

  int sectorsCount = 0;
  int branchesCount = 0;
  int countersCount = 0;
  int todayTokens = 0;

  DashboardStatsProvider() {
    _init();
  }

  void _init() {
    _fs.streamSectorsCount().listen((count) {
      sectorsCount = count;
      notifyListeners();
    });
    _fs.streamBranchesCount().listen((count) {
      branchesCount = count;
      notifyListeners();
    });
    _fs.streamCountersCount().listen((count) {
      countersCount = count;
      notifyListeners();
    });
    _fs.streamTodayTokensCount().listen((count) {
      todayTokens = count;
      notifyListeners();
    });
  }
}
