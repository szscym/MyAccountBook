import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import 'transactions_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _pages = const [
    _OverviewTab(),
    TransactionsScreen(),
    StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        animationDuration: const Duration(milliseconds: 300),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '\u9996\u9875'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: '\u6d41\u6c34'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: '\u7edf\u8ba1'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
          if (mounted) setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('\u8bb0\u4e00\u7b14'),
      ),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final db = DatabaseHelper.instance;
  late int _year;
  late int _month;
  double _income = 0;
  double _expense = 0;
  List<Transaction> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final income = await db.getMonthlyIncome(_year, _month);
    final expense = await db.getMonthlyExpense(_year, _month);
    final all = await db.getByMonth(_year, _month);
    setState(() { _income = income; _expense = expense; _recent = all.take(5).toList(); _loading = false; });
  }

  String get _monthLabel => '$_year\u5e74$_month\u6708';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = _income - _expense;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
                Text(_monthLabel, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: balance >= 0 ? [Colors.teal.shade400, Colors.teal.shade600] : [Colors.red.shade300, Colors.red.shade500],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('\u672c\u6708\u7ed3\u4f59', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('${balance >= 0 ? '+' : ''}${NumberFormat('#,##0.00').format(balance)}', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniStat('\u6536\u5165', _income, Colors.white60, Colors.white),
                      Container(width: 1, height: 32, color: Colors.white24),
                      _miniStat('\u652f\u51fa', _expense, Colors.white60, Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\u6700\u8fd1\u6d41\u6c34', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () { final s = context.findAncestorStateOfType<_HomeScreenState>(); s?.setState(() => s._currentIndex = 1); }, child: const Text('\u67e5\u770b\u5168\u90e8')),
              ],
            ),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
            else if (_recent.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Column(children: [Icon(Icons.receipt_long, size: 48, color: theme.colorScheme.outline), const SizedBox(height: 8), Text('\u672c\u6708\u8fd8\u6ca1\u6709\u8bb0\u5f55\uff0c\u8bb0\u4e00\u7b14\u5427', style: TextStyle(color: theme.colorScheme.outline))])))
            else
              ..._recent.map((tx) => _TransactionCard(tx: tx)),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, double amount, Color labelColor, Color amountColor) {
    return Column(children: [Text(label, style: TextStyle(color: labelColor, fontSize: 12)), const SizedBox(height: 4), Text(NumberFormat('#,##0.00').format(amount), style: TextStyle(color: amountColor, fontWeight: FontWeight.w600, fontSize: 16))]);
  }

  void _prevMonth() { setState(() { if (_month == 1) { _year--; _month = 12; } else { _month--; } }); _loadData(); }
  void _nextMonth() { setState(() { if (_month == 12) { _year++; _month = 1; } else { _month++; } }); _loadData(); }
}

class _TransactionCard extends StatelessWidget {
  final Transaction tx;
  const _TransactionCard({required this.tx});
  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.teal.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
          child: Icon(Categories.iconFor(tx.category), color: isIncome ? Colors.teal : Colors.red, size: 22),
        ),
        title: Text(tx.category),
        subtitle: Text(DateFormat('MM-dd').format(tx.date)),
        trailing: Text('${isIncome ? '+' : '-'}${NumberFormat('#,##0.00').format(tx.amount)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isIncome ? Colors.teal.shade700 : Colors.red.shade700)),
      ),
    );
  }
}
