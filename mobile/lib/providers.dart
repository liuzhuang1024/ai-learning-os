import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/api.dart';
import 'services/auth.dart';

// Default to localhost for dev. Override at build time:
//   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
const _defaultBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

final userIdProvider = FutureProvider<String>((ref) => Auth.ensureUserId());

final apiProvider = FutureProvider<Api>((ref) async {
  final uid = await ref.watch(userIdProvider.future);
  return Api(_defaultBase, uid);
});

final onboardedProvider = FutureProvider<bool>((ref) => Auth.isOnboarded());
