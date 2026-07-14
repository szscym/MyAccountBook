import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final db = DatabaseHelper.instance;

  TransactionType _type = TransactionType.expense;
  String _category = '';
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final tx = widget.transaction!;
      _type = tx.type;
      _category = tx.category;
      _date = tx.date;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';
    } else {
      _category = Categories.items[_type]!.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = Categories.items[_type]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑记录' : '记一笔'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除',
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Type toggle
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('支出'),
                  icon: Icon(Icons.trending_down),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('收入'),
                  icon: Icon(Icons.trending_up),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) {
                setState(() {
                  _type = set.first;
                  _category = Categories.items[_type]!.first;
                });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _type == TransactionType.income
                        ? Colors.teal.shade50
                        : Colors.red.shade50;
                  }
                  return null;
                }),
              ),
            ),
            const SizedBox(height: 24),

            // Amount input
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: !_isEditing,
              decoration: const InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '请输入金额';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return '请输入有效金额';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category picker
            Text(
              '分类',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final selected = _category == cat;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Categories.iconFor(cat),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(cat),
                    ],
                  ),
                  selected: selected,
                  onSelected: (v) {
                    if (v) setState(() => _category = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('日期'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_date)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 20),

            // Note input
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（选填）',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isEditing ? '保存修改' : '确认记账'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final amount = double.parse(_amountController.text);
    final tx = Transaction(
      id: widget.transaction?.id,
      type: _type,
      amount: amount,
      category: _category,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      date: _date,
    );

    if (_isEditing) {
      await db.update(tx);
    } else {
      await db.insert(tx);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true && widget.transaction != null) {
      await db.delete(widget.transaction!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }
}
