import 'package:sqflite/sqflite.dart';
import 'package:chatme/database/db-helper.dart';
import 'package:chatme/modal/user.dart';
// import 'package:shared_preferences/shared_preferences.dart';


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

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }

    return null;
  }

  // Future<void> setLoggedIn(String email) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool('isLoggedIn', true);
  //   await prefs.setString('loggedInEmail', email);
  // }
}
