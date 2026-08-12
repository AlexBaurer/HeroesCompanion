import 'package:go_router/go_router.dart';

import '../features/game/presentation/game_screen.dart';
import '../features/main_menu/presentation/faction_choose_screen.dart';
import '../features/main_menu/presentation/main_menu_screen.dart';
import '../features/scores/presentation/score_entry_screen.dart';
import '../features/scores/presentation/score_history_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainMenuScreen(),
    ),
    GoRoute(
      path: '/faction_choose',
      builder: (context, state) => const FactionChooseScreen(),
    ),
    GoRoute(
      path: '/faction/:factionName',
      builder: (context, state) {
        return GameScreen(factionName: state.pathParameters['factionName']!);
      },
    ),
    GoRoute(
      path: '/score',
      builder: (context, state) => const ScoreEntryScreen(),
    ),
    GoRoute(
      path: '/score_history',
      builder: (context, state) => const ScoreHistoryScreen(),
    ),
  ],
);
