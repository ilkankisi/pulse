import 'package:flutter/material.dart';

import 'features/auth/presentation/auth_gate.dart';

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const AuthGate(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: brightness,
        ).copyWith(
          primary: brightness == Brightness.light
              ? const Color(0xFF6750A4)
              : const Color(0xFFD0BCFF),
          tertiary: brightness == Brightness.light
              ? const Color(0xFF7D5260)
              : const Color(0xFFEFB8C8),
          error: brightness == Brightness.light
              ? const Color(0xFFB3261E)
              : const Color(0xFFF2B8B5),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
    );
  }
}
