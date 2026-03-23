import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsModel {
  final String date;
  final int totalTokens;
  final int completedTokens;
  final int avgWaitMinutes;

  AnalyticsModel({
    required this.date,
    required this.totalTokens,
    required this.completedTokens,
    required this.avgWaitMinutes,
  });

  int get pendingTokens => totalTokens - completedTokens;
  double get completionRate =>
      totalTokens == 0 ? 0 : completedTokens / totalTokens;

  factory AnalyticsModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return AnalyticsModel(
      date: map['date'] ?? doc.id,
      totalTokens: map['totalTokens'] ?? 0,
      completedTokens: map['completedTokens'] ?? 0,
      avgWaitMinutes: map['avgWaitMinutes'] ?? 5,
    );
  }
}
