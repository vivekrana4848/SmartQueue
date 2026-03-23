import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'superAdmin' | 'counterAdmin'
  final String? counterId;
  final String? counterName;
  final String status; // 'active' | 'disabled'

  AdminModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.counterId,
    this.counterName,
    this.status = 'active',
  });

  bool get isSuperAdmin => role == 'superAdmin';
  bool get isCounterAdmin => role == 'counterAdmin';
  bool get isActive => status == 'active';

  factory AdminModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return AdminModel(
      id: doc.id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'counterAdmin',
      counterId: map['counterId'],
      counterName: map['counterName'],
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'role': role,
        'counterId': counterId,
        'counterName': counterName,
        'status': status,
      };

  AdminModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? counterId,
    String? counterName,
    String? status,
  }) {
    return AdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      counterId: counterId ?? this.counterId,
      counterName: counterName ?? this.counterName,
      status: status ?? this.status,
    );
  }
}
