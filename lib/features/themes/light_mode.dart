import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    surface: Colors.grey.shade100,
    primary: Colors.blue,
    secondary: Colors.orange,
    tertiary: Colors.green,
    inversePrimary: Colors.grey.shade900,
    background: Colors.white,
    onSurface: Colors.black,
    surfaceVariant: Colors.grey.shade50,
    onSurfaceVariant: Colors.grey.shade700,
    outline: Colors.grey.shade300,
    outlineVariant: Colors.grey.shade200,
  ),
  scaffoldBackgroundColor: Colors.grey.shade100,
  textTheme: const TextTheme().apply(
    bodyColor: Colors.black,
    displayColor: Colors.black,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.blue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  radioTheme: RadioThemeData(
    fillColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blue;
        }
        return Colors.grey.shade600;
      },
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blue;
        }
        return Colors.grey.shade600;
      },
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blue;
        }
        return Colors.grey.shade500;
      },
    ),
    trackColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blue.withOpacity(0.5);
        }
        return Colors.grey.shade400;
      },
    ),
  ),
);