// Home Screen
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../database/UserRepository.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> _filteredChats = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final Repository _repository = Repository();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContactsFromDatabase();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadContactsFromDatabase() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current logged-in user
      final currentUser = await _repository.getLoggedInUser();
      if (currentUser == null) {
        print('❌ No logged-in user found');
        setState(() {
          chats = [];
          _filteredChats = [];
          _isLoading = false;
        });
        return;
      }

      // Get all users except the current user
      final contacts = await _repository.getAllUsersExceptCurrent(
        currentUser.email,
      );

      // Convert users to chat format
      final List<Map<String, dynamic>> contactChats = contacts.map((user) {
        return {
          'name': user.name,
          'lastMessage':
              user.about, // Using 'about' as placeholder for last message
          'time': _formatTime(DateTime.parse(user.updatedAt)),
          'unreadCount':
              0, // Default to 0, can be updated with message logic later
          'avatar': Icons.person,
          'userId': user.uuid,
          'email': user.email,
          'profileImagePath': user.profileImagePath,
        };
      }).toList();

      setState(() {
        chats = contactChats;
        _filteredChats = List.from(chats);
        _isLoading = false;
      });

      print('✅ Loaded ${contacts.length} contacts from database');
    } catch (e) {
      print('❌ Error loading contacts: $e');
      setState(() {
        chats = [];
        _filteredChats = [];
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final contactDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (contactDate == today) {
      // Same day, show time
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } else {
      // Different day, show date
      return '${dateTime.month}/${dateTime.day}';
    }
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
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var chat in chats) {
        chat['unreadCount'] = 0;
      }
      _filteredChats = List.from(chats);
    });
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
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/qr-scan',
                ); // Navigate to QR scan page
              },
            ),

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
                              Text(
                                'Settings',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'read_all',
                          child: Row(
                            children: const [
                              Icon(Icons.mark_email_read, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                'Read All',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: const [
                              Icon(Icons.logout, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                'Logout',
                                style: TextStyle(color: Colors.white),
                              ),
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
          onPressed: () async {
            final result = await Navigator.pushNamed(context, '/plus');
            // Refresh contacts when returning from add contact screen
            if (result == true) {
              _loadContactsFromDatabase();
            }
          },
          backgroundColor: const Color(0xFFEA911D),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildChatsView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA911D)),
        ),
      );
    }

    if (_filteredChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No contacts found',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Add contacts to start chatting',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

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
          backgroundImage: chat['profileImagePath'] != null
              ? FileImage(File(chat['profileImagePath']))
              : null,
          child: chat['profileImagePath'] == null
              ? Icon(chat['avatar'], color: Colors.white, size: 30)
              : null,
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
            final originalChatIndex = chats.indexWhere(
              (c) => c['userId'] == chat['userId'],
            );
            if (originalChatIndex != -1) {
              chats[originalChatIndex]['unreadCount'] = 0;
            }
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
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
