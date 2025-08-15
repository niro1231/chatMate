// lib/screen/home_screen.dart

import 'package:flutter/material.dart';
import 'package:chatme/screen/chat_screen.dart';
import 'package:chatme/database/messagerepository.dart';
import 'package:chatme/modal/user.dart';
import 'package:intl/intl.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Repository _repository = Repository();
  late Stream<List<User>> _usersStream;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _usersStream = _repository.getUsersWithLastMessagesStream();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    
    _usersStream.first.then((allUsers) {
      setState(() {
        if (query.isEmpty) {
          _filteredUsers = List.from(allUsers);
        } else {
          _filteredUsers = allUsers.where((user) {
            final name = user.name.toLowerCase();
            final lastMessage = user.lastMessage?.toLowerCase() ?? '';
            return name.contains(query) || lastMessage.contains(query);
          }).toList();
        }
      });
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
                            _onSearchChanged(); 
                          });
                        } else {
                          _searchController.clear();
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
                Navigator.pushNamed(context, '/qr-scan');
              },
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = true;
                  _onSearchChanged();
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
            Navigator.pushNamed(context, '/plus');
          },
          backgroundColor: const Color(0xFFEA911D),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildChatsView() {
    return StreamBuilder<List<User>>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No chats yet.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        } else {
          final users = snapshot.data!;
          final displayedUsers = _searchController.text.isEmpty ? users : _filteredUsers;
          
          return ListView.builder(
            itemCount: displayedUsers.length,
            itemBuilder: (context, index) {
              final user = displayedUsers[index];
              return _buildChatTile(user);
            },
          );
        }
      },
    );
  }

  Widget _buildChatTile(User user) {
    return Container(
      color: Colors.grey.shade900,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade600,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          user.lastMessage ?? 'Start a conversation...',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              user.timestamp != null ? _formatTime(user.timestamp!) : '',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(receiverId: user.uuid!),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (timestamp.day == today.day && timestamp.month == today.month && timestamp.year == today.year) {
      return DateFormat.jm().format(timestamp);
    } else if (timestamp.day == yesterday.day && timestamp.month == yesterday.month && timestamp.year == yesterday.year) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yy').format(timestamp);
    }
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
                _repository.logout();
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