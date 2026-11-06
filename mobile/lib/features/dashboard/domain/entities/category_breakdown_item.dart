/// Representation of aggregated financial spending per category
class CategoryBreakdownItem {
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final double totalAmount;
  final int transactionCount;
  final double percentage; // 0.0 to 100.0

  const CategoryBreakdownItem({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
  });

  @override
  String toString() =>
      'CategoryBreakdownItem($categoryName: Rp $totalAmount (${percentage.toStringAsFixed(1)}%))';
}
