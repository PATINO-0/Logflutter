import 'package:flutter/material.dart' as m;


m.ThemeData buildAppTheme() {
  const primaryBlue = m.Color(0xFF1F4FFF);
  const accentRed = m.Color(0xFFFF3B3B);

  final base = m.ThemeData(
    brightness: m.Brightness.light,
    useMaterial3: true,
    colorScheme: m.ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: accentRed,
      brightness: m.Brightness.light,
    ),
    scaffoldBackgroundColor: const m.Color(0xFFF7F8FC),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: const m.Color(0xFF0F172A),
      displayColor: const m.Color(0xFF0F172A),
    ),
    inputDecorationTheme: m.InputDecorationTheme(
      filled: true,
      fillColor: m.Colors.white,
      border: m.OutlineInputBorder(
        borderRadius: m.BorderRadius.circular(14),
        borderSide: m.BorderSide.none,
      ),
      contentPadding: const m.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    
    cardTheme: m.CardThemeData(
      color: m.Colors.white,
      elevation: 1.5,
      shape: m.RoundedRectangleBorder(
        borderRadius: m.BorderRadius.circular(16),
      ),
      shadowColor: m.Colors.black12,
      margin: const m.EdgeInsets.all(0), 
    ),
    elevatedButtonTheme: m.ElevatedButtonThemeData(
      style: m.ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: m.Colors.white,
        padding: const m.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: m.RoundedRectangleBorder(borderRadius: m.BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: m.OutlinedButtonThemeData(
      style: m.OutlinedButton.styleFrom(
        side: const m.BorderSide(color: accentRed, width: 1.2),
        foregroundColor: accentRed,
        padding: const m.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: m.RoundedRectangleBorder(borderRadius: m.BorderRadius.circular(14)),
      ),
    ),
    appBarTheme: const m.AppBarTheme(
      backgroundColor: m.Colors.transparent,
      elevation: 0,
      foregroundColor: m.Color(0xFF0F172A),
      centerTitle: false,
    ),
  );
}
