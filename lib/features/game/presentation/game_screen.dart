import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pencil_game_user/features/game/domain/realtime_table.dart';
import 'package:pencil_game_user/features/game/presentation/number_input_widget.dart';
import 'package:pencil_game_user/features/user/domain/simple_user.dart';

import '../../../constants.dart';
import '../data/realtime_database_repository.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
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
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool grabPenButtonIsBlocked = false;
  late DateTime _serverStartTime;
  late DateTime _serverEndTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _serverStartTime = widget.table.startedOn!;
    _serverEndTime = widget.table.endedOn!;
    _startTimer();
  }

  void _startTimer() {
    const oneSecond = Duration(seconds: 1);
    Duration delay =
        oneSecond - Duration(milliseconds: _serverTimeNow().millisecond);

    _timer = Timer(delay, () {
      Timer.periodic(oneSecond, (timer) {
        setState(() {
          if (_serverTimeNow().isAfter(_serverEndTime)) {
            timer.cancel();
          }
        });
      });
    });
  }

  /// returns local time including offset to get server time
  DateTime _serverTimeNow() {
    return DateTime.now().add(widget.databaseOffset);
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // check if game has started
    bool gameHasStarted = _serverTimeNow().isAfter(_serverStartTime);

    // if game has not yet started
    if (!gameHasStarted) {
      final countInDifference = _serverStartTime.difference(_serverTimeNow());
      final countInDuration =
          countInDifference.isNegative ? Duration.zero : countInDifference;
      final formattedCountInSeconds = countInDuration.inSeconds == 0
          ? 'START'
          : countInDuration.inSeconds.toString();

      final showCountIn = countInDuration.inSeconds < 4;
      // show count in (3...2...1...START)
      return showCountIn
          ? Center(
              child: SizedBox(
                height: 120,
                width: 240,
                child: FittedBox(
                  child: Text(
                    formattedCountInSeconds,
                    style: const TextStyle(
                      fontSize: 100,
                    ),
                  ),
                ),
              ),
            )
          :
          // show waiting text
          const Center(child: Text('starting...'));
    }

    // if game has started, calculate time left
    final timeLeft = _serverEndTime.difference(_serverTimeNow());
    final timeLeftDuration = timeLeft.isNegative ? Duration.zero : timeLeft;
    final formattedTimeLeftDuration = _printDuration(timeLeftDuration);

    // check if game is over and show screen
    final gameIsOver = timeLeftDuration == Duration.zero;
    if (gameIsOver) {
      return const Text('Your game is over. Please stand by.');
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            formattedTimeLeftDuration,
            style: const TextStyle(fontSize: 30),
          ),
        ),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              return widget.table.userHasPen(widget.user)
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(realtimeDatabaseRepositoryProvider)
                                  .returnPen(
                                    experimentDocId: widget.experimentDocId,
                                    tableNumber: widget.table.tableNumber,
                                    user: widget.user,
                                  );
                            },
                            child: const Text('Return Pen'),
                          ),
                        ),
                        Expanded(
                          child: NumberInputWidget(
                            experimentDocId: widget.experimentDocId,
                            tableNumber: widget.table.tableNumber,
                            user: widget.user,
                            numberCopyResults: widget.table.numberCopyResults,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        //mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.table.someOneHasPen
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 50),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(80),
                            ),
                            onPressed: grabPenButtonIsBlocked
                                ? null
                                : () async {
                                    setState(
                                        () => grabPenButtonIsBlocked = true);
                                    final shouldFollowUp = await ref
                                        .read(
                                            realtimeDatabaseRepositoryProvider)
                                        .tryToGrabPen(
                                          experimentDocId:
                                              widget.experimentDocId,
                                          tableNumber: widget.table.tableNumber,
                                          user: widget.user,
                                        );

                                    if (shouldFollowUp) {
                                      await Future.delayed(const Duration(
                                          milliseconds:
                                              catchUpDelayInMilliseconds));
                                      print('Follow up now.');
                                      await ref
                                          .read(
                                              realtimeDatabaseRepositoryProvider)
                                          .followUpClick(
                                            experimentDocId:
                                                widget.experimentDocId,
                                            tableNumber:
                                                widget.table.tableNumber,
                                            user: widget.user,
                                          );
                                    }
                                    setState(
                                        () => grabPenButtonIsBlocked = false);
                                  },
                            child: const Text(
                              'GRAB PEN',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }
}

String _printDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
  return "$twoDigitMinutes:$twoDigitSeconds";
}
