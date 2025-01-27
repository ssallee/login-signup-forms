import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }
  
  DatabaseHelper._internal();

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'calendar_events.db');
    
    return await openDatabase(
      path,
      version: 2, // Increment version number
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            date TEXT NOT NULL,
            startTime TEXT,
            endTime TEXT,
            createdAt TEXT NOT NULL,
            isPriority INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE events ADD COLUMN isPriority INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future<int> insertEvent(Event event) async {
    final Database db = await database;
    return await db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Event>> getEvents() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<List<Event>> getEventsForDate(DateTime date) async {
    final Database db = await database;
    final dateString = DateTime(date.year, date.month, date.day).toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: "date LIKE ?",
      whereArgs: ['$dateString%'],
    );
    
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<int> updateEvent(Event event) async {
    final Database db = await database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final Database db = await database;
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllEvents() async {
    final Database db = await database;
    await db.delete('events');
  }
}