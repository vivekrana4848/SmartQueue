import 'package:cloud_firestore/cloud_firestore.dart';

class BranchModel {
  final String id;
  final String sectorId;
  final String name;
  final String address;
  final String status; // 'active', 'inactive'
  final double latitude;
  final double longitude;

  BranchModel({
    required this.id,
    required this.sectorId,
    required this.name,
    required this.address,
    required this.status,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory BranchModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return BranchModel(
      id: doc.id,
      sectorId: map['sectorId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      status: map['status'] ?? 'active',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'sectorId': sectorId,
        'name': name,
        'address': address,
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
      };

  bool get isActive => status == 'active';
}
