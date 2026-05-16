// Minimal smoke test — just verifies the app boots.
// The splash screen routes to /onboarding or /home via async logic that
// touches shared_preferences (not available in widget tests by default),
// so we only check that the initial frame renders without throwing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learning_os/main.dart';

void main() {
  testWidgets('app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LearningOSApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
