import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/database.dart';
import '../../viewmodels/providers.dart';
import '../widgets/glass_card.dart';

class ExpenseListPage extends ConsumerStatefulWidget {
  const ExpenseListPage({super.key});

  @override
  ConsumerState<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends ConsumerState<ExpenseListPage> {
  String _searchQuery = '';
  ExpenseCategory? _selectedCategory;
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(allExpensesProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Expense History',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                // Search and Filter Bar
                GlassCard(
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search expenses...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ExpenseCategory>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All'),
                                ),
                                ...ExpenseCategory.values.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(category.name.toUpperCase()),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Icon(
                              Icons.calendar_today,
                              color: _selectedDate != null ? Theme.of(context).primaryColor : null,
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                });
                              }
                            },
                          ),
                          if (_selectedDate != null)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                final filteredExpenses = expenses.where((expense) {
                  final matchesSearch = expense.title.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == null || expense.category == _selectedCategory;
                  final matchesDate = _selectedDate == null || isSameDay(expense.date, _selectedDate!);
                  return matchesSearch && matchesCategory && matchesDate;
                }).toList();

                if (filteredExpenses.isEmpty) {
                  return const Center(child: Text('No expenses found'));
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      return _buildTableView(filteredExpenses);
                    } else {
                      return _buildListView(filteredExpenses);
                    }
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildListView(List<Expense> expenses) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Dismissible(
          key: Key(expense.id.toString()),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            ref.read(expenseRepositoryProvider).deleteExpense(expense);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense deleted')),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getCategoryColor(expense.category).withOpacity(0.2),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: _getCategoryColor(expense.category),
                ),
              ),
              title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat.yMMMd().format(expense.date)),
              trailing: Text(
                NumberFormat.currency(symbol: '\$').format(expense.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView(List<Expense> expenses) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Actions')),
          ],
          rows: expenses.map((expense) {
            return DataRow(cells: [
              DataCell(Text(expense.title)),
              DataCell(Text(NumberFormat.currency(symbol: '\$').format(expense.amount))),
              DataCell(Text(expense.category.name.toUpperCase())),
              DataCell(Text(DateFormat.yMMMd().format(expense.date))),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ref.read(expenseRepositoryProvider).deleteExpense(expense);
                  },
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.travel:
        return Colors.blue;
      case ExpenseCategory.shopping:
        return Colors.pink;
      case ExpenseCategory.bills:
        return Colors.red;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.fastfood;
      case ExpenseCategory.travel:
        return Icons.flight;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.bills:
        return Icons.receipt;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }
}
