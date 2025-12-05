import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database.dart';
import '../../viewmodels/providers.dart';
import '../../viewmodels/navigation_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glass_card.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  final Expense? expenseToEdit;
  const AddExpensePage({super.key, this.expenseToEdit});

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  TransactionType _transactionType = TransactionType.expense;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      final expense = widget.expenseToEdit!;
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toString();
      _noteController.text = expense.note ?? '';
      _selectedDate = expense.date;
      _selectedCategory = expense.category;
      _transactionType = expense.transactionType;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      try {
        if (widget.expenseToEdit != null) {
          // Update existing expense
          final updatedExpense = widget.expenseToEdit!.copyWith(
            title: _titleController.text,
            amount: amount,
            date: _selectedDate,
            category: _selectedCategory,
            note: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
            transactionType: _transactionType,
          );
          
          await ref.read(expenseRepositoryProvider).updateExpense(updatedExpense);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense updated successfully!')),
            );
            Navigator.pop(context); // Go back to history
          }
        } else {
          // Add new expense
          final expense = ExpensesCompanion(
            title: drift.Value(_titleController.text),
            amount: drift.Value(amount),
            date: drift.Value(_selectedDate),
            category: drift.Value(_selectedCategory),
            note: drift.Value(_noteController.text.isEmpty ? null : _noteController.text),
            transactionType: drift.Value(_transactionType),
          );

          await ref.read(expenseRepositoryProvider).addExpense(expense);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense added successfully!')),
            );
            _clearForm();
            // Redirect to Dashboard
            ref.read(navigationIndexProvider.notifier).setIndex(0);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving expense: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedCategory = ExpenseCategory.food;
      _transactionType = TransactionType.expense;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expenseToEdit != null;
    
    return Scaffold(
      appBar: isEditing ? AppBar(title: const Text('Edit Expense')) : null,
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isEditing)
              Text(
                'Add Expense',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            const SizedBox(height: 20),
            GlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ExpenseCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: ExpenseCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Transaction Type Selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Type',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        color: _transactionType == TransactionType.expense
                                            ? Colors.white
                                            : Colors.red,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Expense'),
                                    ],
                                  ),
                                  selected: _transactionType == TransactionType.expense,
                                  selectedColor: Colors.red,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _transactionType = TransactionType.expense;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceChip(
                                  label: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        color: _transactionType == TransactionType.credit
                                            ? Colors.white
                                            : Colors.green,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Credit'),
                                    ],
                                  ),
                                  selected: _transactionType == TransactionType.credit,
                                  selectedColor: Colors.green,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _transactionType = TransactionType.credit;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat.yMMMd().format(_selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: isEditing ? 'Update Expense' : 'Save Expense',
                      onPressed: _saveExpense,
                      isLoading: _isLoading,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
