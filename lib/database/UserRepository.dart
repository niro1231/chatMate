import 'package:sqflite/sqflite.dart';
import 'package:chatme/database/db-helper.dart';
import 'package:chatme/modal/user.dart';
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

  Future<void> insertUser(User user) async {
    final db = await database;

    await db.insert('users', user.toMap());
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

    // Ensure about column exists before querying
    await _ensureAboutColumnExists();
    await _ensureProfileImagePathColumnExists();

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      final user = User.fromMap(result.first);
      print(
        '✅ User found: ID=${user.uuid}, Email=${user.email}, About=${user.about}',
      );
      return user;
    }

    print('⚠️ No user found with email: $email');
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

  Future<User?> getLoggedInUser() async {
    final email = await getLoggedInEmail();
    if (email != null) {
      return await getUserByEmail(email);
    }
    return null;
  }

  Future<void> _ensureAboutColumnExists() async {
    final db = await database;

    try {
      // Check if the about column exists
      final result = await db.rawQuery("PRAGMA table_info(users)");
      final columnExists = result.any((column) => column['name'] == 'about');

      if (!columnExists) {
        print('🔧 Adding missing about column...');
        await db.execute('''
          ALTER TABLE users ADD COLUMN about TEXT DEFAULT 'Available'
        ''');
        print('✅ About column added successfully');
      } else {
        print('ℹ️ About column already exists');
      }
    } catch (e) {
      print('❌ Error checking/adding about column: $e');
      rethrow;
    }
  }

  Future<void> _ensureProfileImagePathColumnExists() async {
    final db = await database;

    try {
      // Check if the profileImagePath column exists
      final result = await db.rawQuery("PRAGMA table_info(users)");
      final columnExists = result.any(
        (column) => column['name'] == 'profileImagePath',
      );

      if (!columnExists) {
        print('🔧 Adding missing profileImagePath column...');
        await db.execute('''
          ALTER TABLE users ADD COLUMN profileImagePath TEXT
        ''');
        print('✅ ProfileImagePath column added successfully');
      } else {
        print('ℹ️ ProfileImagePath column already exists');
      }
    } catch (e) {
      print('❌ Error checking/adding profileImagePath column: $e');
      rethrow;
    }
  }

  Future<void> updateUserAbout(String email, String about) async {
    try {
      print('🔄 Starting database update for email: $email, about: $about');

      // Ensure the about column exists before trying to update
      await _ensureAboutColumnExists();

      final db = await database;
      print('📊 Database connection established');

      final rowsAffected = await db.update(
        'users',
        {'about': about, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'email = ?',
        whereArgs: [email],
      );

      print('✅ User about updated for: $email, rows affected: $rowsAffected');

      if (rowsAffected == 0) {
        print('⚠️ No rows were updated - user might not exist');
        throw Exception('No user found with email: $email');
      }
    } catch (e) {
      print('❌ Error in updateUserAbout: $e');
      rethrow;
    }
  }

  Future<void> updateUserName(String email, String name) async {
    try {
      print('🔄 Starting database update for email: $email, name: $name');
      final db = await database;
      print('📊 Database connection established');

      final rowsAffected = await db.update(
        'users',
        {'name': name, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'email = ?',
        whereArgs: [email],
      );

      print('✅ User name updated for: $email, rows affected: $rowsAffected');

      if (rowsAffected == 0) {
        print('⚠️ No rows were updated - user might not exist');
        throw Exception('No user found with email: $email');
      }
    } catch (e) {
      print('❌ Error in updateUserName: $e');
      rethrow;
    }
  }

  Future<void> updateUserEmail(String oldEmail, String newEmail) async {
    try {
      print('🔄 Starting database email update from: $oldEmail to: $newEmail');
      final db = await database;
      print('📊 Database connection established');

      final rowsAffected = await db.update(
        'users',
        {'email': newEmail, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'email = ?',
        whereArgs: [oldEmail],
      );

      print('✅ User email updated: rows affected: $rowsAffected');

      if (rowsAffected == 0) {
        print('⚠️ No rows were updated - user might not exist');
        throw Exception('No user found with email: $oldEmail');
      }
    } catch (e) {
      print('❌ Error in updateUserEmail: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfileImage(String email, String? imagePath) async {
    try {
      print(
        '🔄 Starting profile image update for email: $email, imagePath: $imagePath',
      );

      // Ensure the profileImagePath column exists before trying to update
      await _ensureProfileImagePathColumnExists();

      final db = await database;
      print('📊 Database connection established');

      final rowsAffected = await db.update(
        'users',
        {
          'profileImagePath': imagePath,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'email = ?',
        whereArgs: [email],
      );

      print(
        '✅ User profile image updated for: $email, rows affected: $rowsAffected',
      );

      if (rowsAffected == 0) {
        print('⚠️ No rows were updated - user might not exist');
        throw Exception('No user found with email: $email');
      }
    } catch (e) {
      print('❌ Error in updateUserProfileImage: $e');
      rethrow;
    }
  }
}
