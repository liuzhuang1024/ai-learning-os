// Entry. Theme is deliberately sober — see PRD §产品形态 (服务有认知的成人，不幼稚化).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

void main() {
  runApp(const ProviderScope(child: LearningOSApp()));
}

class LearningOSApp extends StatelessWidget {
  const LearningOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B5BFF),
      brightness: Brightness.light,
    );
    return MaterialApp.router(
      title: 'Learning OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: base,
        scaffoldBackgroundColor: const Color(0xFFFAFAFB),
        useMaterial3: true,
        textTheme: const TextTheme(
          displaySmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(height: 1.55),
          bodyMedium: TextStyle(height: 1.5),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: base.outlineVariant.withValues(alpha: 0.6)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
