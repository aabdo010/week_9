import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('items.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        quantity INTEGER
      )
    ''');
  }

  Future<List<ToDoItem>> getItems() async {
    final db = await instance.database;
    final result = await db.query('items');
    print("Database Query Result: $result");  // Debugging
    return result.map((json) => ToDoItem.fromJson(json)).toList();
  }

  Future<int> insert(ToDoItem item) async {
    final db = await instance.database;
    return await db.insert('items', {
      'name': item.name,  // 👈 Removed 'id' because SQLite auto-generates it
      'quantity': item.quantity,
    });
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}

class ToDoItem {
  final int? id; // 👈 Made 'id' optional
  final String name;
  final int quantity;

  ToDoItem({this.id, required this.name, required this.quantity});

  factory ToDoItem.fromJson(Map<String, dynamic> json) =>
      ToDoItem(id: json['id'], name: json['name'], quantity: json['quantity']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'quantity': quantity};
}
