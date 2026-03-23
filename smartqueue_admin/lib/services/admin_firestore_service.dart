import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sector_model.dart';
import '../models/branch_model.dart';
import '../models/service_model.dart';
import '../models/counter_model.dart';
import '../models/token_model.dart';
import '../models/queue_model.dart';
import '../models/analytics_model.dart';
import '../models/admin_model.dart';

class AdminFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Sectors CRUD ──────────────────────────────────────────────────────────
  Stream<List<SectorModel>> streamAllSectors() => _db
      .collection('sectors')
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map(SectorModel.fromDoc).toList());

  Future<void> addSector(SectorModel s) =>
      _db.collection('sectors').add(s.toMap());

  Future<void> updateSector(SectorModel s) =>
      _db.collection('sectors').doc(s.id).update(s.toMap());

  Future<void> deleteSector(String id) =>
      _db.collection('sectors').doc(id).delete();

  // ── Branches CRUD ─────────────────────────────────────────────────────────
  Stream<List<BranchModel>> streamAllBranches({String? sectorId}) {
    Query q = _db.collection('branches');
    if (sectorId != null) q = q.where('sectorId', isEqualTo: sectorId);
    return q.snapshots().map((s) => s.docs.map(BranchModel.fromDoc).toList());
  }

  Future<void> addBranch(BranchModel b) =>
      _db.collection('branches').add(b.toMap());

  Future<void> updateBranch(BranchModel b) =>
      _db.collection('branches').doc(b.id).update(b.toMap());

  Future<void> deleteBranch(String id) =>
      _db.collection('branches').doc(id).delete();

  Future<void> toggleBranch(String id, String status) =>
      _db.collection('branches').doc(id).update({'status': status});

  // ── Services CRUD ─────────────────────────────────────────────────────────
  Stream<List<ServiceModel>> streamServices(String branchId) => _db
      .collection('services')
      .where('branchId', isEqualTo: branchId.trim())
      .snapshots()
      .map((s) => s.docs.map(ServiceModel.fromDoc).toList());

  Future<void> addService(ServiceModel s) =>
      _db.collection('services').add(s.toMap());

  Future<void> updateService(ServiceModel s) =>
      _db.collection('services').doc(s.id).update(s.toMap());

  Future<void> deleteService(String id) =>
      _db.collection('services').doc(id).delete();

  Future<void> toggleService(String id, String status) =>
      _db.collection('services').doc(id).update({'status': status});

  // ── Counters CRUD ─────────────────────────────────────────────────────────
  Stream<List<CounterModel>> streamCounters(String branchId) => _db
      .collection('counters')
      .where('branchId', isEqualTo: branchId)
      .snapshots()
      .map((s) => s.docs.map(CounterModel.fromDoc).toList());

  Stream<CounterModel?> streamCounter(String id) => _db
      .collection('counters')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? CounterModel.fromDoc(d) : null);

  Stream<List<CounterModel>> streamAllCounters() => _db
      .collection('counters')
      .snapshots()
      .map((s) => s.docs.map(CounterModel.fromDoc).toList());

  Future<void> addCounter(CounterModel c) =>
      _db.collection('counters').add(c.toMap());

  Future<void> updateCounter(CounterModel c) =>
      _db.collection('counters').doc(c.id).update(c.toMap());

  Future<void> deleteCounter(String id) =>
      _db.collection('counters').doc(id).delete();

  Future<void> toggleCounter(String id, String status) =>
      _db.collection('counters').doc(id).update({'status': status});

  // lib/services/admin_firestore_service.dart

  Future<void> assignServiceToCounter(String counterId, String serviceId) async {
    await _db.collection('counters').doc(counterId).update({
      'serviceIds': FieldValue.arrayUnion([serviceId]),
    });
  }

  Future<void> removeServiceFromCounter(String counterId, String serviceId) async {
    await _db.collection('counters').doc(counterId).update({
      'serviceIds': FieldValue.arrayRemove([serviceId]),
    });
  }

  Future<void> toggleCounterService(String counterId, String serviceId, bool enable) async {
    if (enable) {
      await assignServiceToCounter(counterId, serviceId);
    } else {
      await removeServiceFromCounter(counterId, serviceId);
    }
  }

  // ── Queue Management ──────────────────────────────────────────────────────
  Stream<QueueModel?> streamQueue(String counterId) => _db
      .collection('queues')
      .doc(counterId)
      .snapshots()
      .map((d) => d.exists ? QueueModel.fromDoc(d) : null);

  Future<void> nextToken(String counterId) async {
    final qDoc = await _db.collection('queues').doc(counterId).get();
    if (!qDoc.exists) return;
    final data = qDoc.data()!;
    final waitList = List<String>.from(data['waitList'] ?? []);
    final currentToken = data['currentToken'] as String?;

    // Complete current token
    if (currentToken != null) {
      await _db.collection('tokens').doc(currentToken).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      final today = DateTime.now().toIso8601String().substring(0, 10);
      _db.collection('analytics').doc(today).set({
        'completedTokens': FieldValue.increment(1),
        'date': today,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    String? nextId;
    if (waitList.isNotEmpty) {
      nextId = waitList.first;
      waitList.removeAt(0);
    }

    if (nextId != null) {
      await _db.collection('tokens').doc(nextId).update({'status': 'serving'});
    }

    await _db.collection('queues').doc(counterId).update({
      'currentToken': nextId,
      'waitList': waitList,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> skipToken(String counterId) async {
    final qDoc = await _db.collection('queues').doc(counterId).get();
    if (!qDoc.exists) return;
    final data = qDoc.data()!;
    final waitList = List<String>.from(data['waitList'] ?? []);
    final currentToken = data['currentToken'] as String?;

    if (currentToken != null) {
      await _db.collection('tokens').doc(currentToken).update({'status': 'skipped'});
    }

    String? nextId;
    if (waitList.isNotEmpty) {
      nextId = waitList.first;
      waitList.removeAt(0);
    }
    if (nextId != null) {
      await _db.collection('tokens').doc(nextId).update({'status': 'serving'});
    }

    await _db.collection('queues').doc(counterId).update({
      'currentToken': nextId,
      'waitList': waitList,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recallToken(String counterId) async {
    final qDoc = await _db.collection('queues').doc(counterId).get();
    if (!qDoc.exists) return;
    final data = qDoc.data()!;
    final currentToken = data['currentToken'] as String?;
    if (currentToken != null) {
      await _db.collection('tokens').doc(currentToken).update({'status': 'recalled'});
    }
    await _db.collection('queues').doc(counterId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeToken(String counterId) => nextToken(counterId);

  // ── Tokens ────────────────────────────────────────────────────────────────
  Stream<List<TokenModel>> streamTodayTokens() {
    final start = DateTime.now().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0);
    return _db
        .collection('tokens')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TokenModel.fromDoc).toList());
  }

  Stream<List<TokenModel>> streamFilteredTokens({String filter = ''}) {
    Query q = _db.collection('tokens');

    if (filter == 'today') {
      final start = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
      q = q.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
           .orderBy('createdAt', descending: true);
    } else if (filter == 'completed') {
      q = q.where('status', isEqualTo: 'completed')
           .orderBy('completedAt', descending: true);
    } else if (filter == 'pending') {
      q = q.where('status', isEqualTo: 'waiting')
           .orderBy('createdAt', descending: false); 
      // wait, they didn't specify order for pending, but usually FIFO
    } else {
      q = q.orderBy('createdAt', descending: true);
    }

    return q.limit(100).snapshots().map((s) => s.docs.map(TokenModel.fromDoc).toList());
  }

  Stream<TokenModel?> streamToken(String tokenId) => _db
      .collection('tokens')
      .doc(tokenId)
      .snapshots()
      .map((d) => d.exists ? TokenModel.fromDoc(d) : null);

  // ── Analytics ─────────────────────────────────────────────────────────────
  Stream<AnalyticsModel?> streamTodayAnalytics() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _db
        .collection('analytics')
        .doc(today)
        .snapshots()
        .map((d) => d.exists ? AnalyticsModel.fromDoc(d) : null);
  }

  Stream<List<AnalyticsModel>> streamWeekAnalytics() {
    final week = DateTime.now().subtract(const Duration(days: 7));
    return _db
        .collection('analytics')
        .where('date',
            isGreaterThanOrEqualTo:
                week.toIso8601String().substring(0, 10))
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AnalyticsModel.fromDoc).toList());
  }

  // ── Admins CRUD ───────────────────────────────────────────────────────────
  Future<AdminModel?> getAdminByUid(String uid) async {
    final doc = await _db.collection('admins').doc(uid).get();
    if (!doc.exists) return null;
    return AdminModel.fromDoc(doc);
  }

  Stream<List<AdminModel>> streamAllAdmins() => _db
      .collection('admins')
      .snapshots()
      .map((s) => s.docs.map(AdminModel.fromDoc).toList());

  Future<void> createAdminDoc(String uid, AdminModel admin) =>
      _db.collection('admins').doc(uid).set(admin.toMap());

  Future<void> updateAdmin(AdminModel admin) =>
      _db.collection('admins').doc(admin.id).update(admin.toMap());

  Future<void> toggleAdmin(String id, String status) =>
      _db.collection('admins').doc(id).update({'status': status});

  Future<void> deleteAdmin(String id) =>
      _db.collection('admins').doc(id).delete();

  // ── Dashboard Stats ────────────────────────────────────────────────────────
  Stream<int> streamSectorsCount() => _db.collection('sectors').snapshots().map((s) => s.docs.length);
  Stream<int> streamBranchesCount() => _db.collection('branches').snapshots().map((s) => s.docs.length);
  Stream<int> streamCountersCount() => _db.collection('counters').snapshots().map((s) => s.docs.length);
  
  Stream<int> streamTodayTokensCount() {
    final start = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    return _db.collection('tokens')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .snapshots()
        .map((s) => s.docs.length);
  }
}
