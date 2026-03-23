import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/timestamp_utils.dart';

class QueueModel {
  final String id; // same as counterId
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

  int get peopleAhead => waitList.length;

  factory QueueModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return QueueModel(
      id: doc.id,
      counterId: map['counterId'] ?? doc.id,
      currentToken: map['currentToken'],
      waitList: List<String>.from(map['waitList'] ?? []),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'counterId': counterId,
        'currentToken': currentToken,
        'waitList': waitList,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
