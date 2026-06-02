class OrderAddress {
  final int? id;
  final String? line1;
  final String? city;

  OrderAddress({this.id, this.line1, this.city});

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      id: json['id'],
      line1: json['line1'],
      city: json['city'],
    );
  }
}

class OrderModel {
  final int id;
  final String status;
  final double? totalAmount;
  final DateTime? orderDate;
  final OrderAddress? address;

  OrderModel({
    required this.id,
    required this.status,
    this.totalAmount,
    this.orderDate,
    this.address,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final orderDateRaw = json['orderDate'];
    DateTime? parsedDate;
    if (orderDateRaw is String && orderDateRaw.isNotEmpty) {
      parsedDate = DateTime.tryParse(orderDateRaw);
    }

    final addressRaw = json['address'];
    return OrderModel(
      id: (json['id'] ?? 0) is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      status: (json['status'] ?? '').toString(),
      totalAmount: (json['totalAmount'] is num) ? (json['totalAmount'] as num).toDouble() : null,
      orderDate: parsedDate,
      address: addressRaw is Map<String, dynamic> ? OrderAddress.fromJson(addressRaw) : null,
    );
  }
}

