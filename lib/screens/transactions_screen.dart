import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen> {
  final db = DatabaseHelper.instance;
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _loading = true;
  int? _filterYear;
  int? _filterMonth;
  List<DateTime> _availableMonths = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadMonths();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredTransactions = List.from(_transactions);
    } else {
      _filteredTransactions = _transactions.where((tx) {
        return tx.category.toLowerCase().contains(_searchQuery) ||
            (tx.note?.toLowerCase().contains(_searchQuery) ?? false) ||
            tx.amount.toString().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadMonths() async {
    final months = await db.getDistinctMonths();
    setState(() {
      _availableMonths = months;
      if (months.isNotEmpty) {
        _filterYear = months.first.year;
        _filterMonth = months.first.month;
      } else {
        final now = DateTime.now();
        _filterYear = now.year;
        _filterMonth = now.month;
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    List<Transaction> list;
    if (_filterYear != null && _filterMonth != null) {
      list = await db.getByMonth(_filterYear!, _filterMonth!);
    } else {
      list = await db.getAll();
    }
    setState(() {
      _transactions = list;
      _applyFilter();
      _loading = false;
    });
  }

  void refresh() => _loadData();

  double get _monthIncome =>
      _transactions.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);

  double get _monthExpense =>
      _transactions.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          // Month filter + search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                // Month selector
                Row(
                  children: [
                    Expanded(
                      child: _availableMonths.isNotEmpty
                          ? DropdownButtonFormField<DateTime>(
                              initialValue: _availableMonths.isNotEmpty
                                  ? _availableMonths.firstWhere(
                                      (d) => d.year == _filterYear && d.month == _filterMonth,
                                      orElse: () => _availableMonths.first,
                                    )
                                  : null,
                              items: _availableMonths.map((d) {
                                return DropdownMenuItem(
                                  value: d,
                                  child: Text('${d.year}年${d.month}月'),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _filterYear = v.year;
                                    _filterMonth = v.month;
                                  });
                                  _loadData();
                                }
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            )
                          : const Text('暂无记录'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索分类、备注、金额...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
                // Month summary
                if (_transactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Text(
                          '收入 ¥${NumberFormat('#,##0.00').format(_monthIncome)}',
                          style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '支出 ¥${NumberFormat('#,##0.00').format(_monthExpense)}',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '${_filteredTransactions.length} 条',
                          style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: theme.colorScheme.outline),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty ? '未找到匹配的记录' : '本月暂无流水',
                              style: TextStyle(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadMonths();
                          await _loadData();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (ctx, i) {
                            final tx = _filteredTransactions[i];
                            return _TransactionTile(
                              tx: tx,
                              onTap: () async {
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddTransactionScreen(transaction: tx),
                                  ),
                                );
                                if (result == true) _loadData();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onTap;
  const _TransactionTile({required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: isIncome
              ? Colors.teal.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          child: Icon(
            Categories.iconFor(tx.category),
            color: isIncome ? Colors.teal : Colors.red,
            size: 22,
          ),
        ),
        title: Text(tx.category),
        subtitle: Text(
          DateFormat('MM-dd  EEEE', 'zh_CN').format(tx.date),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${NumberFormat('#,##0.00').format(tx.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.teal.shade700 : Colors.red.shade700,
              ),
            ),
            if (tx.note != null && tx.note!.isNotEmpty)
              Text(
                tx.note!,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
