import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// All available categories, separated by type.
/// Supports custom categories persisted via SharedPreferences.
class Categories {
  static const Map<TransactionType, List<String>> _defaultItems = {
    TransactionType.income: ['工资', '奖金', '投资', '兼职', '其他收入'],
    TransactionType.expense: ['餐饮', '交通', '购物', '住房', '娱乐', '医疗', '教育', '通讯', '其他支出'],
  };

  /// Returns the full category list for the given type (default + custom).
  static Future<List<String>> getItems(TransactionType type) async {
    final defaults = List<String>.from(_defaultItems[type]!);
    final customs = await _loadCustomCategories(type);
    // Insert custom categories before the "其他" ones
    final otherPrefix = type == TransactionType.income ? '其他' : '其他';
    final otherIdx = defaults.indexWhere((c) => c.startsWith(otherPrefix));
    if (otherIdx >= 0) {
      defaults.insertAll(otherIdx, customs);
    } else {
      defaults.addAll(customs);
    }
    return defaults;
  }

  /// Synchronous version using defaults only (for quick access).
  static List<String> defaultItems(TransactionType type) {
    return List<String>.from(_defaultItems[type]!);
  }

  /// Add a custom category. Returns the updated list.
  static Future<List<String>> addCustom(TransactionType type, String category) async {
    final customs = await _loadCustomCategories(type);
    if (!customs.contains(category)) {
      customs.add(category);
      await _saveCustomCategories(type, customs);
    }
    return getItems(type);
  }

  /// Remove a custom category. Only custom categories can be removed.
  static Future<List<String>> removeCustom(TransactionType type, String category) async {
    final customs = await _loadCustomCategories(type);
    customs.remove(category);
    await _saveCustomCategories(type, customs);
    return getItems(type);
  }

  /// Check if a category is a default (cannot be removed).
  static bool isDefault(String category) {
    for (final list in _defaultItems.values) {
      if (list.contains(category)) return true;
    }
    return false;
  }

  static Future<List<String>> _loadCustomCategories(TransactionType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'custom_${type.name}_categories';
    final raw = prefs.getStringList(key);
    return raw ?? [];
  }

  static Future<void> _saveCustomCategories(TransactionType type, List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'custom_${type.name}_categories';
    await prefs.setStringList(key, categories);
  }

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
    return mapping[category] ?? Icons.category;
  }
}
