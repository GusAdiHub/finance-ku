import '../../domain/entities/receipt_entity.dart';

class ReceiptItemModel extends ReceiptItemEntity {
  const ReceiptItemModel({
    required super.itemName,
    super.quantity = 1.0,
    super.pricePerUnit = 0.0,
    super.totalPrice = 0.0,
  });

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return ReceiptItemModel(
      itemName: json['item_name'] ?? 'Item',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_name': itemName,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_price': totalPrice,
    };
  }
}

class ReceiptModel extends ReceiptEntity {
  const ReceiptModel({
    required super.id,
    required super.fileName,
    super.merchantName,
    super.receiptDate,
    required super.totalAmount,
    required super.status,
    super.ocrStatus,
    super.ocrMessage,
    super.items = const [],
    required super.createdAt,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((i) => ReceiptItemModel.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];

    DateTime? rDate;
    if (json['receipt_date'] != null) {
      rDate = DateTime.tryParse(json['receipt_date'].toString());
    }

    DateTime cDate = DateTime.now();
    if (json['created_at'] != null) {
      cDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    return ReceiptModel(
      id: json['id'] ?? '',
      fileName: json['file_name'] ?? '',
      merchantName: json['merchant_name'],
      receiptDate: rDate,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'draft',
      ocrStatus: json['ocr_status'],
      ocrMessage: json['ocr_message'],
      items: itemsList,
      createdAt: cDate,
    );
  }
}
