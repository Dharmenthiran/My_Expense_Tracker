import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '0';
  String _expression = '';

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _display = '0';
        _expression = '';
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
          _display = _expression.isEmpty ? '0' : _expression;
        }
      } else if (value == '=') {
        try {
          Parser p = Parser();
          Expression exp = p.parse(_expression.replaceAll('×', '*').replaceAll('÷', '/'));
          ContextModel cm = ContextModel();
          double eval = exp.evaluate(EvaluationType.REAL, cm);
          _display = eval.toString();
          _expression = eval.toString();
        } catch (e) {
          _display = 'Error';
        }
      } else {
        if (_display == '0' && value != '.') {
          _expression = value;
        } else {
          _expression += value;
        }
        _display = _expression;
      }
    });
  }

  Widget _buildButton(String text, {Color? color, Color? textColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => _onButtonPressed(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Theme.of(context).colorScheme.surfaceVariant,
            foregroundColor: textColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final operatorColor = Theme.of(context).colorScheme.primary;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calculator',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _display,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    _buildButton('C', color: Colors.red[400], textColor: Colors.white),
                    _buildButton('⌫', color: Colors.orange[400], textColor: Colors.white),
                    _buildButton('÷', color: operatorColor, textColor: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('7'),
                    _buildButton('8'),
                    _buildButton('9'),
                    _buildButton('×', color: operatorColor, textColor: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('4'),
                    _buildButton('5'),
                    _buildButton('6'),
                    _buildButton('-', color: operatorColor, textColor: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('1'),
                    _buildButton('2'),
                    _buildButton('3'),
                    _buildButton('+', color: operatorColor, textColor: Colors.white),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('0'),
                    _buildButton('.'),
                    _buildButton('=', color: Colors.green[600], textColor: Colors.white),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
