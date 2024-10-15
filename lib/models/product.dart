class Product {
  int? id;
  String name;
  DateTime expiryDate;
  String imageUrl;

  Product({
    this.id,
    required this.name,
    required this.expiryDate,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id, 
      'name': name,
      'expiryDate': expiryDate.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      expiryDate: DateTime.parse(json['expiryDate']),
      imageUrl: json['imageUrl'],
    );
  }
}
