import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

const _storageKey = 'tx_data';

class PlatformWebStorage {
  int _nextId = 1;

  Future<List<Transaction>> _loadAll() async {
    if (!kIsWeb) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Transaction.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _saveAll(List<Transaction> txs) async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(txs.map((t) => t.toMap()).toList());
    await prefs.setString(_storageKey, raw);
  }

  Future<int> insert(Transaction tx) async {
    final all = await _loadAll();
    final id = _nextId++;
    final newTx = tx.copyWith(id: id);
    all.add(newTx);
    await _saveAll(all);
    return id;
  }

  Future<int> update(Transaction tx) async {
    final all = await _loadAll();
    final idx = all.indexWhere((t) => t.id == tx.id);
    if (idx >= 0) { all[idx] = tx; }
    await _saveAll(all);
    return 1;
  }

  Future<int> delete(int id) async {
    final all = await _loadAll();
    all.removeWhere((t) => t.id == id);
    await _saveAll(all);
    return 1;
  }

  Future<Transaction?> getById(int id) async {
    final all = await _loadAll();
    final idx = all.indexWhere((t) => t.id == id);
    return idx >= 0 ? all[idx] : null;
  }

  Future<List<Transaction>> getByMonth(int year, int month) async {
    final all = await _loadAll();
    all.retainWhere((t) => t.date.year == year && t.date.month == month);
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  Future<List<Transaction>> getAll() async {
    final all = await _loadAll();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  Future<double> getMonthlyIncome(int year, int month) async {
    final all = await _loadAll();
    double inc = 0; for (final t in all.where((tx) => tx.type == TransactionType.income && tx.date.year == year && tx.date.month == month)) { inc += t.amount; } return inc;
  }

  Future<double> getMonthlyExpense(int year, int month) async {
    final all = await _loadAll();
    double exp = 0; for (final t in all.where((tx) => tx.type == TransactionType.expense && tx.date.year == year && tx.date.month == month)) { exp += t.amount; } return exp;
  }

  Future<Map<String, double>> getCategoryBreakdown(int year, int month, TransactionType type) async {
    final all = await _loadAll();
    final filtered = all.where((t) => t.type == type && t.date.year == year && t.date.month == month);
    final map = <String, double>{};
    for (final t in filtered) { map.update(t.category, (v) => v + t.amount, ifAbsent: () => t.amount); }
    return map;
  }

  Future<List<DateTime>> getDistinctMonths() async {
    final all = await _loadAll();
    final months = <String>{};
    for (final t in all) { months.add('${t.date.year}-${t.date.month.toString().padLeft(2, '0')}'); }
    return months.map((m) { final parts = m.split('-'); return DateTime(int.parse(parts[0]), int.parse(parts[1])); }).toList()..sort((a, b) => b.compareTo(a));
  }
}
