import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.dark(
    surface: Colors.grey.shade900,
    primary: Colors.grey.shade400,
    secondary: Colors.grey.shade900,
    tertiary: Colors.grey.shade600,
    inversePrimary: Colors.white,
    background: Colors.grey.shade800,
    onSurface: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.grey.shade900,
  textTheme: const TextTheme().apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),
);
