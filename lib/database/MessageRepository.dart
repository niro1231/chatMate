// repository.dart
import 'package:sqflite/sqflite.dart';
import 'package:chatme/database/db-helper.dart';
import 'package:chatme/modal/user.dart';
import 'package:chatme/modal/message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stream_transform/stream_transform.dart';

class Repository {
  late DatabaseConnection _databaseConnection;
  Repository() {
    _databaseConnection = DatabaseConnection();
  }

  static Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // New StreamController to emit the list of users with their last messages
  final _usersWithLastMessageController = StreamController<List<User>>.broadcast();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _databaseConnection.setDatabase();
    return _database!;
  }
  
  final _messagesController = StreamController<List<Message>>.broadcast();

  // Updated method to send messages to Firestore and trigger a UI update
  Future<void> sendMessageToFirestore(Message message) async {
    await _firestore.collection('messages').add(message.toMap());
    print('✅ Message sent to Firestore: ${message.text}');
    _updateAllUsersWithLastMessages(); // Trigger update after sending
  }

  // A stream of all users with their latest messages, for the home screen
  Stream<List<User>> getUsersWithLastMessagesStream() {
    _firestore
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _updateAllUsersWithLastMessages();
        });
    _updateAllUsersWithLastMessages(); // Initial fetch
    return _usersWithLastMessageController.stream;
  }
  
  // Method to fetch all users and their last messages from local database
  Future<void> _updateAllUsersWithLastMessages() async {
    final currentUser = await getLoggedInUser();
    if (currentUser == null) {
      _usersWithLastMessageController.add([]);
      return;
    }

    final db = await database;
    final List<Map<String, dynamic>> userMaps = await db.query('users', where: 'uuid != ?', whereArgs: [currentUser.uuid]);
    final List<User> users = userMaps.map((userMap) => User.fromMap(userMap)).toList();
    
    for (var user in users) {
      final lastMessage = await getLastMessageWithUser(user.uuid!);
      if (lastMessage != null) {
        user.lastMessage = lastMessage.text;
        user.timestamp = lastMessage.createdAt;
      }
    }
    
    users.sort((a, b) => (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));
    _usersWithLastMessageController.add(users);
  }

  Stream<List<Message>> getMessagesStreamForChat(String userUuid, String contactUuid) {
    // 1. Listen for real-time changes from Firestore
    _firestore
        .collection('messages')
        .where('senderUuid', isEqualTo: userUuid)
        .where('receiverUuid', isEqualTo: contactUuid)
        .orderBy('createdAt') // Use consistent field name
        .snapshots()
        .listen((snapshot) async {
      final newMessages = snapshot.docs.map((doc) {
        final data = doc.data();
        return Message.fromMap(data); // Use the fromMap factory
      }).toList();

      // 2. Process and update local database with new messages from Firestore
      for (var message in newMessages) {
        final db = await database;
        await insertMessage(message); // Insert new messages locally
      }

      // 3. After syncing with Firestore, fetch and emit all messages from local DB
      _fetchAndSendMessages(userUuid, contactUuid);
    });

    // Initial fetch to populate the stream immediately
    _fetchAndSendMessages(userUuid, contactUuid);
    return _messagesController.stream;
  }

  Future<void> _fetchAndSendMessages(String userUuid, String contactUuid) async {
    final messages = await getMessagesForChat(userUuid, contactUuid);
    _messagesController.add(messages);
  }
  
  Future<User?> getUserByEmail(String email) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      final user = User.fromMap(result.first);
      print('✅ User found: ID=${user.uuid}, Email=${user.email}');
      return user;
    }
    
    print('⚠️ No user found with email: $email');
    return null;
  }

  Future<User?> getUserByUuid(String uuid) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    if (result.isNotEmpty) {
      final user = User.fromMap(result.first);
      print('✅ User found by UUID: ID=${user.uuid}');
      return user;
    }

    print('⚠️ No user found with UUID: $uuid');
    return null;
  }
  
  Future<User?> getLoggedInUser() async {
    final email = await getLoggedInEmail();
    if (email != null) {
      return await getUserByEmail(email);
    }
    return null;
  }

  Future<void> setLoggedIn(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInEmail', email);
  }
  
  Future<String?> getLoggedInEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loggedInEmail');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInEmail');
  }

  Future<void> insertMessage(Message message) async {
    final db = await database;
    // We no longer pass the ID, as it's auto-generated
    await db.insert('messages', message.toMap());
    print('✅ New message inserted: ${message.text}');
  }

  Future<List<Message>> getMessagesForChat(String userUuid, String contactUuid) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: '(senderUuid = ? AND receiverUuid = ?) OR (senderUuid = ? AND receiverUuid = ?)',
      whereArgs: [userUuid, contactUuid, contactUuid, userUuid],
      orderBy: 'createdAt ASC',
    );
    return result.map((map) => Message.fromMap(map)).toList();
  }

  Future<void> clearChat(String userUuid, String contactUuid) async {
    final db = await database;
    await db.delete(
      'messages',
      where: '(senderUuid = ? AND receiverUuid = ?) OR (senderUuid = ? AND receiverUuid = ?)',
      whereArgs: [userUuid, contactUuid, contactUuid, userUuid],
    );
  }


  Future<Message?> getLastMessageWithUser(String otherUserUuid) async {
    final currentUser = await getLoggedInUser();
    if (currentUser == null) return null;

    final db = await database;
    final result = await db.query(
      'messages',
      where: '(senderUuid = ? AND receiverUuid = ?) OR (senderUuid = ? AND receiverUuid = ?)',
      whereArgs: [currentUser.uuid, otherUserUuid, otherUserUuid, currentUser.uuid],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Message.fromMap(result.first);
    }
    return null;
  }

}