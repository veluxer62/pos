import 'package:flutter/material.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';
import 'package:pos/presentation/theme/app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          error: AppColors.error,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceContainerHighest: AppColors.surfaceVariant,
          outline: AppColors.outline,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: const TextTheme(
          displayLarge: AppTypography.displayLarge,
          displayMedium: AppTypography.displayMedium,
          headlineLarge: AppTypography.headlineLarge,
          headlineMedium: AppTypography.headlineMedium,
          headlineSmall: AppTypography.headlineSmall,
          titleLarge: AppTypography.titleLarge,
          titleMedium: AppTypography.titleMedium,
          titleSmall: AppTypography.titleSmall,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.bodyMedium,
          bodySmall: AppTypography.bodySmall,
          labelLarge: AppTypography.labelLarge,
          labelMedium: AppTypography.labelMedium,
          labelSmall: AppTypography.labelSmall,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          color: AppColors.surface,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          titleTextStyle: AppTypography.appBarTitle.copyWith(
            color: AppColors.onPrimary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, AppSpacing.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, AppSpacing.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppSpacing.minTouchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.outline,
          thickness: AppSpacing.borderWidth,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
}
