import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants.dart';
import '../features/game/presentation/game_screen.dart';
import '../features/user/presentation/login_gate.dart';

enum AppRoute {
  login,
  game,
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
      initialLocation: '/${AppRoute.login.name}/$noCodePlaceholder',
      debugLogDiagnostics: false,
      // route to login page for user
      routes: [
        GoRoute(
          path: '/${AppRoute.login.name}/:uid',
          name: AppRoute.login.name,
          builder: (context, state) {
            return LoginGate(userCode: state.pathParameters['uid']);
          },
        ),
        GoRoute(
          path: '/${AppRoute.game.name}',
          name: AppRoute.game.name,
          builder: (context, state) => const GameScreen(),
        ),
      ]);
});
