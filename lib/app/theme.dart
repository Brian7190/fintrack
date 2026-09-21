import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==================================================
  // IDENTIDAD PRINCIPAL
  // ==================================================

  static const Color primary = Color(0xFF2F7D73);
  static const Color primaryDark = Color(0xFF245F58);
  static const Color primarySoft = Color(0xFFD9E9E6);

  // ==================================================
  // FONDOS
  // ==================================================

  static const Color background = Color(0xFFE7ECEA);
  static const Color surface = Color(0xFFF6F8F7);
  static const Color surfaceAlt = Color(0xFFEEF3F1);

  // ==================================================
  // TEXTO
  // ==================================================

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFF8FAF9);

  // ==================================================
  // BORDES
  // ==================================================

  static const Color border = Color(0xFFD2DBD8);

  // ==================================================
  // SEMÁFORO FINANCIERO
  // ==================================================

  // Estado saludable
  static const Color success = Color(0xFF2F7D73);
  static const Color successSoft = Color(0xFFDCEBE8);

  // Precaución
  static const Color warning = Color(0xFFB88723);
  static const Color warningSoft = Color(0xFFF6EDD8);

  // Riesgo alto
  static const Color danger = Color(0xFFB85A3F);
  static const Color dangerSoft = Color(0xFFF4E3DE);

  // Presupuesto excedido
  static const Color error = Color(0xFF9F2D26);
  static const Color errorSoft = Color(0xFFF4DDDB);
}

// ====================================================
// ESTADO DEL SEMÁFORO
// ====================================================

enum BudgetSignalStatus { healthy, warning, danger, exceeded }

// ====================================================
// LÓGICA DEL SEMÁFORO
// ====================================================

class BudgetSignal {
  final BudgetSignalStatus status;
  final double progress;
  final double percentageUsed;

  final Color primaryColor;
  final Color softColor;

  final String label;
  final String message;

  const BudgetSignal({
    required this.status,
    required this.progress,
    required this.percentageUsed,
    required this.primaryColor,
    required this.softColor,
    required this.label,
    required this.message,
  });

  static BudgetSignal from({required double budget, required double spent}) {
    // ==================================================
    // SIN PRESUPUESTO
    // ==================================================

    if (budget <= 0) {
      return const BudgetSignal(
        status: BudgetSignalStatus.warning,
        progress: 0,
        percentageUsed: 0,
        primaryColor: AppColors.warning,
        softColor: AppColors.warningSoft,
        label: 'Sin presupuesto',
        message:
            'Configura un presupuesto mensual para comenzar a controlar tus gastos.',
      );
    }

    final percentageUsed = (spent / budget) * 100;

    final progress = (spent / budget).clamp(0.0, 1.0).toDouble();

    // ==================================================
    // MÁS DEL 100%
    // ==================================================

    if (spent > budget) {
      return BudgetSignal(
        status: BudgetSignalStatus.exceeded,
        progress: 1,
        percentageUsed: percentageUsed,
        primaryColor: AppColors.error,
        softColor: AppColors.errorSoft,
        label: 'Presupuesto excedido',
        message: 'Has superado el presupuesto establecido para este mes.',
      );
    }

    // ==================================================
    // 90% - 100%
    // ==================================================

    if (percentageUsed >= 90) {
      return BudgetSignal(
        status: BudgetSignalStatus.danger,
        progress: progress,
        percentageUsed: percentageUsed,
        primaryColor: AppColors.danger,
        softColor: AppColors.dangerSoft,
        label: 'Riesgo alto',
        message: 'Estás muy cerca de alcanzar el límite de tu presupuesto.',
      );
    }

    // ==================================================
    // 60% - 89%
    // ==================================================

    if (percentageUsed >= 60) {
      return BudgetSignal(
        status: BudgetSignalStatus.warning,
        progress: progress,
        percentageUsed: percentageUsed,
        primaryColor: AppColors.warning,
        softColor: AppColors.warningSoft,
        label: 'Cuidado',
        message:
            'Ya utilizaste una parte importante de tu presupuesto mensual.',
      );
    }

    // ==================================================
    // 0% - 59%
    // ==================================================

    return BudgetSignal(
      status: BudgetSignalStatus.healthy,
      progress: progress,
      percentageUsed: percentageUsed,
      primaryColor: AppColors.success,
      softColor: AppColors.successSoft,
      label: 'Saludable',
      message: 'Tu presupuesto se encuentra dentro de un nivel saludable.',
    );
  }
}

// ====================================================
// TEMA GENERAL
// ====================================================

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.primaryDark,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: AppColors.background,

      fontFamily: 'Roboto',

      // ==================================================
      // TEXTOS
      // ==================================================
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
      ),

      // ==================================================
      // APP BAR
      // ==================================================
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceAlt,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // ==================================================
      // INPUTS
      // ==================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        helperStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.primaryDark,
        suffixIconColor: AppColors.textSecondary,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // ==================================================
      // BOTONES PRINCIPALES
      // ==================================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ==================================================
      // BOTONES CON BORDE
      // ==================================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ==================================================
      // BOTONES DE TEXTO
      // ==================================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // ==================================================
      // FLOATING ACTION BUTTON
      // ==================================================
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      // ==================================================
      // NAVEGACIÓN INFERIOR
      // ==================================================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 70,
        indicatorColor: AppColors.primarySoft,

        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }

          return const TextStyle(color: AppColors.textSecondary, fontSize: 12);
        }),

        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryDark);
          }

          return const IconThemeData(color: AppColors.textSecondary);
        }),
      ),

      // ==================================================
      // TARJETAS
      // ==================================================
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // ==================================================
      // DIÁLOGOS
      // ==================================================
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // ==================================================
      // BOTTOM SHEETS
      // ==================================================
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        showDragHandle: true,
      ),

      // ==================================================
      // SNACKBAR
      // ==================================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ==================================================
      // PROGRESO
      // ==================================================
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
      ),

      // ==================================================
      // ICONOS
      // ==================================================
      iconTheme: const IconThemeData(color: AppColors.textPrimary),

      // ==================================================
      // LIST TILE
      // ==================================================
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.primaryDark,
      ),

      // ==================================================
      // DIVISORES
      // ==================================================
      dividerColor: AppColors.border,

      // ==================================================
      // DATE PICKER
      // ==================================================
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,

        headerBackgroundColor: AppColors.primary,

        headerForegroundColor: Colors.white,

        todayForegroundColor: const WidgetStatePropertyAll(
          AppColors.primaryDark,
        ),

        todayBorder: const BorderSide(color: AppColors.primary),

        dayOverlayColor: WidgetStatePropertyAll(
          AppColors.primarySoft.withValues(alpha: 0.45),
        ),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // ==================================================
      // CHIPS
      // ==================================================
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primarySoft,
        disabledColor: AppColors.border,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
