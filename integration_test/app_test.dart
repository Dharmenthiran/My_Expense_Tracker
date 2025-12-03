import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:expense_tracker/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add Expense Flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Navigate to Add Expense
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    // Fill Form
    await tester.enterText(find.byType(TextFormField).at(0), 'Integration Test Expense');
    await tester.enterText(find.byType(TextFormField).at(1), '123.45');
    
    // Save
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    // Verify Success SnackBar
    expect(find.text('Expense added successfully!'), findsOneWidget);

    // Navigate to History
    await tester.tap(find.byIcon(Icons.list_alt_outlined));
    await tester.pumpAndSettle();

    // Verify Expense in List
    expect(find.text('Integration Test Expense'), findsOneWidget);
    expect(find.text('\$123.45'), findsOneWidget);
  });
}
