import 'package:flutter/material.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> chats = [
    {
      'name': 'John Doe',
      'lastMessage': 'Hey, how are you doing?',
      'time': '2:30 PM',
      'unreadCount': 2,
      'avatar': Icons.person,
    },
    {
      'name': 'Sarah Wilson',
      'lastMessage': 'Thanks for the help!',
      'time': '1:15 PM',
      'unreadCount': 0,
      'avatar': Icons.person_2,
    },
    {
      'name': 'Mike Johnson',
      'lastMessage': 'See you tomorrow',
      'time': '12:45 PM',
      'unreadCount': 1,
      'avatar': Icons.person_3,
    },
    {
      'name': 'Emily Davis',
      'lastMessage': 'Good morning!',
      'time': '10:20 AM',
      'unreadCount': 0,
      'avatar': Icons.person_4,
    },
  ];

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredChats = [];

  @override
  void initState() {
    super.initState();
    _sortChatsByTime();
    _filteredChats = List.from(chats);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredChats = List.from(chats);
      } else {
        _filteredChats = chats.where((chat) {
          final name = chat['name'].toString().toLowerCase();
          final lastMessage = chat['lastMessage'].toString().toLowerCase();
          return name.contains(query) || lastMessage.contains(query);
        }).toList();
      }
      _filteredChats.sort((a, b) =>
          _parseChatTime(b['time']).compareTo(_parseChatTime(a['time'])));
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var chat in chats) {
        chat['unreadCount'] = 0;
      }
      _sortChatsByTime();
      _filteredChats = List.from(chats);
    });
  }

  DateTime _parseChatTime(String timeStr) {
    final now = DateTime.now();
    final format = RegExp(r'(\d{1,2}):(\d{2})\s?(AM|PM)', caseSensitive: false);
    final match = format.firstMatch(timeStr);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final int minute = int.parse(match.group(2)!);
      final String meridiem = match.group(3)!.toUpperCase();
      if (meridiem == 'PM' && hour != 12) hour += 12;
      if (meridiem == 'AM' && hour == 12) hour = 0;
      return DateTime(now.year, now.month, now.day, hour, minute);
    }
    return now;
  }

  void _sortChatsByTime() {
    chats.sort(
        (a, b) => _parseChatTime(b['time']).compareTo(_parseChatTime(a['time'])));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF212121),
        appBar: AppBar(
          backgroundColor: const Color(0xFF424242),
          elevation: 1,
          automaticallyImplyLeading: false,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFFEA911D),
                  decoration: InputDecoration(
                    hintText: 'Search chats...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        if (_searchController.text.isEmpty) {
                          setState(() {
                            _isSearching = false;
                            _filteredChats = List.from(chats);
                          });
                        } else {
                          _searchController.clear();
                          setState(() {
                            _filteredChats = List.from(chats);
                          });
                        }
                      },
                    ),
                  ),
                )
              : const Text(
                  'ChatMate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = true;
                  if (_searchController.text.isEmpty) {
                    _filteredChats = List.from(chats);
                  }
                });
              },
              icon: const Icon(Icons.search, color: Colors.white),
            ),
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () async {
                    final RenderBox overlay =
                        Overlay.of(context).context.findRenderObject()
                            as RenderBox;
                    final RenderBox button =
                        context.findRenderObject() as RenderBox;
                    final Offset position = button.localToGlobal(
                      Offset.zero,
                      ancestor: overlay,
                    );

                    final result = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        position.dx,
                        position.dy + 60,
                        0,
                        0,
                      ),
                      color: const Color.fromARGB(255, 83, 83, 83),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      items: [
                        PopupMenuItem<String>(
                          value: 'settings',
                          child: Row(
                            children: const [
                              Icon(Icons.settings, color: Colors.white),
                              SizedBox(width: 10),
                              Text('Settings',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'read_all',
                          child: Row(
                            children: const [
                              Icon(Icons.mark_email_read, color: Colors.white),
                              SizedBox(width: 10),
                              Text('Read All',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: const [
                              Icon(Icons.logout, color: Colors.white),
                              SizedBox(width: 10),
                              Text('Logout',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (result == 'settings') {
                      Navigator.pushNamed(context, '/settings');
                    } else if (result == 'read_all') {
                      _markAllAsRead();
                    } else if (result == 'logout') {
                      _showLogoutDialog();
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: _buildChatsView(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/qr-system');
          },
          backgroundColor: const Color(0xFFEA911D),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildChatsView() {
    return ListView.builder(
      itemCount: _filteredChats.length,
      itemBuilder: (context, index) {
        final chat = _filteredChats[index];
        return _buildChatTile(chat);
      },
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    return Container(
      color: Colors.grey.shade900,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade600,
          child: Icon(chat['avatar'], color: Colors.white, size: 30),
        ),
        title: Text(
          chat['name'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          chat['lastMessage'],
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              chat['time'],
              style: TextStyle(
                color: chat['unreadCount'] > 0
                    ? const Color(0xFFEA911D)
                    : Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            if (chat['unreadCount'] > 0)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFEA911D),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  chat['unreadCount'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          setState(() {
            chat['unreadCount'] = 0;
            final originalChatIndex =
                chats.indexWhere((c) => c['name'] == chat['name']);
            if (originalChatIndex != -1) {
              chats[originalChatIndex]['unreadCount'] = 0;
            }
            _sortChatsByTime();
            _filteredChats = List.from(chats);
          });

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen(chat: chat)),
          );
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA911D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
