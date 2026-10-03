import 'package:flutter/material.dart';

abstract final class TerraTheme {
  static final ValueNotifier<bool> isDarkMode = ValueNotifier(false);
  static const ink = Color(0xFF173B32);
  static const forest = Color(0xFF215C45);
  static const olive = Color(0xFF6D8B62);
  static const sage = Color(0xFFAFC7A8);
  static const mist = Color(0xFFF2F6F3);
  static const paper = Color(0xFFFCFDFB);
  static const line = Color(0xFFDCE7DE);
  static const blue = Color(0xFF2C6970);
  static const amber = Color(0xFFD39A3A);
  static const coral = Color(0xFFC86D4A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: Brightness.light,
      primary: forest,
      secondary: blue,
      surface: paper,
      error: coral,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: mist,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: mist,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: blue),
      ),
      cardTheme: CardThemeData(
        color: paper,
        elevation: 1,
        shadowColor: ink,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: ink.withValues(alpha: 0.38)),
        border: _inputBorder(line),
        enabledBorder: _inputBorder(line),
        focusedBorder: _inputBorder(forest, width: 1.8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forest,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forest,
          side: const BorderSide(color: sage, width: 1.2),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE7F0E7),
        side: const BorderSide(color: sage),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: Brightness.dark,
      primary: sage,
      secondary: blue,
      error: coral,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF10231E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF10231E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF18352D),
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF18352D),
        border: _inputBorder(const Color(0xFF315A4D)),
        enabledBorder: _inputBorder(const Color(0xFF315A4D)),
        focusedBorder: _inputBorder(sage, width: 1.8),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
