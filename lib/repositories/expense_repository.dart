import 'package:drift/drift.dart';
import '../data/database.dart';

class ExpenseRepository {
  final AppDatabase _db;

  ExpenseRepository(this._db);

  Future<List<Expense>> getAllExpenses() => _db.select(_db.expenses).get();

  Stream<List<Expense>> watchAllExpenses() {
    return (_db.select(_db.expenses)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<int> addExpense(ExpensesCompanion expense) =>
      _db.into(_db.expenses).insert(expense);

  Future<bool> updateExpense(Expense expense) =>
      _db.update(_db.expenses).replace(expense);

  Future<int> deleteExpense(Expense expense) =>
      _db.delete(_db.expenses).delete(expense);

  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category) {
    return (_db.select(_db.expenses)
          ..where((t) => t.category.equals(category.name)))
        .get();
  }
  
  Stream<List<Expense>> watchExpensesByMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1).subtract(const Duration(seconds: 1));
    
    return (_db.select(_db.expenses)
      ..where((t) => t.date.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
      .watch();
  }
}
