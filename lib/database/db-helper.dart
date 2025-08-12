import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseConnection {
  static final DatabaseConnection _instance = DatabaseConnection._internal();
  factory DatabaseConnection() => _instance;
  DatabaseConnection._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await setDatabase();
    return _database!;
  }

  Future<Database> setDatabase() async {

    String path = join(await getDatabasesPath(), 'chatMate.db');
    print('📂 DB location: $path');

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );


    return db;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        uuid TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    print("✅ users table created.");
  }



}
