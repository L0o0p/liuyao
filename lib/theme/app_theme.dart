import 'package:flutter/material.dart';

/// 设计稿 docs/ui/*.html 的色板。ColorScheme 之外的描边、投影、语义色放这里。
class AppColors {
  AppColors._();

  /// 卡片描边和卡片投影。
  static const border = Color(0xFF7B4E2D);

  /// 按钮投影，比描边深一档。
  static const shadow = Color(0xFF5C381E);

  /// 主按钮的芝士黄。
  static const cheese = Color(0xFFFECB4D);
  static const honey = Color(0xFFF1C042);

  static const page = Color(0xFFE5F2E0);
  static const pageDot = Color(0xFFD3E8CD);

  /// 卡片的奶油白。
  static const card = Color(0xFFFFFDF7);

  static const masteredBg = Color(0xFFECF9EA);
  static const masteredBorder = Color(0xFF548050);
  static const masteredShadow = Color(0xFF385A35);
  static const masteredText = Color(0xFF234221);
  static const masteredBar = Color(0xFF7AC471);

  static const learningBg = Color(0xFFFFF5DB);
  static const learningBorder = Color(0xFFB87C14);
  static const learningShadow = Color(0xFF754D09);
  static const learningText = Color(0xFF523504);

  static const unseenBg = Color(0xFFF1EEE3);
  static const unseenBorder = Color(0xFF83746B);
  static const unseenShadow = Color(0xFF544841);
  static const unseenBar = Color(0xFFD6C3B8);

  static const correct = Color(0xFF2E7D32);
  static const correctBg = Color(0xFFECF9EA);
  static const wrong = Color(0xFFBA1A1A);
  static const wrongBg = Color(0xFFFFF1F0);
  static const wrongShadow = Color(0xFF8B1313);
}

/// 五行标签配色：背景、文字、描边。
class WuXingColors {
  final Color background;
  final Color foreground;
  final Color border;

  const WuXingColors(this.background, this.foreground, this.border);

  static const Map<String, WuXingColors> byName = {
    '木': WuXingColors(Color(0xFFBBF7D0), Color(0xFF14532D), Color(0xFF86EFAC)),
    '火': WuXingColors(Color(0xFFFECACA), Color(0xFF991B1B), Color(0xFFFCA5A5)),
    '土': WuXingColors(Color(0xFFFED7AA), Color(0xFF7C2D12), Color(0xFFFDBA74)),
    '金': WuXingColors(Color(0xFFFEF08A), Color(0xFF854D0E), Color(0xFFFDE047)),
    '水': WuXingColors(Color(0xFFBFDBFE), Color(0xFF1E3A8A), Color(0xFF93C5FD)),
  };
}

const _scheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF603718),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF7B4E2D),
  onPrimaryContainer: Color(0xFFFFC39B),
  primaryFixed: Color(0xFFFFDCC6),
  primaryFixedDim: Color(0xFFF6BA91),
  onPrimaryFixed: Color(0xFF301400),
  onPrimaryFixedVariant: Color(0xFF663D1D),
  secondary: Color(0xFF4B6548),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFCDEBC5),
  onSecondaryContainer: Color(0xFF516B4D),
  secondaryFixed: Color(0xFFCDEBC5),
  secondaryFixedDim: Color(0xFFB1CFAB),
  onSecondaryFixed: Color(0xFF082009),
  onSecondaryFixedVariant: Color(0xFF344D31),
  tertiary: Color(0xFF533E00),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFF705400),
  onTertiaryContainer: Color(0xFFFBC84A),
  tertiaryFixed: Color(0xFFFFDF9B),
  tertiaryFixedDim: Color(0xFFF1C042),
  onTertiaryFixed: Color(0xFF251A00),
  onTertiaryFixedVariant: Color(0xFF5A4300),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF93000A),
  surface: Color(0xFFFDF9EE),
  onSurface: Color(0xFF1C1C15),
  onSurfaceVariant: Color(0xFF51443C),
  surfaceDim: Color(0xFFDDDACF),
  surfaceBright: Color(0xFFFDF9EE),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF7F3E8),
  surfaceContainer: Color(0xFFF1EEE3),
  surfaceContainerHigh: Color(0xFFECE8DD),
  surfaceContainerHighest: Color(0xFFE6E2D8),
  outline: Color(0xFF83746B),
  outlineVariant: Color(0xFFD6C3B8),
  inverseSurface: Color(0xFF31312A),
  onInverseSurface: Color(0xFFF4F1E6),
  inversePrimary: Color(0xFFF6BA91),
  surfaceTint: Color(0xFF825432),
);

const _textTheme = TextTheme(
  displaySmall: TextStyle(
    fontSize: 36,
    height: 44 / 36,
    letterSpacing: -0.7,
    fontWeight: FontWeight.w800,
  ),
  headlineLarge: TextStyle(
    fontSize: 28,
    height: 36 / 28,
    letterSpacing: -0.3,
    fontWeight: FontWeight.w800,
  ),
  headlineMedium: TextStyle(
    fontSize: 22,
    height: 30 / 22,
    fontWeight: FontWeight.w700,
  ),
  headlineSmall: TextStyle(
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w700,
  ),
  titleLarge: TextStyle(
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w700,
  ),
  titleMedium: TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w700,
  ),
  bodyLarge: TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  ),
  bodyMedium: TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w500,
  ),
  bodySmall: TextStyle(
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w500,
  ),
  labelLarge: TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
  ),
  labelMedium: TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
  ),
  labelSmall: TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
  ),
);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: _scheme,
    textTheme: _textTheme,
  );
  final text = base.textTheme.apply(
    bodyColor: _scheme.onSurface,
    displayColor: _scheme.primary,
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.page,
    primaryColor: _scheme.primary,
    textTheme: text.copyWith(
      bodyMedium: text.bodyMedium?.copyWith(color: _scheme.onSurfaceVariant),
      bodySmall: text.bodySmall?.copyWith(color: _scheme.onSurfaceVariant),
      titleLarge: text.titleLarge?.copyWith(color: _scheme.primary),
      titleMedium: text.titleMedium?.copyWith(color: _scheme.primary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _scheme.surface,
      foregroundColor: _scheme.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: text.headlineSmall?.copyWith(color: _scheme.primary),
      shape: Border(
        bottom: BorderSide(
          color: AppColors.border.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.cheese,
        foregroundColor: _scheme.primary,
        textStyle: text.labelLarge,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.shadow, width: 2),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.primary,
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: AppColors.border, width: 2),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _scheme.primary,
        textStyle: text.labelLarge,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border, width: 2),
      ),
      titleTextStyle: text.headlineSmall?.copyWith(color: _scheme.primary),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: _scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _scheme.surfaceContainerLowest,
      contentTextStyle: text.labelMedium?.copyWith(color: _scheme.primary),
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.border, width: 2),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _scheme.secondary,
    ),
  );
}
