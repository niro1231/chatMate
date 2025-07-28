import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> chat;

  ChatScreen({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  bool _isSearchMode = false;
  int _currentSearchIndex = -1;
  List<int> _searchMatchIndices = [];
  bool _isBlocked = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredMessages = List.from(messages);
        _searchMatchIndices.clear();
        _currentSearchIndex = -1;
      } else {
        _searchMatchIndices.clear();
        _filteredMessages = [];
        for (int i = 0; i < messages.length; i++) {
          final message = messages[i];
          if (message['text'].toString().toLowerCase().contains(query)) {
            _searchMatchIndices.add(i);
            _filteredMessages.add(message);
          }
        }
        if (_searchMatchIndices.isNotEmpty) {
          _currentSearchIndex = 0;
          _scrollToMessage(_searchMatchIndices[0]);
        }
      }
    });
  }

  void _scrollToMessage(int index) {
    if (_scrollController.hasClients) {
      final position = index * 80.0;
      _scrollController.animateTo(
        position,
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
        _filteredMessages = List.from(messages);
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
    setState(() {
      _messageController.text = _messageController.text + emoji;
    });
    // Move cursor to the end
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  void _loadMessages() {
    messages = [
      {
        'text': 'Hey, how are you doing?',
        'isMe': false,
        'time': '2:25 PM',
        'isRead': true,
      },
      {
        'text': 'I\'m doing great! Thanks for asking 😊',
        'isMe': true,
        'time': '2:26 PM',
        'isRead': true,
      },
      {
        'text': 'That\'s wonderful to hear!',
        'isMe': false,
        'time': '2:27 PM',
        'isRead': true,
      },
      {
        'text': 'How about you? How has your day been?',
        'isMe': true,
        'time': '2:28 PM',
        'isRead': true,
      },
      {
        'text': widget.chat['lastMessage'],
        'isMe': false,
        'time': widget.chat['time'],
        'isRead': false,
      },
    ];
    _filteredMessages = List.from(messages);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        'text': _messageController.text.trim(),
        'isMe': true,
        'time': _getCurrentTime(),
        'isRead': false,
      });
      _showEmojiPicker = false; // Hide emoji picker when sending message
    });

    _messageController.clear();

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

  String _getCurrentTime() {
    final now = DateTime.now();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
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
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
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
            child: Icon(widget.chat['avatar'], color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat['name'],
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
          } else if (value == 'clear') {
            _showClearChatDialog();
          }
        },
      ),
    ];
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message, [
    bool isHighlighted = false,
  ]) {
    final isMe = message['isMe'];
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
              child: Icon(widget.chat['avatar'], color: Colors.white, size: 16),
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
                          message['text'],
                          _searchController.text,
                        )
                      : Text(
                          message['text'],
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
                        message['time'],
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message['isRead'] ? Icons.done_all : Icons.done,
                          color: message['isRead']
                              ? Colors.blue
                              : Colors.white70,
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
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  messages.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat cleared'),
                    backgroundColor: Color(0xFFEA911D),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
    final List<String> emojis = [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🤩',
      '🥳',
      '😏',
      '😒',
      '😞',
      '😔',
      '😟',
      '😕',
      '🙁',
      '☹️',
      '😣',
      '😖',
      '😫',
      '😩',
      '🥺',
      '😢',
      '😭',
      '😤',
      '😠',
      '😡',
      '🤬',
      '🤯',
      '😳',
      '🥵',
      '🥶',
      '😱',
      '😨',
      '😰',
      '😥',
      '😓',
      '🤗',
      '🤔',
      '🤭',
      '🤫',
      '🤥',
      '😶',
      '😐',
      '😑',
      '😬',
      '🙄',
      '😯',
      '😦',
      '😧',
      '😮',
      '😲',
      '🥱',
      '😴',
      '🤤',
      '😪',
      '😵',
      '🤐',
      '🥴',
      '🤢',
      '🤮',
      '🤧',
      '😷',
      '🤒',
      '🤕',
      '🤑',
      '👍',
      '👎',
      '👌',
      '✌️',
      '🤞',
      '🤟',
      '🤘',
      '🤙',
      '👈',
      '👉',
      '👆',
      '👇',
      '☝️',
      '✋',
      '🤚',
      '🖐',
      '🖖',
      '👋',
      '🤏',
      '💪',
      '🦾',
      '🙏',
      '🤝',
      '👏',
      '👐',
      '🙌',
      '👊',
      '✊',
      '🤛',
      '🤜',
      '💎',
      '⭐',
      '🌟',
      '💫',
      '✨',
      '💥',
      '💢',
      '💦',
      '💨',
      '🔥',
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💔',
      '❤️‍🔥',
      '❤️‍🩹',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '🎉',
      '🎊',
      '🎈',
      '🎁',
    ];

    return Container(
      height: 250,
      color: const Color(0xFF303030),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF424242),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade600, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emojis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () {
                    setState(() {
                      _showEmojiPicker = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onEmojiSelected(emojis[index]),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
