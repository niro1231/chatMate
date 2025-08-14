import 'package:sqflite/sqflite.dart';
import 'package:chatme/database/db-helper.dart';
import 'package:chatme/modal/user.dart';
import 'package:chatme/modal/message.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Repository {
  late DatabaseConnection _databaseConnection;
  Repository() {
    _databaseConnection = DatabaseConnection();
  }

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _databaseConnection.setDatabase();
    return _database!;
  }
  
  Future<void> createMessageTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        senderUuid TEXT,
        receiverUuid TEXT,
        text TEXT,
        createdAt TEXT,
        isRead INTEGER
      )
    ''');
  }

  Future<void> insertUser(User user) async {
    final db = await database;

    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    print('✅ New user inserted: ${user.email}');

    // Print all users in the table for verification
    final allUsers = await db.query('users');
    print('📦 All users in database:');
    for (var u in allUsers) {
      print(u);
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

  Future<void> updateUser(User user) async {
    final db = await database;

    await db.update(
      'users',
      user.toMap(),
      where: 'uuid = ?',
      whereArgs: [user.uuid],
    );
    print('✅ User updated: ID=${user.uuid}, New Name=${user.name}');
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
}
