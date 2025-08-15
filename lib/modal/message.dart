class Message {
  String? id; // Changed to String for Firestore document ID
  String senderUuid;
  String receiverUuid;
  String text;
  DateTime? createdAt; // Changed to DateTime for consistency
  String? receiverName; 

  Message({
    this.id, // ID is optional for new messages
    required this.senderUuid,
    required this.receiverUuid,
    required this.text,
    this.createdAt,
    this.receiverName,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'senderUuid': senderUuid,
      'receiverUuid': receiverUuid,
      'text': text,
      'createdAt': createdAt?.millisecondsSinceEpoch, // Store as timestamp
    };
    // Only include the ID if it's present (i.e., for updates or when fetching from DB)
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String?,
      senderUuid: map['senderUuid'] ?? '',
      receiverUuid: map['receiverUuid'] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      receiverName: map['receiverName'], 
    );
  }
}
