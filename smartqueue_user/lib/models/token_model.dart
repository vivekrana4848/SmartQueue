import 'package:cloud_firestore/cloud_firestore.dart';

enum TokenStatus { waiting, serving, completed, skipped, recalled, cancelled }

class TokenModel {
  final String id;
  final String userId;
  final String sectorId;
  final String sectorName;
  final String branchId;
  final String branchName;
  final String serviceId;
  final String serviceName;
  final String counterId;
  final String counterName;
  final String tokenNumber;
  final TokenStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int position;
  final String? userName;
  final String? userPhone;
  final double latitude;
  final double longitude;

  TokenModel({
    required this.id,
    required this.userId,
    required this.sectorId,
    required this.sectorName,
    required this.branchId,
    required this.branchName,
    required this.serviceId,
    required this.serviceName,
    required this.counterId,
    required this.counterName,
    required this.tokenNumber,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.position,
    this.userName,
    this.userPhone,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory TokenModel.fromDoc(DocumentSnapshot doc) {
    return TokenModel.fromMap(
      (doc.data() as Map<String, dynamic>?) ?? {},
      id: doc.id,
    );
  }

  factory TokenModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return TokenModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      sectorId: map['sectorId']?.toString() ?? '',
      sectorName: map['sectorName']?.toString() ?? '',
      branchId: map['branchId']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? '',
      serviceId: map['serviceId']?.toString() ?? '',
      serviceName: map['serviceName']?.toString() ?? '',
      counterId: map['counterId']?.toString() ?? '',
      counterName: map['counterName']?.toString() ?? '',
      tokenNumber: map['tokenNumber']?.toString() ?? '',
      status: statusFromString(map['status']?.toString()),
      createdAt: _parseDate(map['createdAt']),
      completedAt: map['completedAt'] != null ? _parseDate(map['completedAt']) : null,
      position: (map['position'] as num?)?.toInt() ?? 0,
      userName: map['userName']?.toString(),
      userPhone: map['userPhone']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static TokenStatus statusFromString(String? s) {
    if (s == null) return TokenStatus.waiting;
    return TokenStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == s.toLowerCase(),
      orElse: () => TokenStatus.waiting,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'sectorId': sectorId,
        'sectorName': sectorName,
        'branchId': branchId,
        'branchName': branchName,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'counterId': counterId,
        'counterName': counterName,
        'tokenNumber': tokenNumber,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'position': position,
        'userName': userName,
        'userPhone': userPhone,
        'latitude': latitude,
        'longitude': longitude,
      };

  bool get isActive => status == TokenStatus.waiting || status == TokenStatus.serving;

  String get statusLabel {
    switch (status) {
      case TokenStatus.waiting: return 'Waiting';
      case TokenStatus.serving: return 'Now Serving';
      case TokenStatus.completed: return 'Completed';
      case TokenStatus.skipped: return 'Skipped';
      case TokenStatus.recalled: return 'Recalled';
      case TokenStatus.cancelled: return 'Cancelled';
    }
  }
}
