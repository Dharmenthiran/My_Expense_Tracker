import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../viewmodels/providers.dart';
import '../widgets/glass_card.dart';
import '../widgets/calculator_dialog.dart';
import '../profile/profile_page.dart';
import 'category_list_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _exportToCsv(BuildContext context, WidgetRef ref) async {
    final expenses = await ref.read(allExpensesProvider.future);
    
    List<List<dynamic>> rows = [];
    rows.add(["ID", "Title", "Amount", "Category", "Timing", "Date", "Note"]);
    
    for (var expense in expenses) {
      rows.add([
        expense.id,
        expense.title,
        expense.amount,
        expense.category,
        expense.timing ?? '',
        expense.date.toIso8601String(),
        expense.transactionType.name,
        expense.note
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/expenses_export.csv";
    final file = File(path);
    await file.writeAsString(csv);
    
    if (Platform.isWindows) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to $path')),
      );
    } else {
      await Share.shareXFiles([XFile(path)], text: 'My Expenses');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Enable dark theme'),
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                    secondary: Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Profile'),
                    subtitle: const Text('Manage your profile'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilePage()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Manage Categories'),
                    subtitle: const Text('Add or remove expense categories'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CategoryListPage()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.calculate, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Calculator'),
                    subtitle: const Text('Quick calculator'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const CalculatorDialog(),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.download, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Export Data'),
                    subtitle: const Text('Export expenses to CSV'),
                    onTap: () => _exportToCsv(context, ref),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                    title: const Text('About'),
                    subtitle: const Text('Expense Tracker v2.0.0'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
