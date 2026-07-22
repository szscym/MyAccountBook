import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Use GlobalKeys to access child state for refreshing
  final _overviewKey = GlobalKey<_OverviewTabState>();
  final _transactionsKey = GlobalKey<TransactionsScreenState>();
  final _statisticsKey = GlobalKey<StatisticsScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _OverviewTab(key: _overviewKey),
          TransactionsScreen(key: _transactionsKey),
          StatisticsScreen(key: _statisticsKey),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          // Refresh data when switching to a tab
          if (i == 0) _overviewKey.currentState?.refresh();
          if (i == 1) _transactionsKey.currentState?.refresh();
          if (i == 2) _statisticsKey.currentState?.refresh();
        },
        animationDuration: const Duration(milliseconds: 300),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: '流水'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: '统计'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
          if (mounted) {
            // Refresh all visible data after adding a transaction
            _overviewKey.currentState?.refresh();
            _transactionsKey.currentState?.refresh();
            _statisticsKey.currentState?.refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
    );
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab({super.key});
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final db = DatabaseHelper.instance;
  late int _year;
  late int _month;
  double _income = 0;
  double _expense = 0;
  double _monthlyBudget = 0;
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

  /// Public method so parent can trigger refresh
  void refresh() => _loadData();

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      db.getMonthlyIncome(_year, _month),
      db.getMonthlyExpense(_year, _month),
      db.getByMonth(_year, _month),
      _loadBudget(),
    ]);
    if (mounted) {
      setState(() {
        _income = results[0] as double;
        _expense = results[1] as double;
        _recent = (results[2] as List<Transaction>).take(5).toList();
        _monthlyBudget = results[3] as double;
        _loading = false;
      });
    }
  }

  Future<double> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'budget_$_year-${_month.toString().padLeft(2, '0')}';
    return prefs.getDouble(key) ?? 0;
  }

  Future<void> _setBudget() async {
    final controller = TextEditingController(text: _monthlyBudget > 0 ? _monthlyBudget.toStringAsFixed(0) : '');
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置月度预算'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: '¥ ',
            labelText: '预算金额',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'budget_$_year-${_month.toString().padLeft(2, '0')}';
      if (result > 0) {
        await prefs.setDouble(key, result);
      } else {
        await prefs.remove(key);
      }
      _loadData();
    }
  }

  String get _monthLabel => '$_year年$_month月';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final balance = _income - _expense;
    final budgetPercent = _monthlyBudget > 0 ? _expense / _monthlyBudget : 0.0;
    final budgetOverspent = budgetPercent > 1.0;

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
            // Balance card — tap to set budget
            GestureDetector(
              onTap: _setBudget,
              child: Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('本月结余', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 14, color: Colors.white.withValues(alpha: 0.6)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${balance >= 0 ? '+' : ''}${NumberFormat('#,##0.00').format(balance)}',
                      style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    if (_monthlyBudget > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        '预算 ¥${NumberFormat('#,##0').format(_monthlyBudget)} | 已花 ${(budgetPercent * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: budgetOverspent ? Colors.yellow.shade200 : Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: budgetPercent.clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            budgetOverspent ? Colors.yellow.shade400 : Colors.white,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _miniStat('收入', _income, Colors.white60, Colors.white),
                        Container(width: 1, height: 32, color: Colors.white24),
                        _miniStat('支出', _expense, Colors.white60, Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('最近流水', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    final s = context.findAncestorStateOfType<_HomeScreenState>();
                    s?.setState(() => s._currentIndex = 1);
                  },
                  child: const Text('查看全部'),
                ),
              ],
            ),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
            else if (_recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: theme.colorScheme.outline),
                      const SizedBox(height: 8),
                      Text('本月还没有记录，记一笔吧', style: TextStyle(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
              )
            else
              ..._recent.map((tx) => _TransactionCard(
                    tx: tx,
                    onTap: () async {
                      await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => AddTransactionScreen(transaction: tx)),
                      );
                      _loadData();
                    },
                  )),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, double amount, Color labelColor, Color amountColor) {
    return Column(children: [
      Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
      const SizedBox(height: 4),
      Text(NumberFormat('#,##0.00').format(amount), style: TextStyle(color: amountColor, fontWeight: FontWeight.w600, fontSize: 16)),
    ]);
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) { _year--; _month = 12; } else { _month--; }
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) { _year++; _month = 1; } else { _month++; }
    });
    _loadData();
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction tx;
  final VoidCallback? onTap;
  const _TransactionCard({required this.tx, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.teal.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
          child: Icon(Categories.iconFor(tx.category), color: isIncome ? Colors.teal : Colors.red, size: 22),
        ),
        title: Text(tx.category),
        subtitle: Text(DateFormat('MM-dd').format(tx.date)),
        trailing: Text('${isIncome ? '+' : '-'}${NumberFormat('#,##0.00').format(tx.amount)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isIncome ? Colors.teal.shade700 : Colors.red.shade700)),
      ),
    );
  }
}
