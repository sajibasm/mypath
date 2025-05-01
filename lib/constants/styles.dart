import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {

  static const double pageHorizontalPadding = 24.0;
  static const double pageVerticalPadding = 24.0;
  static const double buttonHorizontalPadding = 24.0;
  static const double buttonVerticalPadding = 12.0;


  static const double inputFieldSpacing = 20.0;
  static const double buttonSpacing = 12.0;
  static const double buttonPaddingVertical = 16.0;
  static const double pagePadding = 24.0; // general padding



  /// 🟦 Big screen headers like "Welcome", "Reset Password"
  static const TextStyle header = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );


/// 🟦 App title shown on light background (e.g., 'MyPath')
static const TextStyle title = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: AppColors.black, // use black for white backgrounds
);
  /// 🟩 Subtitles or section headers
  static const TextStyle subtitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  /// 🟨 Form field labels like "Email address"
  static const TextStyle label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.greyText,
  );

  /// 🟫 Form field hints like "example@email.com"
  static const TextStyle formHint = TextStyle(
    fontSize: 14,
    color: AppColors.greyText,
    fontWeight: FontWeight.normal,
  );

  /// 🟦 Primary button text (Login, Submit)
  static const TextStyle primaryButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );


  /// 🟧 Outlined button text (Sign Up)
  static const TextStyle outlinedButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  /// 🟥 Links (Reset Password)
  static const TextStyle link = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );



}
