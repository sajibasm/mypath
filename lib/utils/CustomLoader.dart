import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;

  const CustomLoader({
    super.key,
    this.size = 40,
    this.strokeWidth = 3.5,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}
