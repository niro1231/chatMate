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
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );

    return db;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        uuid TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        about TEXT DEFAULT 'Available',
        profileImagePath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    print("✅ users table created.");
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    print('🔄 Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Check if the about column already exists to avoid duplicate column error
      try {
        final result = await db.rawQuery("PRAGMA table_info(users)");
        final columnExists = result.any((column) => column['name'] == 'about');

        if (!columnExists) {
          // Add the about column for version 2
          await db.execute('''
            ALTER TABLE users ADD COLUMN about TEXT DEFAULT 'Available'
          ''');
          print("✅ users table upgraded - added about column.");
        } else {
          print("ℹ️ about column already exists, skipping migration.");
        }
      } catch (e) {
        print('❌ Error during migration: $e');
        // Try to add the column anyway in case the check failed
        try {
          await db.execute('''
            ALTER TABLE users ADD COLUMN about TEXT DEFAULT 'Available'
          ''');
          print("✅ users table upgraded - added about column (fallback).");
        } catch (e2) {
          print('❌ Failed to add about column: $e2');
          rethrow;
        }
      }
    }
  }
}
