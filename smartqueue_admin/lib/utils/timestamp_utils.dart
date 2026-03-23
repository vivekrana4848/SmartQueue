import 'package:cloud_firestore/cloud_firestore.dart';

/// Safely parses a Firestore value into a DateTime.
/// If the value is a Timestamp, it converts it using toDate().
/// Otherwise (String "SERVER_TIMESTAMP", null, etc.), it returns DateTime.now().
DateTime parseTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return DateTime.now();
}
