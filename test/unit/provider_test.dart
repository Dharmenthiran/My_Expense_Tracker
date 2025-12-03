import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/viewmodels/providers.dart';

void main() {
  test('ThemeModeNotifier toggles theme', () async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({'isDarkMode': false});
    
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state should be false (light mode)
    expect(container.read(themeModeProvider), false);

    // Toggle theme
    await container.read(themeModeProvider.notifier).toggleTheme();

    // State should be true (dark mode)
    expect(container.read(themeModeProvider), true);
    
    // Verify persistence
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('isDarkMode'), true);
  });
}
