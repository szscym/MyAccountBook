import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('money_minder.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL
      )
    ''');
  }

  // --- CRUD ---

  Future<int> insert(Transaction tx) async {
    final db = await database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<int> update(Transaction tx) async {
    final db = await database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Transaction?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  /// Get transactions in [year]-[month] (both inclusive), ordered by date desc
  Future<List<Transaction>> getByMonth(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDay = _daysInMonth(year, month);
    final endDate = '$year-${month.toString().padLeft(2, '0')}-$endDay';

    final maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  /// Get all transactions, ordered by date desc
  Future<List<Transaction>> getAll() async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  /// Monthly income total
  Future<double> getMonthlyIncome(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDay = _daysInMonth(year, month);
    final endDate = '$year-${month.toString().padLeft(2, '0')}-$endDay';

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions '
      'WHERE type = ? AND date BETWEEN ? AND ?',
      [TransactionType.income.index, startDate, endDate],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// Monthly expense total
  Future<double> getMonthlyExpense(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDay = _daysInMonth(year, month);
    final endDate = '$year-${month.toString().padLeft(2, '0')}-$endDay';

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions '
      'WHERE type = ? AND date BETWEEN ? AND ?',
      [TransactionType.expense.index, startDate, endDate],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// Category breakdown for a month and type
  Future<Map<String, double>> getCategoryBreakdown(
    int year,
    int month,
    TransactionType type,
  ) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDay = _daysInMonth(year, month);
    final endDate = '$year-${month.toString().padLeft(2, '0')}-$endDay';

    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM transactions '
      'WHERE type = ? AND date BETWEEN ? AND ? '
      'GROUP BY category ORDER BY total DESC',
      [type.index, startDate, endDate],
    );

    return {
      for (var row in result) row['category'] as String: (row['total'] as num).toDouble(),
    };
  }

  /// Get all distinct months that have transactions (for filter dropdowns)
  Future<List<DateTime>> getDistinctMonths() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT date FROM transactions ORDER BY date DESC',
    );
    // Parse to DateTime, then group by year-month
    final months = <String>{};
    for (var row in result) {
      final date = DateTime.parse(row['date'] as String);
      months.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }
    return months.map((m) {
      final parts = m.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]));
    }).toList()
      ..sort((a, b) => b.compareTo(a));
  }

  int _daysInMonth(int year, int month) {
    if (month == 12) {
      return 31;
    }
    return DateTime(year, month + 1, 0).day;
  }
}
