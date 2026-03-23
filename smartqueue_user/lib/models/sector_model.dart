import 'package:cloud_firestore/cloud_firestore.dart';

class SectorModel {
  final String id;
  final String name;
  final String icon; // Icon name from material icons
  final String color; // Hex color string
  final String status;
  final int order;
  final String prefix;

  SectorModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.status,
    required this.order,
    this.prefix = 'T',
  });

  factory SectorModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return SectorModel(
      id: doc.id,
      name: map['name'] ?? '',
      icon: map['icon'] ?? 'category',
      color: map['color'] ?? '#000000',
      status: map['status'] ?? 'active',
      order: map['order'] ?? 0,
      prefix: map['prefix'] ?? 'T',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'icon': icon,
        'color': color,
        'status': status,
        'order': order,
        'prefix': prefix,
      };
}