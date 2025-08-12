class Message {
  int? id; // Changed from String uuid to int? id
  String senderUuid;
  String receiverUuid;
  String text;
  String createdAt;
  bool isRead;

  Message({
    this.id, // ID is now optional for new messages
    required this.senderUuid,
    required this.receiverUuid,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'senderUuid': senderUuid,
      'receiverUuid': receiverUuid,
      'text': text,
      'createdAt': createdAt,
      'isRead': isRead ? 1 : 0,
    };
    // Only include the ID if it's present (i.e., for updates or when fetching from DB)
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as int, // Parse the ID as an integer
      senderUuid: map['senderUuid'],
      receiverUuid: map['receiverUuid'],
      text: map['text'],
      createdAt: map['createdAt'],
      isRead: map['isRead'] == 1,
    );
  }
}
