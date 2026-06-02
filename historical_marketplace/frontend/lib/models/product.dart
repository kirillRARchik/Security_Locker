class Product {
  final int? id;
  final String? photoUrl;
  final String name;
  final double price;
  final int quantity;
  final bool customMade;
  final String? description;
  final String? sizeMeasure;
  final String? manufacturingMethod;
  final String? category;
  final String? authenticityCertificate;
  final String? period;
  final String? material;
  final bool? verifiedByAdmin;
  final SellerInfo? seller;

  Product({
    this.id,
    this.photoUrl,
    required this.name,
    required this.price,
    required this.quantity,
    required this.customMade,
    this.description,
    this.sizeMeasure,
    this.manufacturingMethod,
    this.category,
    this.authenticityCertificate,
    this.period,
    this.material,
    this.verifiedByAdmin,
    this.seller,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      photoUrl: json['photoUrl'],
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      customMade: json['customMade'] ?? false,
      description: json['description'],
      sizeMeasure: json['sizeMeasure'],
      manufacturingMethod: json['manufacturingMethod'],
      category: json['category'],
      authenticityCertificate: json['authenticityCertificate'],
      period: json['period'],
      material: json['material'],
      verifiedByAdmin: json['verifiedByAdmin'],
      seller: json['seller'] != null ? SellerInfo.fromJson(json['seller']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photoUrl': photoUrl,
      'name': name,
      'price': price,
      'quantity': quantity,
      'customMade': customMade,
      'description': description,
      'sizeMeasure': sizeMeasure,
      'manufacturingMethod': manufacturingMethod,
      'category': category,
      'authenticityCertificate': authenticityCertificate,
      'period': period,
      'material': material,
      'verifiedByAdmin': verifiedByAdmin,
    };
  }
}

class SellerInfo {
  final int? id;
  final String? businessArea;
  final String? iin;

  SellerInfo({
    this.id,
    this.businessArea,
    this.iin,
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      id: json['id'],
      businessArea: json['businessArea'],
      iin: json['iin'],
    );
  }
}


