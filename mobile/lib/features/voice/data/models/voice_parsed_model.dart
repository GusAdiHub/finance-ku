class VoiceParsedModel {
  final String rawText;
  final String type; // 'expense' | 'income'
  final double? amount;
  final String? description;
  final String? suggestedCategoryName;
  final String? suggestedCategoryId;
  final double confidenceScore;

  const VoiceParsedModel({
    required this.rawText,
    this.type = 'expense',
    this.amount,
    this.description,
    this.suggestedCategoryName,
    this.suggestedCategoryId,
    this.confidenceScore = 0.0,
  });

  factory VoiceParsedModel.fromJson(Map<String, dynamic> json) {
    return VoiceParsedModel(
      rawText: json['raw_text'] ?? '',
      type: json['type'] ?? 'expense',
      amount: (json['amount'] as num?)?.toDouble(),
      description: json['description'],
      suggestedCategoryName: json['suggested_category_name'],
      suggestedCategoryId: json['suggested_category_id'],
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
