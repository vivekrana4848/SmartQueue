import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/timestamp_utils.dart';

enum TokenStatus { waiting, serving, completed, skipped, recalled }

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
  final int position; // position in queue
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
    final map = doc.data() as Map<String, dynamic>;
    return TokenModel(
      id: doc.id,
      userId: map['userId'] ?? '',
      sectorId: map['sectorId'] ?? '',
      sectorName: map['sectorName'] ?? '',
      branchId: map['branchId'] ?? '',
      branchName: map['branchName'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      counterId: map['counterId'] ?? '',
      counterName: map['counterName'] ?? '',
      tokenNumber: map['tokenNumber'] ?? '',
      status: _statusFromString(map['status'] ?? 'waiting'),
      createdAt: parseTimestamp(map['createdAt']),
      completedAt: map['completedAt'] == null ? null : parseTimestamp(map['completedAt']),
      position: map['position'] ?? 0,
      userName: map['userName'],
      userPhone: map['userPhone'],
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static TokenStatus _statusFromString(String s) {
    switch (s) {
      case 'serving':
        return TokenStatus.serving;
      case 'completed':
        return TokenStatus.completed;
      case 'skipped':
        return TokenStatus.skipped;
      case 'recalled':
        return TokenStatus.recalled;
      default:
        return TokenStatus.waiting;
    }
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
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'position': position,
        'userName': userName,
        'userPhone': userPhone,
        'latitude': latitude,
        'longitude': longitude,
      };

  bool get isActive =>
      status == TokenStatus.waiting || status == TokenStatus.serving;

  String get statusLabel {
    switch (status) {
      case TokenStatus.waiting:
        return 'Waiting';
      case TokenStatus.serving:
        return 'Now Serving';
      case TokenStatus.completed:
        return 'Completed';
      case TokenStatus.skipped:
        return 'Skipped';
      case TokenStatus.recalled:
        return 'Recalled';
    }
  }
}
