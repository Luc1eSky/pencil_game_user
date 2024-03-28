import 'package:flutter/material.dart';

import '../../user/domain/simple_user.dart';
import '../domain/realtime_table.dart';
import 'game_screen.dart';

class GameScreenOrError extends StatelessWidget {
  const GameScreenOrError({
    super.key,
    required this.experimentDocId,
    required this.table,
    required this.user,
    required this.databaseOffset,
  });

  final String experimentDocId;
  final RealtimeTable table;
  final SimpleUser user;
  final Duration databaseOffset;

  @override
  Widget build(BuildContext context) {
    final startedOn = table.startedOn;
    final endedOn = table.endedOn;

    if (startedOn == null || endedOn == null) {
      return const Center(child: Text('Error - No starting or ending time found!'));
    }

    return GameScreen(
      experimentDocId: experimentDocId,
      table: table,
      user: user,
      databaseOffset: databaseOffset,
    );
  }
}
