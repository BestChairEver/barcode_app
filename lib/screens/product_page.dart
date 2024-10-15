import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/product_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductsPage extends StatelessWidget {
  final ProductProvider productProvider;

  ProductsPage({required this.productProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список продуктов'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: productProvider.products.isEmpty
          ? Center(
              child: Text(
                'Нет добавленных продуктов',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: productProvider.products.length,
                itemBuilder: (context, index) {
                  final product = productProvider.products[index];

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: product.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => Center(child: Icon(Icons.error, size: 30)),
                                )
                              : Center(child: Icon(Icons.image, size: 30, color: Colors.grey)),
                        ),
                      ),
                      title: Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      subtitle: Text(
                        'Срок годности: ${DateFormat('dd.MM.yyyy').format(product.expiryDate)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14.0),
                      ),
                      trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Удалить продукт?'),
                                content: Text('Вы уверены, что хотите удалить "${product.name}"?'),
                                actions: [
                                  TextButton(
                                    child: Text('Отмена'),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  TextButton(
                                    child: Text('Удалить'),
                                    onPressed: () async {
                                      if (product.id != null) {
                                        await productProvider.deleteProduct(product.id!);
                                        Navigator.of(context).pop();
                                      } else {
                                        print("Невозможно удалить продукт без id");
                                      }
                                    },
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}