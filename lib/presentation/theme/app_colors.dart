import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary — 인디고 계열 (POS 전문성)
  static const primary = Color(0xFF3F51B5);
  static const primaryLight = Color(0xFF757DE8);
  static const primaryDark = Color(0xFF002984);
  static const onPrimary = Color(0xFFFFFFFF);

  // Secondary — 앰버 (강조·액션)
  static const secondary = Color(0xFFFFA000);
  static const secondaryLight = Color(0xFFFFD149);
  static const secondaryDark = Color(0xFFC67100);
  static const onSecondary = Color(0xFF000000);

  // Status
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);
  static const error = Color(0xFFC62828);
  static const errorLight = Color(0xFFFFEBEE);
  static const warning = Color(0xFFE65100);
  static const warningLight = Color(0xFFFFF3E0);
  static const info = Color(0xFF0277BD);
  static const infoLight = Color(0xFFE1F5FE);

  // Neutral
  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEEEEEE);
  static const outline = Color(0xFFBDBDBD);
  static const outlineDark = Color(0xFF757575);

  // Text
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textDisabled = Color(0xFFBDBDBD);
  static const textOnDark = Color(0xFFFFFFFF);

  // Order status
  static const statusPending = Color(0xFF1565C0);
  static const statusPendingBg = Color(0xFFE3F2FD);
  // success와 동일한 값 — 전달 완료는 긍정적 완료 상태이므로 의도적으로 같은 색상 사용
  static const statusDelivered = Color(0xFF2E7D32);
  static const statusDeliveredBg = Color(0xFFE8F5E9);
  static const statusPaid = Color(0xFF4E342E);
  static const statusPaidBg = Color(0xFFEFEBE9);
  static const statusCredited = Color(0xFF6A1B9A);
  static const statusCreditedBg = Color(0xFFF3E5F5);
  static const statusCancelled = Color(0xFF757575);
  static const statusCancelledBg = Color(0xFFF5F5F5);
  static const statusRefunded = Color(0xFFE65100);
  static const statusRefundedBg = Color(0xFFFFF3E0);
}
