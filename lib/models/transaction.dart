import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TransactionType { income, expense }

class Transaction {
  final int? id;
  final TransactionType type;
  final double amount;
  final String category;
  final String? note;
  final DateTime date;

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'amount': amount,
      'category': category,
      'note': note,
      'date': DateFormat('yyyy-MM-dd').format(date),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      type: TransactionType.values[map['type'] as int],
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
    );
  }

  Transaction copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }
}

/// All available categories, separated by type
class Categories {
  static const Map<TransactionType, List<String>> items = {
    TransactionType.income: ['工资', '奖金', '投资', '兼职', '其他收入'],
    TransactionType.expense: ['餐饮', '交通', '购物', '住房', '娱乐', '医疗', '教育', '通讯', '其他支出'],
  };

  /// Icon code point mapping for each category (Material Icons)
  static IconData iconFor(String category) {
    const Map<String, IconData> mapping = {
      '工资': Icons.work,
      '奖金': Icons.emoji_events,
      '投资': Icons.trending_up,
      '兼职': Icons.more_time,
      '其他收入': Icons.savings,
      '餐饮': Icons.restaurant,
      '交通': Icons.directions_car,
      '购物': Icons.shopping_bag,
      '住房': Icons.home,
      '娱乐': Icons.sports_esports,
      '医疗': Icons.local_hospital,
      '教育': Icons.school,
      '通讯': Icons.call,
      '其他支出': Icons.more_horiz,
    };
    return mapping[category] ?? Icons.help_outline;
  }
}
