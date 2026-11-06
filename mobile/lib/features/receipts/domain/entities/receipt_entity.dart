class ReceiptItemEntity {
  final String itemName;
  final double quantity;
  final double pricePerUnit;
  final double totalPrice;

  const ReceiptItemEntity({
    required this.itemName,
    this.quantity = 1.0,
    this.pricePerUnit = 0.0,
    this.totalPrice = 0.0,
  });
}

class ReceiptEntity {
  final String id;
  final String fileName;
  final String? merchantName;
  final DateTime? receiptDate;
  final double totalAmount;
  final String status;
  final String? ocrStatus;
  final String? ocrMessage;
  final List<ReceiptItemEntity> items;
  final DateTime createdAt;

  const ReceiptEntity({
    required this.id,
    required this.fileName,
    this.merchantName,
    this.receiptDate,
    required this.totalAmount,
    required this.status,
    this.ocrStatus,
    this.ocrMessage,
    this.items = const [],
    required this.createdAt,
  });
}
