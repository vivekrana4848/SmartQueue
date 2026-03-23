import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sector_model.dart';
import '../models/branch_model.dart';
import '../models/service_model.dart';
import '../models/token_model.dart';
import '../models/queue_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ───────────────── Sectors ─────────────────
  Stream<List<SectorModel>> streamSectors() {
    return _db
        .collection('sectors')
        .snapshots()
        .map((snapshot) {
      final sectors =
      snapshot.docs.map((doc) => SectorModel.fromDoc(doc)).toList();

      // safe sort
      sectors.sort((a, b) => a.order.compareTo(b.order));

      return sectors.where((s) =>
      s.status == 'active' ||
          s.status == 'ON').toList();
    });
  }

  Future<SectorModel?> getSector(String id) async {
    if (id.isEmpty) return null;

    final doc = await _db.collection('sectors').doc(id).get();

    if (!doc.exists) return null;

    return SectorModel.fromDoc(doc);
  }

  // ───────────────── Branches ─────────────────
  Stream<List<BranchModel>> streamBranches(String sectorId) {
    return _db
        .collection('branches')
        .where('sectorId', isEqualTo: sectorId.trim())
        .snapshots()
        .map((snapshot) {
      final branches =
      snapshot.docs.map((doc) => BranchModel.fromDoc(doc)).toList();

      return branches.where((b) =>
      b.status == 'active' ||
          b.status == 'ON').toList();
    });
  }

  Future<BranchModel?> getBranch(String id) async {
    if (id.isEmpty) return null;

    final doc = await _db.collection('branches').doc(id).get();

    if (!doc.exists) return null;

    return BranchModel.fromDoc(doc);
  }

  // ───────────────── Services ─────────────────
  Stream<List<ServiceModel>> streamServices(String branchId) {
    final sanitized = branchId.trim();

    return _db
        .collection('services')
        .where('branchId', isEqualTo: sanitized)
        .snapshots()
        .map((snapshot) {
      final all = snapshot.docs.map(ServiceModel.fromDoc).toList();
      return all.where((s) => s.isActive || s.status == 'ON').toList();
    });
  }

  Future<ServiceModel?> getService(String id) async {
    if (id.isEmpty) return null;
    final doc = await _db.collection('services').doc(id).get();
    return doc.exists ? ServiceModel.fromDoc(doc) : null;
  }

  // ───────────────── Token Generation ─────────────────
  Future<TokenModel?> generateToken({
    required String userId,
    required SectorModel sector,
    required BranchModel branch,
    required ServiceModel service,
    String? userName,
    String? userPhone,
  }) async {
    if (userId.isEmpty) return null;

    try {
      return await _db.runTransaction<TokenModel?>((transaction) async {
        final countersQuery = await _db
            .collection('counters')
            .where('branchId', isEqualTo: branch.id)
            .where('status', isEqualTo: 'active')
            .where('serviceIds', arrayContains: service.id)
            .get();

        if (countersQuery.docs.isEmpty) {
          debugPrint("❌ No active counters found for this service");
          return null;
        }

        String bestCounterId = '';
        String bestCounterName = '';
        int shortestQueue = 99999;
        List<String> waitList = [];

        for (var counter in countersQuery.docs) {
          final queueDoc = await transaction.get(_db.collection('queues').doc(counter.id));
          final data = queueDoc.data();
          final list = List<String>.from(data?['waitList'] ?? []);

          if (list.length < shortestQueue) {
            shortestQueue = list.length;
            bestCounterId = counter.id;
            bestCounterName = counter['name'] ?? 'Counter';
            waitList = list;
          }
        }

        if (bestCounterId.isEmpty) return null;

        // Serial number logic
        final dateStr = DateTime.now().toIso8601String().substring(0, 10);
        final statsRef = _db.collection('analytics').doc(dateStr);
        final statsSnap = await transaction.get(statsRef);
        final totalToday = (statsSnap.data()?['totalTokens'] ?? 0) as int;
        final nextNum = totalToday + 1;
        final tokenNum = "${sector.prefix}${nextNum.toString().padLeft(3, '0')}";

        final tokenRef = _db.collection('tokens').doc();
        final token = TokenModel(
          id: tokenRef.id,
          userId: userId,
          sectorId: sector.id,
          sectorName: sector.name,
          branchId: branch.id,
          branchName: branch.name,
          serviceId: service.id,
          serviceName: service.name,
          counterId: bestCounterId,
          counterName: bestCounterName,
          tokenNumber: tokenNum,
          status: TokenStatus.waiting,
          createdAt: DateTime.now(), // Local fallback, will be overwritten by serverTimestamp in toMap or directly
          position: shortestQueue + 1,
          userName: userName,
          userPhone: userPhone,
          latitude: branch.latitude,
          longitude: branch.longitude,
        );

        final tokenMap = token.toMap();
        tokenMap['createdAt'] = FieldValue.serverTimestamp();

        transaction.set(tokenRef, tokenMap);
        transaction.set(statsRef, {'totalTokens': nextNum, 'date': dateStr}, SetOptions(merge: true));

        transaction.set(
            _db.collection('users').doc(userId),
            {
              'currentTokenId': tokenRef.id,
              'lastTokenTime': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        waitList.add(tokenRef.id);
        transaction.set(
            _db.collection('queues').doc(bestCounterId),
            {
              'waitList': waitList,
              'updatedAt': FieldValue.serverTimestamp()
            },
            SetOptions(merge: true));

        return token;
      });
    } catch (e) {
      debugPrint("❌ Token Error $e");
      return null;
    }
  }

  // ───────────────── User Tokens ─────────────────
  Stream<List<TokenModel>> streamUserTokens(String userId) {

    return _db
        .collection('tokens')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => TokenModel.fromDoc(doc)).toList());
  }

  Stream<TokenModel?> streamToken(String tokenId) {

    return _db
        .collection('tokens')
        .doc(tokenId)
        .snapshots()
        .map((doc) => doc.exists ? TokenModel.fromDoc(doc) : null);
  }

  Stream<QueueModel?> streamQueue(String counterId) {

    return _db
        .collection('queues')
        .doc(counterId)
        .snapshots()
        .map((doc) => doc.exists ? QueueModel.fromDoc(doc) : null);
  }

  Future<void> cancelToken(String tokenId, String counterId) async {

    final batch = _db.batch();

    batch.update(_db.collection('tokens').doc(tokenId), {
      'status': 'cancelled',
      'completedAt': FieldValue.serverTimestamp(),
    });

    batch.update(_db.collection('queues').doc(counterId), {
      'waitList': FieldValue.arrayRemove([tokenId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<List<TokenModel>> streamUserActiveTokens(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    return _db
        .collection('tokens')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['waiting', 'serving'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TokenModel.fromDoc(doc)).toList();
    });
  }

  Stream<List<TokenModel>> streamUserHistory(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    return _db
        .collection('tokens')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['completed', 'cancelled', 'skipped'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TokenModel.fromDoc(doc)).toList();
    });
  }

  Stream<int> streamPeopleAhead(String tokenId, String counterId) {
    if (tokenId.isEmpty || counterId.isEmpty) {
      return Stream.value(0);
    }

    return _db.collection('queues').doc(counterId).snapshots().map((snap) {

      if (!snap.exists) return 0;

      final data = snap.data();

      final waitList = List<String>.from(data?['waitList'] ?? []);

      final index = waitList.indexOf(tokenId);

      if (index == -1) return 0;

      return index;
    });
  }
}