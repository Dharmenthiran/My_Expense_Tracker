import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/views/dashboard/dashboard_page.dart';
import 'package:expense_tracker/viewmodels/providers.dart';
import 'package:expense_tracker/data/database.dart';
import 'package:expense_tracker/core/theme.dart';

void main() {
  testWidgets('DashboardPage renders total expense and transactions', (WidgetTester tester) async {
    final expenses = [
      Expense(
        id: 1,
        title: 'Test Food',
        amount: 50.0,
        date: DateTime.now(),
        category: ExpenseCategory.food,
        note: 'Yummy',
      ),
      Expense(
        id: 2,
        title: 'Test Travel',
        amount: 100.0,
        date: DateTime.now(),
        category: ExpenseCategory.travel,
        note: 'Fun',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allExpensesProvider.overrideWith((ref) => Stream.value(expenses)),
          themeModeProvider.overrideWith(() => ThemeModeNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardPage(),
        ),
      ),
    );

    // Wait for the stream to emit
    await tester.pumpAndSettle();

    // Verify Total Expense
    expect(find.text('\$150.00'), findsOneWidget);

    // Verify Transactions
    expect(find.text('Test Food'), findsOneWidget);
    expect(find.text('Test Travel'), findsOneWidget);
  });
}
