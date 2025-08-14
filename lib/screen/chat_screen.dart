import 'package:chatme/modal/message.dart';
import 'package:chatme/services/auth_service.dart';
import 'package:chatme/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
// import 'package:chatme/database/UserRepository.dart'; 
import 'package:chatme/database/MessageRepository.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp
import 'package:chatme/modal/user.dart'; // Import the User model

class ChatScreen extends StatefulWidget {
  final String receiverId;

  const ChatScreen({super.key, required this.receiverId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ChatService _chatService = ChatService();
  final Repository _repository = Repository();

  String _receiverName = 'Loading...';
  IconData _receiverAvatar = Icons.person;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _fetchReceiverDetails();
  }

  void _fetchReceiverDetails() async {
    final user = await _repository.getUserByUuid(widget.receiverId);
    if (user != null) {
      setState(() {
        _receiverName = user.name;
        // Assuming your User model has an avatar property of type IconData
        _receiverAvatar = _receiverAvatar;
      });
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _onEmojiSelected(Emoji emoji) {
    _messageController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = await _repository.getLoggedInUser();
    if (currentUser == null) return;

    final newMessage = Message(
      senderUuid: currentUser.uuid,
      receiverUuid: widget.receiverId,
      text: _messageController.text,
      // Correct way to get a Timestamp from a DateTime
      timestamp: Timestamp.fromDate(DateTime.now()),
    );

    await _repository.insertMessage(newMessage);
    _messageController.clear();
  }

  Widget _buildMessageList() {
    return FutureBuilder<User?>(
      future: _repository.getLoggedInUser(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data == null) {
          return const Center(child: Text('User not logged in.'));
        }

        final currentUserUuid = userSnapshot.data!.uuid;

        return StreamBuilder<List<Message>>(
          stream: _repository.getMessagesStreamForChat(currentUserUuid, widget.receiverId),
          builder: (context, messagesSnapshot) {
            if (messagesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (messagesSnapshot.hasError) {
              return Center(child: Text('Error: ${messagesSnapshot.error}'));
            }
            if (!messagesSnapshot.hasData || messagesSnapshot.data!.isEmpty) {
              return const Center(child: Text('No messages yet.'));
            }

            final messages = messagesSnapshot.data!;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });

            return ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageBubble(message, currentUserUuid);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message, String currentUserUuid) {
    final isMe = message.senderUuid == currentUserUuid;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFEA911D) : Colors.grey.shade700,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF424242),
        elevation: 1,
        title: _buildChatTitle(),
        actions: const [],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
          if (_showEmojiPicker) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildChatTitle() {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF757575),
          child: Icon(_receiverAvatar, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _receiverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'Online',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        border: Border(
          top: BorderSide(color: Colors.grey.shade600, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
              color: _showEmojiPicker
                  ? const Color(0xFFEA911D)
                  : Colors.grey.shade400,
            ),
            onPressed: _toggleEmojiPicker,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              cursorColor: const Color(0xFFEA911D),
              onTap: () {
                if (_showEmojiPicker) {
                  setState(() => _showEmojiPicker = false);
                }
              },
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            backgroundColor: const Color(0xFFEA911D),
            onPressed: _sendMessage,
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 256,
      child: EmojiPicker(
        onEmojiSelected: (Category? category, Emoji emoji) {
          _onEmojiSelected(emoji);
        },
        textEditingController: _messageController,
      ),
    );
  }
}