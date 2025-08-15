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
  
  // Map to store separate controllers for each chat
  final Map<String, StreamController<List<Message>>> _chatControllers = {};

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _databaseConnection.setDatabase();
    return _database!;
  }

  // Updated method to send messages to Firestore and trigger a UI update
  Future<void> sendMessageToFirestore(Message message) async {
    try {
      print('🚀 Sending message to Firestore: ${message.text}');
      print('📤 From: ${message.senderUuid} To: ${message.receiverUuid}');
      print('🔑 Message ID will be: ${message.id}');
      
      // Save to local database first
      await insertMessage(message);
      print('💾 Message saved to local database');
      
      // Use the specific Firestore map method
      final firestoreData = message.toFirestoreMap();
      print('📦 Firestore data: $firestoreData');
      
      final docRef = await _firestore.collection('messages').add(firestoreData);
      print('✅ Message sent to Firestore with doc ID: ${docRef.id}');
      
      _updateAllUsersWithLastMessages(); // Trigger update after sending
    } catch (e) {
      print('❌ Error sending message to Firestore: $e');
      rethrow; // Re-throw to let caller handle the error
    }
  }

  // A stream of all users with their latest messages, for the home screen
  Stream<List<User>> getUsersWithLastMessagesStream() {
    _firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
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
        user.timestamp = lastMessage.timestamp.toDate();
      }
    }
    
    users.sort((a, b) => (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));
    _usersWithLastMessageController.add(users);
  }

  Stream<List<Message>> getMessagesStreamForChat(String userUuid, String contactUuid) {
    print('🔄 Setting up message stream for chat: $userUuid <-> $contactUuid');
    
    // Create a unique key for this chat
    final chatKey = _getChatKey(userUuid, contactUuid);
    print('🔑 Chat key: $chatKey');
    
    // Create or get existing controller for this specific chat
    if (!_chatControllers.containsKey(chatKey)) {
      _chatControllers[chatKey] = StreamController<List<Message>>.broadcast();
      print('📺 Created new controller for chat: $chatKey');
    } else {
      print('♻️ Reusing existing controller for chat: $chatKey');
    }
    
    // Listen for messages in BOTH directions for real-time chat
    
    // 1. Listen for messages FROM userUuid TO contactUuid (outgoing messages)
    print('📡 Setting up listener for outgoing messages: $userUuid -> $contactUuid');
    _firestore
        .collection('messages')
        .where('senderUuid', isEqualTo: userUuid)
        .where('receiverUuid', isEqualTo: contactUuid)
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) async {
      print('📨 Outgoing messages snapshot received: ${snapshot.docs.length} docs');
      await _processFirestoreMessages(snapshot);
      _fetchAndSendMessages(userUuid, contactUuid);
    });

    // 2. Listen for messages FROM contactUuid TO userUuid (incoming messages)
    print('📡 Setting up listener for incoming messages: $contactUuid -> $userUuid');
    _firestore
        .collection('messages')
        .where('senderUuid', isEqualTo: contactUuid)
        .where('receiverUuid', isEqualTo: userUuid)
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) async {
      print('📬 Incoming messages snapshot received: ${snapshot.docs.length} docs');
      await _processFirestoreMessages(snapshot);
      _fetchAndSendMessages(userUuid, contactUuid);
    });

    // Initial fetch to populate the stream immediately
    _fetchAndSendMessages(userUuid, contactUuid);
    return _chatControllers[chatKey]!.stream;
  }

  // Create consistent chat key regardless of user order
  String _getChatKey(String userUuid, String contactUuid) {
    final users = [userUuid, contactUuid]..sort();
    return '${users[0]}_${users[1]}';
  }

  // Helper method to process Firestore messages
  Future<void> _processFirestoreMessages(QuerySnapshot snapshot) async {
    print('🔍 Processing Firestore messages: ${snapshot.docs.length} docs');
    
    final newMessages = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      print('📄 Processing message doc ID: ${doc.id}, data: $data');
      return Message.fromMap(data);
    }).toList();

    print('✅ Created ${newMessages.length} Message objects from Firestore');

    // Process and update local database with new messages from Firestore
    for (var message in newMessages) {
      print('💾 Inserting message to local DB: ${message.text} (${message.senderUuid} -> ${message.receiverUuid})');
      await _insertMessageIfNotExists(message);
    }
  }

  // Helper method to avoid duplicate messages
  Future<void> _insertMessageIfNotExists(Message message) async {
    try {
      final db = await database;
      
      // Check if message already exists to avoid duplicates
      final existing = await db.query(
        'messages',
        where: 'senderUuid = ? AND receiverUuid = ? AND text = ? AND createdAt = ?',
        whereArgs: [
          message.senderUuid,
          message.receiverUuid,
          message.text,
          message.timestamp.toDate().toIso8601String(),
        ],
        limit: 1,
      );
      
      if (existing.isEmpty) {
        await db.insert('messages', message.toMap());
        print('✅ New message synced from Firestore: ${message.text}');
      } else {
        print('⏭️ Message already exists in local DB: ${message.text}');
      }
    } catch (e) {
      print('❌ Error inserting message from Firestore: $e');
    }
  }

  Future<void> _fetchAndSendMessages(String userUuid, String contactUuid) async {
    final chatKey = _getChatKey(userUuid, contactUuid);
    print('📊 Fetching messages for chat: $chatKey ($userUuid <-> $contactUuid)');
    
    final messages = await getMessagesForChat(userUuid, contactUuid);
    print('📨 Found ${messages.length} messages in local DB for chat');
    
    if (messages.isNotEmpty) {
      print('💬 Latest message: ${messages.last.text} at ${messages.last.timestamp.toDate()}');
    }
    
    final controller = _chatControllers[chatKey];
    if (controller != null) {
      controller.add(messages);
      print('✅ Messages sent to stream controller for chat: $chatKey');
    } else {
      print('❌ No controller found for chat: $chatKey');
    }
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