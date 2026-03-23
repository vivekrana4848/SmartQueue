import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> exportAllFirestore() async {
  final firestore = FirebaseFirestore.instance;

  final collections = [
    'sectors',
    'branches',
    'services',
    'counters',
    'queues',
    'tokens',
    'users'
  ];

  for (var collection in collections) {
    final snapshot = await firestore.collection(collection).get();

    print("========== $collection ==========");

    for (var doc in snapshot.docs) {
      print(doc.data());
    }
  }
}