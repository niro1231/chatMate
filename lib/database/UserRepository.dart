import 'package:sqflite/sqflite.dart';
import 'package:chatme/database/db-helper.dart';
import 'package:chatme/modal/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class Repository {
  late DatabaseConnection _databaseConnection;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Repository() {
    _databaseConnection = DatabaseConnection();
  }

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _databaseConnection.setDatabase();
    return _database!;
  }

  Future<void> insertUser(User user) async {
    try {
      // 1. Insert into local SQLite database
      final db = await database;
      await db.insert('users', user.toMap());
      print('✅ New user inserted locally: ${user.email}');

      // 2. Insert into Firestore for global access
      await _firestore.collection('users').doc(user.uuid).set(user.toMap());
      print('✅ New user created in Firestore: ${user.email}');

      // Print all users in the local table for verification
      final allUsers = await db.query('users');
      print('📦 All users in local database:');
      for (var u in allUsers) {
        print(u);
      }
    } catch (e) {
      print('❌ Error creating user: $e');
      rethrow;
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

  // Get user from Firestore by UUID (useful for QR code scanning)
  Future<User?> getUserFromFirestoreByUuid(String uuid) async {
    try {
      final doc = await _firestore.collection('users').doc(uuid).get();
      if (doc.exists && doc.data() != null) {
        final user = User.fromMap(doc.data()!);
        print('✅ User found in Firestore: ${user.email}');
        
        // Also save to local database for offline access
        final db = await database;
        await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        
        return user;
      }
      print('⚠️ No user found in Firestore with UUID: $uuid');
      return null;
    } catch (e) {
      print('❌ Error getting user from Firestore: $e');
      return null;
    }
  }

  // Sync all users from Firestore to local database
  Future<void> syncUsersFromFirestore() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final db = await database;
      
      for (var doc in snapshot.docs) {
        final user = User.fromMap(doc.data());
        await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      print('✅ Synced ${snapshot.docs.length} users from Firestore');
    } catch (e) {
      print('❌ Error syncing users from Firestore: $e');
    }
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

  Future<User?> getLoggedInUser() async {
    final email = await getLoggedInEmail();
    if (email != null) {
      return await getUserByEmail(email);
    }
    return null;
  }
}
