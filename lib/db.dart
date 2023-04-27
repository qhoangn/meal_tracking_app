import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DB with ChangeNotifier {
  static final DB _db = DB._internal();
  DB._internal();
  static DB get instance => _db;
  static Database? _database;

  // values for currently selected date
  static int id = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
  static int calories = 0;
  static double protein = 0;
  static double carbs = 0;
  static double fat = 0;
  static List<dynamic> foods = [];

  // values for macronutrient calculation
  static Map<String, dynamic> calc = {
    'age': 0,
    'weight': 0,
    'height': 0,
    'activity': 0,
  };

  static Map<String, dynamic> goal = {
    'calories': 2000,
    'protein': 150,
    'carbs': 200,
    'fat': 67,
  };

  factory DB() {
    return _db;
  }

  Future<Database?> get database async {
    if(_database != null) {
      return _database;
    }
    _database = await _init();
    return _database;
  }

  Future<Database> _init() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'database.db'),
      onCreate: (db, version) {
        return db.execute('''
        CREATE TABLE days(
        id INTEGER PRIMARY KEY,
        calories INTEGER,
        protein REAL,
        carbs REAL,
        fat REAL,
        foods BLOB)
        ''');
      },
      version: 1,
    );
  }

  void addFood(Map<String, dynamic> m) {
    calories += int.parse(m['calories']!);
    protein += double.parse(m['protein']!);
    carbs += double.parse(m['carbs']!);
    fat += double.parse(m['fat']!);
    foods.add(m['info']!);

    update(mapValues());
  }

  void zeroValues() {
    calories = 0;
    protein = 0;
    carbs = 0;
    fat = 0;
    foods = [];
  }

  Map<String, dynamic> mapValues() {
    return {
      'id': id,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'foods': foods,
    };
  }

  void setValues(Map<String, dynamic> m) {
      id = m['id'];
      calories = m['calories'];
      protein = m['protein'];
      carbs = m['carbs'];
      fat = m['fat'];
      foods = jsonDecode(m['foods']);
  }

  void setDay(int i) async {
    final q = await query(i);
    if (q == null) {
      id = i;
      zeroValues();
      insert(mapValues());
    } else {
      setValues(q);
    }

    notifyListeners();
  }

  query(int i) async {
    final q = await (_database!).query(
      'days',
      where: 'id = ?',
      whereArgs: [i],
    );

    return q.isNotEmpty ? q.first : null;
  }

  void insert(Map<String, dynamic> m) async {
    m['foods'] = jsonEncode(m['foods']);
    await _database!.insert(
      'days',
      m,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void update(Map<String, dynamic> m) async {
    m['foods'] = jsonEncode(m['foods']);
    await _database!.update(
      'days',
      m,
      where: 'id = ?',
      whereArgs: [m['id']],
    );
  }

  void delete(int i) async {
    await _database!.delete(
      'days',
      where: 'id = ?',
      whereArgs: [i],
    );
  }
}
