class MessageModel {
  final int id;
  final String customerName;
  final String content;
  final String sentiment;
  final String category;
  final String priority;
  final String createdAt;

  MessageModel({
    required this.id,
    required this.customerName,
    required this.content,
    required this.sentiment,
    required this.category,
    required this.priority,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      customerName: json['customer_name'],
      content: json['content'],
      sentiment: json['sentiment'],
      category: json['category'],
      priority: json['priority'],
      createdAt: json['created_at'],
    );
  }
}
