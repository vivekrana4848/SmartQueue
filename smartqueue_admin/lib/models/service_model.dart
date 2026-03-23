import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String sectorId;
  final String branchId;
  final String name;
  final String description;
  final int avgWaitMinutes;
  final String status; // 'active' | 'inactive'

  ServiceModel({
    required this.id,
    required this.sectorId,
    required this.branchId,
    required this.name,
    required this.description,
    required this.avgWaitMinutes,
    required this.status,
  });

  bool get isActive => status == 'active';

  factory ServiceModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      sectorId: map['sectorId'] ?? '',
      branchId: map['branchId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      avgWaitMinutes: map['avgWaitMinutes'] ?? 5,
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() => {
        'sectorId': sectorId,
        'branchId': branchId,
        'name': name,
        'description': description,
        'avgWaitMinutes': avgWaitMinutes,
        'status': status,
      };
}
