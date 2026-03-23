import 'package:cloud_firestore/cloud_firestore.dart';

class CounterModel {
  final String id;
  final String branchId;
  final String name;
  final String status; // 'active' | 'inactive'
  final List<String> serviceIds;
  final String? currentServingToken;

  CounterModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.status,
    required this.serviceIds,
    this.currentServingToken,
  });

  bool get isActive => status == 'active';

  factory CounterModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return CounterModel(
      id: doc.id,
      branchId: map['branchId'] ?? '',
      name: map['name'] ?? '',
      status: map['status'] ?? 'active',
      serviceIds: List<String>.from(map['serviceIds'] ?? []),
      currentServingToken: map['currentServingToken'],
    );
  }

  Map<String, dynamic> toMap() => {
        'branchId': branchId,
        'name': name,
        'status': status,
        'serviceIds': serviceIds,
        'currentServingToken': currentServingToken,
      };
}
