// Placeholder entry. Real app needs `flutter create` to fill in iOS/Android
// platform folders and generated files. See mobile/README.md.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: LearningOSApp()));
}

class LearningOSApp extends StatelessWidget {
  const LearningOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning OS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B5BFF)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Learning OS — bootstrap pending')),
      ),
    );
  }
}
