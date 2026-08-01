import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import '../../viewmodels/providers.dart';
import '../widgets/glass_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  List<Expense> _filterByMonth(List<Expense> expenses) {
    return expenses.where((expense) {
      return expense.date.year == _selectedMonth.year &&
          expense.date.month == _selectedMonth.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(allExpensesProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.backgroundGradientDark : AppTheme.backgroundGradientLight,
        ),
        child: SafeArea(
          child: expensesAsync.when(
            data: (allExpenses) {
              final expenses = _filterByMonth(allExpenses);
              final totalExpense = expenses.fold(0.0, (sum, item) => sum + item.amount);
              final recentTransactions = expenses.take(5).toList();
              final categoryData = _calculateCategoryData(expenses);

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                      ),
                      const SizedBox(height: 16),
                      // Month Selector
                      GlassCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _previousMonth,
                            ),
                            Text(
                              DateFormat.yMMMM().format(_selectedMonth),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _nextMonth,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Credits, Expenses, Balance Cards
                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.arrow_upward, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Credits',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              color: Colors.green,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    NumberFormat.currency(symbol: '₹').format(
                                      expenses.where((e) => e.transactionType == TransactionType.credit).fold(0.0, (sum, item) => sum + item.amount),
                                    ),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.arrow_downward, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Expenses',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              color: Colors.red,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    NumberFormat.currency(symbol: '₹').format(
                                      expenses.where((e) => e.transactionType == TransactionType.expense).fold(0.0, (sum, item) => sum + item.amount),
                                    ),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Balance',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              NumberFormat.currency(symbol: '₹').format(
                                expenses.where((e) => e.transactionType == TransactionType.credit).fold(0.0, (sum, item) => sum + item.amount) -
                                expenses.where((e) => e.transactionType == TransactionType.expense).fold(0.0, (sum, item) => sum + item.amount),
                              ),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Chart
                      if (expenses.isNotEmpty)
                        SizedBox(
                          height: 300,
                          child: GlassCard(
                            child: Column(
                              children: [
                                Text(
                                  'Expenses by Category',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: PieChart(
                                    PieChartData(
                                      sections: categoryData.entries.map((entry) {
                                        return PieChartSectionData(
                                          color: _getCategoryColor(entry.key),
                                          value: entry.value,
                                          title: '${(entry.value / totalExpense * 100).toStringAsFixed(1)}%',
                                          radius: 60,
                                          titleStyle: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                                          ),
                                          badgeWidget: _Badge(
                                            _getCategoryIcon(entry.key),
                                            size: 30,
                                            borderColor: _getCategoryColor(entry.key),
                                          ),
                                          badgePositionPercentageOffset: .98,
                                        );
                                      }).toList(),
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: categoryData.keys.map((category) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor(category),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          category.toUpperCase(),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (recentTransactions.isEmpty)
                        const Center(child: Text('No recent transactions'))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentTransactions.length,
                          itemBuilder: (context, index) {
                            final expense = recentTransactions[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 400 + (index * 100)),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(50 * (1 - value), 0),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                color: Colors.transparent,
                                child: GlassCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
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
                                      NumberFormat.currency(symbol: '₹').format(expense.amount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ),
    );
  }

  Map<String, double> _calculateCategoryData(List<Expense> expenses) {
    final data = <String, double>{};
    for (var expense in expenses) {
      data[expense.category] = (data[expense.category] ?? 0) + expense.amount;
    }
    return data;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'travel':
        return Colors.blue;
      case 'shopping':
        return Colors.pink;
      case 'bills':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'travel':
        return Icons.flight;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt;
      default:
        return Icons.category;
    }
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color borderColor;

  const _Badge(
    this.icon, {
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(
        child: Icon(
          icon,
          color: borderColor,
          size: size * 0.6,
        ),
      ),
    );
  }
}
