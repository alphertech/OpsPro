import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/money.dart';

class AppTheme {
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4C8C4A);
  static const Color primaryDark = Color(0xFF003300);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFC8E6C9);
  static const Color onPrimaryContainer = Color(0xFF002107);

  static const Color secondary = Color(0xFFE65100);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFE0B2);
  static const Color onSecondaryContainer = Color(0xFF3E2700);

  static const Color tertiary = Color(0xFF00695C);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB2DFDB);
  static const Color onTertiaryContainer = Color(0xFF00251A);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color surface = Color(0xFFFDFCF8);
  static const Color onSurface = Color(0xFF1A1C1A);
  static const Color surfaceVariant = Color(0xFFE1E4DB);
  static const Color surfaceContainerHighest = Color(0xFFE1E4DB);
  static const Color onSurfaceVariant = Color(0xFF44483F);
  static const Color outline = Color(0xFF74796D);
  static const Color outlineVariant = Color(0xFFC4C8BE);

  static const Color background = Color(0xFFFDFCF8);
  static const Color onBackground = Color(0xFF1A1C1A);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFEF6C00);
  static const Color info = Color(0xFF0277BD);

  static const Color surfaceTint = primary;

  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacing2Xl = 24;
  static const double spacing3Xl = 32;

  static const double borderRadiusXs = 4;
  static const double borderRadiusSm = 6;
  static const double borderRadiusMd = 8;
  static const double borderRadiusLg = 10;
  static const double borderRadiusXl = 12;
  static const double borderRadius2Xl = 16;

  static const double elevationNone = 0;
  static const double elevationLow = 1;
  static const double elevationMedium = 2;
  static const double elevationHigh = 4;

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        fontFamily: 'Roboto',
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        fontFamily: 'Roboto',
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        fontFamily: 'Roboto',
        color: onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        fontFamily: 'Roboto',
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        fontFamily: 'Roboto',
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        fontFamily: 'Roboto',
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        fontFamily: 'Roboto',
        color: onSurface,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        fontFamily: 'Roboto',
        color: onSurface,
        letterSpacing: 0.1,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        fontFamily: 'Roboto',
        color: onSurfaceVariant,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        fontFamily: 'Roboto',
        color: onSurface,
        letterSpacing: 0.25,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        fontFamily: 'Roboto',
        color: onSurfaceVariant,
        letterSpacing: 0.2,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        fontFamily: 'Roboto',
        color: onSurfaceVariant,
        letterSpacing: 0.2,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.35,
        fontFamily: 'Roboto',
        color: onSurface,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
        fontFamily: 'Roboto',
        color: onSurfaceVariant,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.35,
        fontFamily: 'Roboto',
        color: outline,
        letterSpacing: 0.5,
      ),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainerHighest,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2E312E),
      onInverseSurface: Color(0xFFF1F1EE),
      inversePrimary: Color(0xFFA8D5A2),
      surfaceTint: surfaceTint,
    ),
    fontFamily: 'Roboto',
    fontFamilyFallback: const ['MaterialIcons'],
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      elevation: elevationNone,
      centerTitle: false,
      backgroundColor: primary,
      foregroundColor: onPrimary,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onPrimary,
        fontFamily: 'Roboto',
      ),
      toolbarHeight: 52,
    ),
    cardTheme: CardThemeData(
      elevation: elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusXl),
        side: const BorderSide(color: outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      color: surface,
      surfaceTintColor: surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusMd)),
        elevation: elevationLow,
        padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingSm),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusMd)),
        side: const BorderSide(color: outline),
        padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingSm),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusSm)),
        padding: const EdgeInsets.symmetric(horizontal: spacingSm, vertical: spacingXs),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusMd),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingSm),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
        fontFamily: 'Roboto',
      ),
      hintStyle: const TextStyle(
        fontSize: 13,
        color: outline,
        fontFamily: 'Roboto',
      ),
      helperStyle: const TextStyle(
        fontSize: 12,
        color: onSurfaceVariant,
        fontFamily: 'Roboto',
      ),
      errorStyle: const TextStyle(
        fontSize: 12,
        color: error,
        fontFamily: 'Roboto',
      ),
      isDense: true,
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.resolveWith((states) => surfaceVariant.withValues(alpha: 0.5)),
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: onSurface,
        fontFamily: 'Roboto',
      ),
      dataRowColor: WidgetStateProperty.resolveWith((states) => surface),
      dataTextStyle: const TextStyle(fontSize: 13, fontFamily: 'Roboto', color: onSurface),
      dividerThickness: 1,
      horizontalMargin: spacingLg,
      columnSpacing: spacingLg,
      headingRowHeight: 44,
      dataRowMinHeight: 44,
      dataRowMaxHeight: 44,
    ),
    iconTheme: const IconThemeData(
      color: onSurfaceVariant,
      size: 20,
      opticalSize: 20,
    ),
    dividerTheme: const DividerThemeData(
      color: outlineVariant,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusSm)),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Roboto',
      ),
      side: const BorderSide(color: outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: spacingSm, vertical: spacingXs),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusXl)),
      elevation: elevationMedium,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
        fontFamily: 'Roboto',
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: onSurfaceVariant,
        fontFamily: 'Roboto',
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadiusXl)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusMd)),
      elevation: elevationMedium,
    ),
    textTheme: _buildTextTheme(),
  );

  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0);
    return formatter.format(value);
  }

  static String formatMoney(Money money) {
    return money.toFormattedString('UGX');
  }
}