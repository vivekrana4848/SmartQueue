import 'package:cloud_firestore/cloud_firestore.dart';

class QueueModel {
  final String id;
  final String counterId;
  final String? currentToken;
  final List<String> waitList;
  final DateTime updatedAt;

  QueueModel({
    required this.id,
    required this.counterId,
    this.currentToken,
    required this.waitList,
    required this.updatedAt,
  });

  factory QueueModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return QueueModel(
      id: doc.id,
      counterId: map['counterId'] ?? doc.id,
      currentToken: map['currentToken'],
      waitList: List<String>.from(map['waitList'] ?? []),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'counterId': counterId,
        'currentToken': currentToken,
        'waitList': waitList,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
