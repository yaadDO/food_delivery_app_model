import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    surface: Colors.grey.shade900,
    primary: Colors.blueAccent,
    secondary: Colors.orangeAccent,
    tertiary: Colors.greenAccent,
    inversePrimary: Colors.white,
    background: Colors.grey.shade900,
    onSurface: Colors.white,
    surfaceVariant: Colors.grey.shade800,
    onSurfaceVariant: Colors.grey.shade300,
    outline: Colors.grey.shade700,
    outlineVariant: Colors.grey.shade600,
  ),
  scaffoldBackgroundColor: Colors.grey.shade900,
  textTheme: const TextTheme().apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),
  cardTheme: CardThemeData(
    color: Colors.grey.shade800,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.blueAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  radioTheme: RadioThemeData(
    fillColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blueAccent;
        }
        return Colors.grey.shade400;
      },
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blueAccent;
        }
        return Colors.grey.shade400;
      },
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blueAccent;
        }
        return Colors.grey.shade300;
      },
    ),
    trackColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blueAccent.withOpacity(0.5);
        }
        return Colors.grey.shade600;
      },
    ),
  ),
);