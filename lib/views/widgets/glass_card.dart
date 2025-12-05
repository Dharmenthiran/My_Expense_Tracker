import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: height,
            width: width,
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isDark ? AppTheme.glassGradientDark : AppTheme.glassGradientLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
