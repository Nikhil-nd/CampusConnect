import 'package:flutter/material.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.surfaceTint,
  });

  final Color success;
  final Color warning;
  final Color info;
  final Color surfaceTint;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? surfaceTint,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      surfaceTint: surfaceTint ?? this.surfaceTint,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t) ?? surfaceTint,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF0B7285);
  static const AppSemanticColors lightSemanticColors = AppSemanticColors(
    success: Color(0xFF1B8A5A),
    warning: Color(0xFFB7791F),
    info: Color(0xFF2563EB),
    surfaceTint: Color(0xFF0B7285),
  );

  static const AppSemanticColors darkSemanticColors = AppSemanticColors(
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
    surfaceTint: Color(0xFF5EEAD4),
  );

  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: const TextStyle(fontSize: 57, fontWeight: FontWeight.w700, height: 1.05),
      displayMedium: const TextStyle(fontSize: 45, fontWeight: FontWeight.w700, height: 1.08),
      displaySmall: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, height: 1.1),
      headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15),
      headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.18),
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.22, color: scheme.onSurface),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3, color: scheme.onSurface),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.45, color: scheme.onSurface),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45, color: scheme.onSurfaceVariant),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2, color: scheme.onSurface),
    );
  }

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: const <ThemeExtension<dynamic>>[lightSemanticColors],
      textTheme: _textTheme(scheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: const <ThemeExtension<dynamic>>[darkSemanticColors],
      textTheme: _textTheme(scheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }
}
