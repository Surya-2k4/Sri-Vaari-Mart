import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = _buildTheme(Brightness.light);
  static ThemeData darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: brightness,
    );

    // Get the default text theme for the brightness
    final baseTextTheme = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;

    // Apply GoogleFonts and ensure colors match the ColorScheme
    final themedText = GoogleFonts.interTextTheme(baseTextTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
      decorationColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: themedText,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 8,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        titleTextStyle: themedText.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: themedText.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      // Added explicitly to ensure TextField text is visible
      primaryTextTheme: themedText,
    );
  }
}
