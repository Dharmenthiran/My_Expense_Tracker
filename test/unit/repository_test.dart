import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/data/database.dart';
import 'package:expense_tracker/repositories/expense_repository.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late AppDatabase database;
  late ExpenseRepository repository;

  setUp(() {
    // Use in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ExpenseRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('addExpense adds an expense to the database', () async {
    final expense = ExpensesCompanion(
      title: const drift.Value('Test Expense'),
      amount: const drift.Value(100.0),
      date: drift.Value(DateTime.now()),
      category: const drift.Value('food'),
    );

    await repository.addExpense(expense);

    final allExpenses = await repository.getAllExpenses();
    expect(allExpenses.length, 1);
    expect(allExpenses.first.title, 'Test Expense');
  });

  test('deleteExpense removes an expense from the database', () async {
    final expense = ExpensesCompanion(
      title: const drift.Value('Test Expense'),
      amount: const drift.Value(100.0),
      date: drift.Value(DateTime.now()),
      category: const drift.Value('food'),
    );

    await repository.addExpense(expense);
    final savedExpense = (await repository.getAllExpenses()).first;

    await repository.deleteExpense(savedExpense);

    final allExpenses = await repository.getAllExpenses();
    expect(allExpenses.isEmpty, true);
  });
  
  test('getExpensesByCategory filters expenses correctly', () async {
     await repository.addExpense(ExpensesCompanion(
      title: const drift.Value('Food'),
      amount: const drift.Value(10.0),
      date: drift.Value(DateTime.now()),
      category: const drift.Value('food'),
    ));
    
    await repository.addExpense(ExpensesCompanion(
      title: const drift.Value('Travel'),
      amount: const drift.Value(20.0),
      date: drift.Value(DateTime.now()),
      category: const drift.Value('travel'),
    ));

    final foodExpenses = await repository.getExpensesByCategory('food');
    expect(foodExpenses.length, 1);
    expect(foodExpenses.first.category, 'food');
    
    final travelExpenses = await repository.getExpensesByCategory('travel');
    expect(travelExpenses.length, 1);
    expect(travelExpenses.first.category, 'travel');
  });
}
