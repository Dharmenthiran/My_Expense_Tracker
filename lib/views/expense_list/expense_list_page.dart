import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:csv/csv.dart';
import '../../data/database.dart';
import '../../viewmodels/providers.dart';
import '../widgets/glass_card.dart';
import '../add_expense/add_expense_page.dart';

class ExpenseListPage extends ConsumerStatefulWidget {
  const ExpenseListPage({super.key});

  @override
  ConsumerState<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends ConsumerState<ExpenseListPage> {
  String _searchQuery = '';
  String? _selectedCategory;
  DateTime? _selectedDate;
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

  Future<void> _exportToPdf(List<Expense> expenses) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Expense Report - ${DateFormat.yMMMM().format(_selectedMonth)}',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Title', 'Amount', 'Category', 'Timing', 'Date'],
                data: expenses.map((expense) => [
                  expense.title,
                  '₹${expense.amount.toStringAsFixed(2)}',
                  expense.category.toUpperCase(),
                  expense.timing ?? '',
                  DateFormat.yMMMd().format(expense.date),
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total: ₹${expenses.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/expenses_${DateFormat('yyyy_MM').format(_selectedMonth)}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    if (mounted) {
      if (Platform.isWindows) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved to $path')),
        );
      } else {
        await Share.shareXFiles([XFile(path)], text: 'Expense Report');
      }
    }
  }

  Future<void> _exportToExcel(List<Expense> expenses) async {
    var excel = excel_pkg.Excel.createExcel();
    excel_pkg.Sheet sheetObject = excel['Expenses'];

    sheetObject.appendRow([
      excel_pkg.TextCellValue('Title'),
      excel_pkg.TextCellValue('Amount'),
      excel_pkg.TextCellValue('Type'),
      excel_pkg.TextCellValue('Category'),
      excel_pkg.TextCellValue('Timing'),
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Note'),
    ]);

    for (var expense in expenses) {
      sheetObject.appendRow([
        excel_pkg.TextCellValue(expense.title),
        excel_pkg.DoubleCellValue(expense.amount),
        excel_pkg.TextCellValue(expense.transactionType.name.toUpperCase()),
        excel_pkg.TextCellValue(expense.category.toUpperCase()),
        excel_pkg.TextCellValue(expense.timing ?? ''),
        excel_pkg.TextCellValue(DateFormat.yMMMd().format(expense.date)),
        excel_pkg.TextCellValue(expense.note ?? ''),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/expenses_${DateFormat('yyyy_MM').format(_selectedMonth)}.xlsx';
    final file = File(path);
    await file.writeAsBytes(excel.encode()!);

    if (mounted) {
      if (Platform.isWindows) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel saved to $path')),
        );
      } else {
        await Share.shareXFiles([XFile(path)], text: 'Expense Report');
      }
    }
  }

  Future<void> _exportToCsv(List<Expense> expenses) async {
    List<List<dynamic>> rows = [];
    rows.add(['Title', 'Amount', 'Type', 'Category', 'Timing', 'Date', 'Note']);

    for (var expense in expenses) {
      rows.add([
        expense.title,
        expense.amount,
        expense.transactionType.name.toUpperCase(),
        expense.category.toUpperCase(),
        expense.timing ?? '',
        DateFormat.yMMMd().format(expense.date),
        expense.note ?? '',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/expenses_${DateFormat('yyyy_MM').format(_selectedMonth)}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    if (mounted) {
      if (Platform.isWindows) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV saved to $path')),
        );
      } else {
        await Share.shareXFiles([XFile(path)], text: 'Expense Report');
      }
    }
  }

  void _showExportDialog(List<Expense> expenses) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportToPdf(expenses);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel(expenses);
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.blue),
              title: const Text('CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportToCsv(expenses);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(allExpensesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
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
                            child: Consumer(
                              builder: (context, ref, child) {
                                final categoriesAsync = ref.watch(allCategoriesProvider);
                                final categories = categoriesAsync.value ?? [];
                                return DropdownButtonFormField<String>(
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
                                    ...categories.map((category) {
                                      return DropdownMenuItem(
                                        value: category.name,
                                        child: Text(category.name.toUpperCase()),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  },
                                );
                              }
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final allExpenses = await ref.read(allExpensesProvider.future);
                    final filteredExpenses = allExpenses.where((expense) {
                      final matchesMonth = expense.date.year == _selectedMonth.year &&
                          expense.date.month == _selectedMonth.month;
                      final matchesSearch = expense.title.toLowerCase().contains(_searchQuery.toLowerCase());
                      final matchesCategory = _selectedCategory == null || expense.category == _selectedCategory;
                      final matchesDate = _selectedDate == null || isSameDay(expense.date, _selectedDate!);
                      return matchesMonth && matchesSearch && matchesCategory && matchesDate;
                    }).toList();
                    _showExportDialog(filteredExpenses);
                  },
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                final filteredExpenses = expenses.where((expense) {
                  final matchesMonth = expense.date.year == _selectedMonth.year &&
                      expense.date.month == _selectedMonth.month;
                  final matchesSearch = expense.title.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == null || expense.category == _selectedCategory;
                  final matchesDate = _selectedDate == null || isSameDay(expense.date, _selectedDate!);
                  return matchesMonth && matchesSearch && matchesCategory && matchesDate;
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddExpensePage(expenseToEdit: expense),
                  ),
                );
              },
              leading: CircleAvatar(
                backgroundColor: expense.transactionType == TransactionType.credit
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                child: Icon(
                  expense.transactionType == TransactionType.credit
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: expense.transactionType == TransactionType.credit
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${DateFormat.yMMMd().format(expense.date)} • ${expense.timing ?? ''}'),
              trailing: Text(
                NumberFormat.currency(symbol: '₹').format(expense.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: expense.transactionType == TransactionType.credit
                      ? Colors.green
                      : Colors.red,
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
            DataColumn(label: Text('Timing')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Actions')),
          ],
          rows: expenses.map((expense) {
            return DataRow(cells: [
              DataCell(Text(expense.title)),
              DataCell(Text(NumberFormat.currency(symbol: '₹').format(expense.amount))),
              DataCell(Text(expense.category.toUpperCase())),
              DataCell(Text(expense.timing ?? '')),
              DataCell(Text(DateFormat.yMMMd().format(expense.date))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddExpensePage(expenseToEdit: expense),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ref.read(expenseRepositoryProvider).deleteExpense(expense);
                      },
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
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
