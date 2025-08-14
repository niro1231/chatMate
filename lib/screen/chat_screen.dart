// ChatScreen.dart
import 'package:flutter/material.dart';
import 'package:chatme/modal/message.dart';
import 'package:chatme/modal/user.dart';
import 'package:chatme/database/MessageRepository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;

  const ChatScreen({super.key, required this.receiverId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final Repository _repo = Repository();
  User? _currentUser;
  User? _receiverUser;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final loggedInUser = await _repo.getLoggedInUser();
    final receiverUser = await _repo.getUserByUuid(widget.receiverId);
    setState(() {
      _currentUser = loggedInUser;
      _receiverUser = receiverUser;
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUser == null) return;

    final messageText = _messageController.text;
    _messageController.clear();

    final newMessage = Message(
      senderUuid: _currentUser!.uuid,
      receiverUuid: widget.receiverId,
      text: messageText,
      timestamp: Timestamp.now(),
    );

    // 1. Send to Firestore for real-time sync with other user
    await _repo.sendMessageToFirestore(newMessage);
    
    // 2. Insert into local database to update UI immediately
    await _repo.insertMessage(newMessage);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _receiverUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_receiverUser!.name),
        // ... (appbar design) ...
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _repo.getMessagesStreamForChat(_currentUser!.uuid, widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Start a new conversation!'));
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderUuid == _currentUser!.uuid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}