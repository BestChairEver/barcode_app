import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];

  List<Product> get products => _products;

  Future<void> loadProducts() async {
    final databaseHelper = DatabaseHelper();
    _products = await databaseHelper.getProducts();
    _products.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
  final databaseHelper = DatabaseHelper();
  final id = await databaseHelper.insertProduct(product);
  product.id = id;
  _products.add(product);
  notifyListeners();
}

  Future<void> deleteProduct(int id) async {
    final databaseHelper = DatabaseHelper();
    await databaseHelper.deleteProduct(id);
    _products.removeWhere((product) => product.id == id);
    notifyListeners();
  }

  Future<void> init() async {
    await loadProducts();
  }
}
