import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../utils/product_provider.dart';
import 'calender.dart';
import 'product_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              return ProductsPage(productProvider: productProvider);
            },
          ),
          CalendarPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Продукты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Календарь',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              await _addProductManually();
            },
            child: Icon(Icons.add),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () async {
              var result = await BarcodeScanner.scan();
              if (result.rawContent.isNotEmpty) {
                await fetchProductData(result.rawContent);
              } else {
                _showErrorMessage('Неудачное сканирование.');
              }
            },
            child: Icon(Icons.camera),
          ),
        ],
      ),
    );
  }

   Future<void> _addProductManually() async {
    final productNameController = TextEditingController();
    DateTime? expiryDate;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Добавить продукт вручную'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: productNameController,
                decoration: InputDecoration(labelText: 'Название продукта'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Выбрать срок годности'),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                    locale: const Locale("ru", "RU"),
                  );
                  if (picked != null) {
                    setState(() {
                      expiryDate = picked;
                    });
                  }
                },
              ),
              expiryDate != null
                  ? Text('Выбранная дата: ${DateFormat('dd.MM.yy').format(expiryDate!)}')
                  : Text(''),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Добавить'),
              onPressed: () async {
                final productName = productNameController.text;

                if (productName.isNotEmpty) {
                  final newProduct = Product(
                    name: productName,
                    expiryDate: expiryDate ?? DateTime.now(), // используем оператор ??
                    imageUrl: '',
                  );
                  final productProvider = Provider.of<ProductProvider>(context, listen: false);
                  await productProvider.addProduct(newProduct);
                  await productProvider.loadProducts();
                  Navigator.of(context).pop();
                } else {
                  _showErrorMessage('Введите все поля');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchProductData(String barcode) async {
    final url = 'https://world.openfoodfacts.org/api/v0/product/$barcode.json';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final productData = json.decode(response.body);

        if (productData['status'] == 1) {
          final product = productData['product'];
          final productName = product['product_name'] ?? 'Неизвестный продукт';
          final imageUrl = product['image_url'] ?? '';

          DateTime? selectedDate = await showDialog<DateTime>(
            context: context,
            builder: (BuildContext context) {
              DateTime initialDate = DateTime.now();
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: Text('Введите срок годности'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('Выбранная дата: ${DateFormat('dd.MM.yy').format(initialDate)}'),
                        SizedBox(height: 20),
                        ElevatedButton(
                          child: Text('Выбрать дату'),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: initialDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                              locale: const Locale("ru", "RU"),
                            );
                            if (picked != null && picked != initialDate) {
                              setState(() {
                                initialDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Отмена'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('ОК'),
                        onPressed: () {
                          Navigator.of(context).pop(initialDate);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );

          if (selectedDate != null) {
            final newProduct = Product(
              name: productName,
              expiryDate: selectedDate,
              imageUrl: imageUrl,
            );
            final productProvider = Provider.of<ProductProvider>(context, listen: false);
            await productProvider.addProduct(newProduct);
            await productProvider.loadProducts();
          }
        } else {
          _showErrorMessage('Продукт не найден.');
        }
      } else {
        _showErrorMessage('Ошибка при получении данных.');
      }
    } catch (e) {
      _showErrorMessage('Ошибка: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}