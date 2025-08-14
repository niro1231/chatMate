import 'package:chatme/modal/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  //get instance of firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // get user
  Stream<List<Map<String,dynamic>>> getUserStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();

        return user ;
      }).toList();
    });
  }
  // send msg
  Future<void> sendMessage(String receiverUuid, String text) async {
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderUuid: currentUserId,
      receiverUuid: receiverUuid,
      text: text,
      timestamp: timestamp,
    );

    List<String> ids = [currentUserId, receiverUuid];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore
      .collection('chat_rooms')
      .doc(chatRoomId)
      .collection("messages")
      .add(newMessage.toMap());
  }

  // get msg
  Stream<QuerySnapshot> getMessages(String userID, otherUserId) {
    List<String> ids = [userID, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
      .collection('chat_rooms')
      .doc(chatRoomId)
      .collection("messages")
      .orderBy('timestamp', descending: false)
      .snapshots();
  }
}
