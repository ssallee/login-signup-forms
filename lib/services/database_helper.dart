import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';
import '../models/routine.dart';
import 'package:flutter/material.dart';

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
      version: 1,
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

        await db.execute('''
          CREATE TABLE routines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            daysOfWeek TEXT NOT NULL,
            startTime TEXT NOT NULL,
            endTime TEXT NOT NULL,
            isActive INTEGER DEFAULT 1
          )
        ''');
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

  Future<List<Event>> getAllEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    
    return List.generate(maps.length, (i) {
      return Event(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'] ?? '',
        date: DateTime.parse(maps[i]['date']),
        startTime: maps[i]['startTimeHour'] != null
            ? TimeOfDay(
                hour: maps[i]['startTimeHour'],
                minute: maps[i]['startTimeMinute'],
              )
            : null,
        endTime: maps[i]['endTimeHour'] != null
            ? TimeOfDay(
                hour: maps[i]['endTimeHour'],
                minute: maps[i]['endTimeMinute'],
              )
            : null,
        isPriority: maps[i]['isPriority'] == 1,
      );
    });
  }

  Future<List<Event>> getFutureEvents() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'date >= ?',
      whereArgs: [todayStart],
      orderBy: 'date ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Event(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'] ?? '',
        date: DateTime.parse(maps[i]['date']),
        startTime: maps[i]['startTimeHour'] != null
            ? TimeOfDay(
                hour: maps[i]['startTimeHour'],
                minute: maps[i]['startTimeMinute'],
              )
            : null,
        endTime: maps[i]['endTimeHour'] != null
            ? TimeOfDay(
                hour: maps[i]['endTimeHour'],
                minute: maps[i]['endTimeMinute'],
              )
            : null,
        isPriority: maps[i]['isPriority'] == 1,
      );
    });
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

  Future<int> insertRoutine(Routine routine) async {
    final Database db = await database;
    return await db.insert('routines', routine.toMap());
  }

  Future<List<Routine>> getRoutines() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('routines');
    return List.generate(maps.length, (i) => Routine.fromMap(maps[i]));
  }

  Future<List<Routine>> getRoutinesForDay(int weekday) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('routines');
    return maps
        .map((map) => Routine.fromMap(map))
        .where((routine) => 
            routine.isActive && routine.daysOfWeek.contains(weekday))
        .toList();
  }

  Future<int> updateRoutine(Routine routine) async {
    final Database db = await database;
    return await db.update(
      'routines',
      routine.toMap(),
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  Future<int> deleteRoutine(int id) async {
    final Database db = await database;
    return await db.delete(
      'routines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}