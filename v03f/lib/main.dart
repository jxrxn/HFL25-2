// lib/main.dart
import 'package:flutter/material.dart';
import 'calculator_screen.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  /// Aktuellt temaläge:
  /// - ThemeMode.system = "auto" (följer OS)
  /// - ThemeMode.dark   = mörkt
  /// - ThemeMode.light  = ljust
  ThemeMode _mode = ThemeMode.system;

  /// Cyklar mellan:
  ///   system → dark → light → system …
  void _toggleTheme() {
    setState(() {
      if (_mode == ThemeMode.system) {
        _mode = ThemeMode.dark;
      } else if (_mode == ThemeMode.dark) {
        _mode = ThemeMode.light;
      } else {
        _mode = ThemeMode.system;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
    );

    final light = ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Flutter Calculator',
      debugShowCheckedModeBanner: false,
      theme: light,
      darkTheme: dark,
      themeMode: _mode,
      home: CalculatorScreen(onToggleTheme: _toggleTheme),
    );
  }
}