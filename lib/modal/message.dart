import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  int? id; // Changed from String uuid to int? id
  String senderUuid;
  String receiverUuid;
  String text;
  Timestamp timestamp;
  String? receiverName; 

  Message({
    this.id, // ID is now optional for new messages
    required this.senderUuid,
    required this.receiverUuid,
    required this.text,
    required this.timestamp,
    this.receiverName,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'senderUuid': senderUuid,
      'receiverUuid': receiverUuid,
      'text': text,
      'createdAt': timestamp.toDate().toIso8601String()
    };
    // Only include the ID if it's present (i.e., for updates or when fetching from DB)
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as int?, // Parse the ID as an integer
      senderUuid: map['senderUuid'],
      receiverUuid: map['receiverUuid'],
      text: map['text'],
      timestamp: Timestamp.fromDate(DateTime.parse(map['createdAt'])),
      receiverName: null, 
    );
  }
}
