import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final dbFile = join(dbPath, filePath);

    return await openDatabase(
      dbFile,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const table = '''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lastName TEXT NOT NULL,
        firstName TEXT NOT NULL,
        birthDate TEXT NOT NULL,
        gender TEXT NOT NULL,
        grade TEXT NOT NULL,
        school TEXT NOT NULL,
        city TEXT NOT NULL
      );
    ''';
    await db.execute(table);
  }

  Future<void> insertData(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert('students', data);
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    final db = await instance.database;
    return await db.query('students');
  }
}