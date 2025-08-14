import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatme/database/MessageRepository.dart';
import 'package:chatme/modal/user.dart';
import 'package:chatme/modal/message.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Repository _repo = Repository();

  late String _userUuid;
  late String _contactUuid;

  List<Message> _messages = [];
  bool _isSearchMode = false;
  int _currentSearchIndex = -1;
  List<int> _searchMatchIndices = [];
  bool _isBlocked = false;
  bool _showEmojiPicker = false;
  Timer? _realtimeTimer;
  Color _backgroundColor = const Color(0xFF212121); // Default background color

  @override
  void initState() {
    super.initState();
    _loadChatData();
    _loadBackgroundColor();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadChatData() async {
    final User? loggedInUser = await _repo.getLoggedInUser();

    if (loggedInUser != null) {
      _userUuid = loggedInUser.uuid;
      _contactUuid = widget.chat['uuid'] as String;

      // Ensure the messages table is created
      await _repo.createMessageTable();
      await _loadMessages();
      _setupRealtimeListener();
    } else {
      // Handle the case where no user is logged in
      if (mounted) {
        // Pop back to a login screen or show an error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadBackgroundColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('chat_wallpaper_color');
    if (colorValue != null && mounted) {
      setState(() {
        _backgroundColor = Color(colorValue);
      });
    }
  }

  Future<void> _loadMessages() async {
    final fetchedMessages = await _repo.getMessagesForChat(
      _userUuid,
      _contactUuid,
    );
    if (mounted) {
      setState(() {
        _messages = fetchedMessages;
      });
      _scrollToBottom();
    }
  }

  void _setupRealtimeListener() {
    // This is a mock real-time listener using a Timer.
    // In a real app, you would use a WebSocket or a service like Firebase Firestore
    _realtimeTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final mockMessage = Message(
        senderUuid: _contactUuid,
        receiverUuid: _userUuid,
        text:
            "This is a simulated message from ${_contactUuid.substring(0, 8)}!",
        createdAt: DateTime.now().toIso8601String(),
        isRead: false,
      );
      await _repo.insertMessage(mockMessage);
      if (mounted) {
        setState(() {
          _messages.add(mockMessage);
        });
        _scrollToBottom();
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _searchMatchIndices.clear();
        _currentSearchIndex = -1;
      } else {
        _searchMatchIndices = _messages
            .where((message) => message.text.toLowerCase().contains(query))
            .map((message) => _messages.indexOf(message))
            .toList();
        if (_searchMatchIndices.isNotEmpty) {
          _currentSearchIndex = 0;
          _scrollToMessage(_searchMatchIndices[0]);
        }
      }
    });
  }

  void _scrollToMessage(int index) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        index * 80.0, // This is an approximation
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextSearchResult() {
    if (_searchMatchIndices.isNotEmpty) {
      setState(() {
        _currentSearchIndex =
            (_currentSearchIndex + 1) % _searchMatchIndices.length;
        _scrollToMessage(_searchMatchIndices[_currentSearchIndex]);
      });
    }
  }

  void _previousSearchResult() {
    if (_searchMatchIndices.isNotEmpty) {
      setState(() {
        _currentSearchIndex =
            (_currentSearchIndex - 1 + _searchMatchIndices.length) %
            _searchMatchIndices.length;
        _scrollToMessage(_searchMatchIndices[_currentSearchIndex]);
      });
    }
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _searchMatchIndices.clear();
        _currentSearchIndex = -1;
      }
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _onEmojiSelected(String emoji) {
    _messageController.text += emoji;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = Message(
      senderUuid: _userUuid,
      receiverUuid: _contactUuid,
      text: _messageController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    await _repo.insertMessage(newMessage);

    if (mounted) {
      setState(() {
        _messages.add(newMessage);
        _showEmojiPicker = false;
      });
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getCurrentTime(String dateTimeString) {
    final now = DateTime.parse(dateTimeString);
    final hour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _realtimeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF424242),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isSearchMode) {
              _toggleSearchMode();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: _isSearchMode ? _buildSearchBar() : _buildChatTitle(),
        actions: _isSearchMode ? _buildSearchActions() : _buildChatActions(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isHighlighted =
                    _isSearchMode &&
                    _searchMatchIndices.contains(index) &&
                    _currentSearchIndex != -1 &&
                    _searchMatchIndices[_currentSearchIndex] == index;
                return _buildMessageBubble(message, isHighlighted);
              },
            ),
          ),
          _isBlocked ? _buildBlockedMessage() : _buildMessageInput(),
          if (_showEmojiPicker && !_isBlocked) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: const Color(0xFFEA911D),
            decoration: InputDecoration(
              hintText: 'Search messages...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
            ),
          ),
        ),
        if (_searchMatchIndices.isNotEmpty) ...[
          Text(
            '${_currentSearchIndex + 1}/${_searchMatchIndices.length}',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _previousSearchResult,
          ),
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _nextSearchResult,
          ),
        ],
      ],
    );
  }

  Widget _buildChatTitle() {
    final name =
        widget.chat['name'] as String? ??
        widget.chat['email'] ??
        'Unknown User';
    final avatarIcon = widget.chat['avatar'] ?? Icons.person;
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          '/contact-profile',
          arguments: widget.chat,
        );
        if (result != null && result is Map<String, dynamic>) {
          if (result['action'] == 'block') {
            setState(() {
              _isBlocked = true;
            });
          }
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF757575),
            child: Icon(avatarIcon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSearchActions() {
    return [
      IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: _toggleSearchMode,
      ),
    ];
  }

  List<Widget> _buildChatActions() {
    return [
      IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: _toggleSearchMode,
      ),
      IconButton(
        icon: const Icon(Icons.person_add, color: Colors.white),
        onPressed: () {
          _showAddContactDialog();
        },
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        color: const Color(0xFF424242),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        offset: const Offset(0, 55),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'view_contact',
            child: Text(
              'View contact',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const PopupMenuItem(
            value: 'wallpaper',
            child: Text(
              'Wallpaper',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const PopupMenuItem(
            value: 'clear',
            child: Text(
              'Clear chat',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
        onSelected: (value) async {
          if (value == 'view_contact') {
            final result = await Navigator.pushNamed(
              context,
              '/contact-profile',
              arguments: widget.chat,
            );
            if (result != null && result is Map<String, dynamic>) {
              if (result['action'] == 'block') {
                setState(() {
                  _isBlocked = true;
                });
              }
            }
          } else if (value == 'wallpaper') {
            final result = await Navigator.pushNamed(context, '/wallpaper');
            if (result != null && result is Map<String, dynamic>) {
              if (result['color'] != null) {
                setState(() {
                  _backgroundColor = result['color'] as Color;
                });
              }
            }
          } else if (value == 'clear') {
            _showClearChatDialog();
          }
        },
      ),
    ];
  }

  Widget _buildMessageBubble(Message message, [bool isHighlighted = false]) {
    final isMe = message.senderUuid == _userUuid;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: isHighlighted
          ? BoxDecoration(
              color: const Color(0x33EA911D),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      padding: isHighlighted ? const EdgeInsets.all(8) : null,
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade600,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFEA911D) : Colors.grey.shade700,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isSearchMode && _searchController.text.isNotEmpty
                      ? _buildHighlightedText(
                          message.text,
                          _searchController.text,
                        )
                      : Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getCurrentTime(message.createdAt),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          color: message.isRead ? Colors.blue : Colors.white70,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFEA911D),
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty)
      return Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      );

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    int start = 0;
    int index = lowerText.indexOf(lowerQuery, start);

    while (index != -1) {
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.yellow,
          ),
        ),
      );

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
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
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(25),
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
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onTap: () {
                        if (_showEmojiPicker) {
                          setState(() {
                            _showEmojiPicker = false;
                          });
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
                  IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.grey.shade400),
                    onPressed: _showAttachmentOptions,
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.grey.shade400),
                    onPressed: () {},
                  ),
                ],
              ),
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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF303030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAttachmentOption(Icons.insert_drive_file, 'Document'),
              _buildAttachmentOption(Icons.photo, 'Photo'),
              _buildAttachmentOption(Icons.videocam, 'Video'),
              _buildAttachmentOption(Icons.audiotrack, 'Audio'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label option tapped'),
            backgroundColor: const Color(0xFFEA911D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Clear chat',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to clear this chat? This action cannot be undone.',
            style: TextStyle(color: Colors.grey.shade300),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _repo.clearChat(_userUuid, _contactUuid);
                if (mounted) {
                  setState(() {
                    _messages.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat cleared'),
                      backgroundColor: Color(0xFFEA911D),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear chat'),
            ),
          ],
        );
      },
    );
  }

  void _showAddContactDialog() {
    final name =
        widget.chat['name'] as String? ??
        widget.chat['email'] ??
        'Unknown User';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Contact',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Do you want to add $name to your contacts?',
            style: TextStyle(color: Colors.grey.shade300),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Add contact logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name added to your contacts'),
                    backgroundColor: const Color(0xFFEA911D),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA911D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add Contact'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlockedMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade900,
      child: const Center(
        child: Text(
          'You blocked this contact.',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 256,
      child: EmojiPicker(
        onEmojiSelected: (Category? category, Emoji emoji) {
          _onEmojiSelected(emoji.emoji);
        },
        textEditingController: _messageController,
      ),
    );
  }
}
