import 'package:cloud_firestore/cloud_firestore.dart';

class SectorModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String status; // 'active' | 'inactive'
  final int order;

  SectorModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.status,
    required this.order,
  });

  bool get isActive => status == 'active';

  factory SectorModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return SectorModel(
      id: doc.id,
      name: map['name'] ?? '',
      icon: map['icon'] ?? '🏢',
      color: map['color'] ?? '#6C63FF',
      status: map['status'] ?? 'active',
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'icon': icon,
        'color': color,
        'status': status,
        'order': order,
      };
}
