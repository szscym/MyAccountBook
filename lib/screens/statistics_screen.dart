import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final db = DatabaseHelper.instance;
  DateTime _selectedMonth = DateTime.now();
  double _income = 0;
  double _expense = 0;
  Map<String, double> _expenseBreakdown = {};
  Map<String, double> _incomeBreakdown = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final y = _selectedMonth.year;
    final m = _selectedMonth.month;
    final results = await Future.wait([
      db.getMonthlyIncome(y, m),
      db.getMonthlyExpense(y, m),
      db.getCategoryBreakdown(y, m, TransactionType.expense),
      db.getCategoryBreakdown(y, m, TransactionType.income),
    ]);
    setState(() {
      _income = results[0] as double;
      _expense = results[1] as double;
      _expenseBreakdown = results[2] as Map<String, double>;
      _incomeBreakdown = results[3] as Map<String, double>;
      _loading = false;
    });
  }

  void _prevMonth() {
    setState(() {
      if (_selectedMonth.month == 1) {
        _selectedMonth = DateTime(_selectedMonth.year - 1, 12);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      }
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth.month == 12) {
        _selectedMonth = DateTime(_selectedMonth.year + 1, 1);
      } else {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthLabel = '${_selectedMonth.year}年${_selectedMonth.month}月';
    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
                      Text(monthLabel, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _SummaryCard(label: '收入', amount: _income, color: Colors.teal)),
                      const SizedBox(width: 12),
                      Expanded(child: _SummaryCard(label: '支出', amount: _expense, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_expense > 0 && _expenseBreakdown.isNotEmpty) ...[
                    Text('支出分类', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(height: 220, child: _PieChartSection(breakdown: _expenseBreakdown, total: _expense, colorList: _expenseColors)),
                    const SizedBox(height: 8),
                    ..._buildLegend(_expenseBreakdown, false),
                  ],
                  const SizedBox(height: 24),
                  if (_income > 0 && _incomeBreakdown.isNotEmpty) ...[
                    Text('收入分类', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(height: 220, child: _PieChartSection(breakdown: _incomeBreakdown, total: _income, colorList: _incomeColors)),
                    const SizedBox(height: 8),
                    ..._buildLegend(_incomeBreakdown, true),
                  ],
                  if (_expense == 0 && _income == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('本月暂无数据', style: TextStyle(color: theme.colorScheme.outline))),
                    ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildLegend(Map<String, double> breakdown, bool isIncome) {
    final colors = isIncome ? _incomeColors : _expenseColors;
    final entries = breakdown.entries.toList();
    final total = isIncome ? _income : _expense;
    return entries.asMap().entries.map((e) {
      final i = e.key;
      final entry = e.value;
      final pct = (entry.value / total * 100);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(entry.key, style: const TextStyle(fontSize: 12)),
            const Spacer(),
            Text('${NumberFormat('#,##0.00').format(entry.value)} (${pct.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      );
    }).toList();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummaryCard({required this.label, required this.amount, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 13)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(NumberFormat('#,##0.00').format(amount), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20))),
        ],
      ),
    );
  }
}

class _PieChartSection extends StatelessWidget {
  final Map<String, double> breakdown;
  final double total;
  final List<Color> colorList;
  const _PieChartSection({required this.breakdown, required this.total, required this.colorList});
  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    final entries = breakdown.entries.toList();
    return PieChart(
      PieChartData(
        sections: entries.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          final pct = entry.value / total * 100;
          return PieChartSectionData(
            value: entry.value,
            color: colorList[i % colorList.length],
            radius: 60,
            title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
            titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
}

const _expenseColors = [Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFFFDD835), Color(0xFF43A047), Color(0xFF1E88E5), Color(0xFF8E24AA), Color(0xFF00ACC1), Color(0xFF6D4C41), Color(0xFF546E7A)];

const _incomeColors = [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A), Color(0xFF4DB6AC), Color(0xFF80CBC4)];
