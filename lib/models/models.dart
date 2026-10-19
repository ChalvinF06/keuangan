// ============================================================
// MODEL: Category
// ============================================================
class CategoryModel {
  final int? id;
  final String name;
  final String type; // 'income' | 'expense'
  final String createdAt;

  CategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        type: map['type'] as String,
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type,
        'created_at': createdAt,
      };
}

// ============================================================
// MODEL: Transaction
// ============================================================
class TransactionModel {
  final int? id;
  final String type; // 'income' | 'expense'
  final double amount;
  final int categoryId;
  final String categoryName;
  final String? description;
  final String? itemName; // for expense
  final int quantity; // for expense
  final String date;
  final String createdAt;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.itemName,
    this.quantity = 1,
    required this.date,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'] as int?,
        type: map['type'] as String,
        amount: (map['amount'] as num).toDouble(),
        categoryId: map['category_id'] as int,
        categoryName: map['category_name'] as String,
        description: map['description'] as String?,
        itemName: map['item_name'] as String?,
        quantity: (map['quantity'] as int?) ?? 1,
        date: map['date'] as String,
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type,
        'amount': amount,
        'category_id': categoryId,
        'category_name': categoryName,
        'description': description,
        'item_name': itemName,
        'quantity': quantity,
        'date': date,
        'created_at': createdAt,
      };

  String get displayName {
    if (type == 'income') return description ?? categoryName;
    return itemName ?? categoryName;
  }
}

// ============================================================
// MODEL: Category Total (for charts)
// ============================================================
class CategoryTotal {
  final String categoryName;
  final double total;

  CategoryTotal({required this.categoryName, required this.total});

  factory CategoryTotal.fromMap(Map<String, dynamic> map) => CategoryTotal(
        categoryName: map['category_name'] as String,
        total: (map['total'] as num).toDouble(),
      );
}