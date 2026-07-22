import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/transaction.dart';
import 'platform_web_storage.dart';

// Import sqflite only for mobile
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  Database? _db;
  late final bool _isWeb;
  final PlatformWebStorage _webStorage = PlatformWebStorage();

  DatabaseHelper._init() {
    _isWeb = kIsWeb;
  }

  Future<Database> get database async {
    if (_isWeb) throw UnsupportedError('Use web storage methods on web');
    if (_db != null) return _db!;
    _db = await _initDB('money_minder.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, type INTEGER NOT NULL, amount REAL NOT NULL, category TEXT NOT NULL, note TEXT, date TEXT NOT NULL)''');
  }

  Future<int> insert(Transaction tx) async {
    if (_isWeb) return await _webStorage.insert(tx);
    final db = await database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<int> update(Transaction tx) async {
    if (_isWeb) return await _webStorage.update(tx);
    final db = await database;
    return await db.update('transactions', tx.toMap(), where: 'id = ?', whereArgs: [tx.id]);
  }

  Future<int> delete(int id) async {
    if (_isWeb) return await _webStorage.delete(id);
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<Transaction?> getById(int id) async {
    if (_isWeb) return await _webStorage.getById(id);
    final db = await database;
    final maps = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  Future<List<Transaction>> getByMonth(int year, int month) async {
    if (_isWeb) return await _webStorage.getByMonth(year, month);
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDay = _daysInMonth(year, month);
    final endDate = '$year-${month.toString().padLeft(2, '0')}-$endDay';
    final maps = await db.query('transactions', where: 'date BETWEEN ? AND ?', whereArgs: [startDate, endDate], orderBy: 'date DESC, id DESC');
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<List<Transaction>> getAll() async {
    if (_isWeb) return await _webStorage.getAll();
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<double> getMonthlyIncome(int year, int month) async {
    if (_isWeb) return await _webStorage.getMonthlyIncome(year, month);
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDay = _daysInMonth(year, month);
    final endDate = '$year-${month.toString().padLeft(2, '0')}-$endDay';
    final result = await db.rawQuery('SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = ? AND date BETWEEN ? AND ?', [TransactionType.income.index, startDate, endDate]);
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getMonthlyExpense(int year, int month) async {
    if (_isWeb) return await _webStorage.getMonthlyExpense(year, month);
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDay = _daysInMonth(year, month);
    final endDate = '$year-${month.toString().padLeft(2, '0')}-$endDay';
    final result = await db.rawQuery('SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = ? AND date BETWEEN ? AND ?', [TransactionType.expense.index, startDate, endDate]);
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> getCategoryBreakdown(int year, int month, TransactionType type) async {
    if (_isWeb) return await _webStorage.getCategoryBreakdown(year, month, type);
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDay = _daysInMonth(year, month);
    final endDate = '$year-${month.toString().padLeft(2, '0')}-$endDay';
    final result = await db.rawQuery('SELECT category, SUM(amount) as total FROM transactions WHERE type = ? AND date BETWEEN ? AND ? GROUP BY category ORDER BY total DESC', [type.index, startDate, endDate]);
    return {for (var row in result) row['category'] as String: (row['total'] as num).toDouble()};
  }

  Future<List<DateTime>> getDistinctMonths() async {
    if (_isWeb) return await _webStorage.getDistinctMonths();
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT date FROM transactions ORDER BY date DESC');
    final months = <String>{};
    for (var row in result) {
      final date = DateTime.parse(row['date'] as String);
      months.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }
    return months.map((m) { final parts = m.split('-'); return DateTime(int.parse(parts[0]), int.parse(parts[1])); }).toList()..sort((a, b) => b.compareTo(a));
  }

  int _daysInMonth(int year, int month) {
    if (month == 12) return 31;
    return DateTime(year, month + 1, 0).day;
  }
}
