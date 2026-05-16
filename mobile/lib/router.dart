import 'package:go_router/go_router.dart';

import 'screens/home.dart';
import 'screens/memory.dart';
import 'screens/onboarding.dart';
import 'screens/quest.dart';
import 'screens/splash.dart';
import 'screens/tutor.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/quest', builder: (_, __) => const QuestScreen()),
    GoRoute(path: '/tutor', builder: (_, __) => const TutorScreen()),
    GoRoute(path: '/memory', builder: (_, __) => const MemoryScreen()),
  ],
);
