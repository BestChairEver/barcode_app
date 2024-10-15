import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DatabaseHelper {
  static final _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), 'products.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            expiryDate TEXT NOT NULL,
            imageUrl TEXT
          )
        ''');
    });
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final products = await db.query('products');
    return products.map((product) => Product.fromJson(product)).toList();
  }

  Future<int> insertProduct(Product product) async {
  final db = await database;
  final id = await db.insert('products', product.toJson());
  return id;
}

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}