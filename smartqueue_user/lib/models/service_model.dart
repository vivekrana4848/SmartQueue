import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ServiceModel {
  final String id;
  final String sectorId;
  final String branchId;
  final String name;
  final String description;
  final int avgWaitMinutes;
  final String status;

  ServiceModel({
    required this.id,
    required this.sectorId,
    required this.branchId,
    required this.name,
    required this.description,
    required this.avgWaitMinutes,
    required this.status,
  });

  factory ServiceModel.fromDoc(DocumentSnapshot doc) {
    final map = (doc.data() as Map<String, dynamic>?) ?? {};
    
    // Debug info for fields
    if (kDebugMode) {
      debugPrint('ServiceModel: Processing Doc ID: ${doc.id}');
      debugPrint('ServiceModel: branchId in Doc: ${map['branchId']}');
      debugPrint('ServiceModel: status in Doc: ${map['status']}');
    }

    return ServiceModel(
      id: doc.id,
      sectorId: map['sectorId']?.toString() ?? '',
      branchId: map['branchId']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unnamed Service',
      description: map['description']?.toString() ?? '',
      avgWaitMinutes: (map['avgWaitMinutes'] as num?)?.toInt() ?? 0,
      status: map['status']?.toString() ?? 'active',
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

  bool get isActive => status == 'active';
}
