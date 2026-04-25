import 'package:flutter/material.dart';

abstract final class AppTypography {
  // Display — 대형 숫자·제목 (보고서, 금액)
  static const displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );
  static const displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.16,
  );

  // Headline — 화면 제목
  static const headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  static const headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
  );
  static const headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  // Title — 카드·섹션 제목
  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.27,
  );
  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
  );
  static const titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Body — 본문
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Label — 버튼·칩
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );
  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );
  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // AppBar 제목 전용
  static const appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // 금액 표시 전용 — 태블릿 POS에서 큰 숫자 강조
  static const amountLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );
  static const amountMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.2,
  );
}
