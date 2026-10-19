import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Round Faruk Fashion logo from assets/logo.png
class BrandLogo extends StatelessWidget {
  final double size;
  final double borderWidth;
  final bool showGlow;

  const BrandLogo({
    super.key,
    this.size = 100,
    this.borderWidth = 2,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: borderWidth),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.35),
                  blurRadius: size * 0.18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.surface,
            child: Center(
              child: Text(
                'FF',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}