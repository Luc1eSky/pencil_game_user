import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pencil_game_user/constants.dart';
import 'package:pencil_game_user/features/survey/presentation/survey_dialog.dart';

import '../../../firebase/database_time_offset_provider.dart';
import '../../authorize/data/firestore_auth_instance_provider.dart';
import '../../game/data/realtime_database_repository.dart';
import '../../user/data/firestore_user_repository.dart';
import '../../user/domain/app_user.dart';
import '../../user/domain/simple_user.dart';
import '../domain/realtime_table.dart';
import 'game_screen_or_error.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userUid = ref.watch(firebaseAuthInstanceProvider).currentUser!.uid;
    return Center(
      child: StreamBuilder(
        stream:
            ref.read(firestoreUserRepositoryProvider).getUserDocStream(userUid),
        builder: (context, userSnap) {
          if (userSnap.hasError) {
            return const Text('Error with user data stream.');
          }
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          String experimentDocId;
          try {
            experimentDocId = userSnap.data!.data()!['experimentDocId'];
          } catch (e) {
            return const Text('Error - Could not find experiment ID.');
          }

          return StreamBuilder<DocumentSnapshot<AppUser>>(
            stream: ref
                .read(firestoreUserRepositoryProvider)
                .getDetailedUserDocStream(experimentDocId, userUid),
            builder: (context, appUserSnap) {
              if (appUserSnap.hasError) {
                return const Text('Error with detailed user data stream.');
              }
              if (!appUserSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              AppUser appUser;
              try {
                appUser = appUserSnap.data!.data()!;
              } catch (e) {
                return Text('Error with user object: ${e.toString()}');
              }

              // check if survey should be displayed
              if (appUser.showSurvey) {
                return ElevatedButton(
                  onPressed: () async {
                    print('button pressed');
                    // Show survey to user
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const SurveyDialog();
                      },
                    );
                  },
                  child: const Text('Go to Survey'),
                );
              }

              // get table number from app user
              final tableNumber = appUser.currentTableNumber;
              // convert to simple user
              final simpleUser = SimpleUser.fromAppUser(appUser);

              return Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.grey[200],
                  title: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: appUser.colorCode.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: '     ',
                          style: TextStyle(fontSize: 36),
                        ),
                        TextSpan(
                          text: appUser.firstName,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    if (inDebuggingMode)
                      IconButton(
                        onPressed: () async {
                          await ref
                              .read(firebaseAuthInstanceProvider)
                              .signOut();
                        },
                        icon: const Icon(Icons.exit_to_app),
                      ),
                  ],
                ),
                body: Center(
                  child: tableNumber == null
                      ? const Text(
                          'Please wait while your table is being assigned.')
                      : tableNumber == 0
                          ? const Text('You are pausing this round.')
                          : StreamBuilder(
                              stream: ref
                                  .read(realtimeDatabaseRepositoryProvider)
                                  .getTableStream(
                                    experimentDocId: experimentDocId,
                                    tableNumber: tableNumber,
                                  ),
                              builder: (context, realtimeSnap) {
                                if (realtimeSnap.hasError) {
                                  return Text(
                                      'Snapshot error ${realtimeSnap.error.toString()}');
                                }
                                if (!realtimeSnap.hasData) {
                                  return const CircularProgressIndicator();
                                }
                                final dataSnap = realtimeSnap.data?.snapshot;
                                if (dataSnap?.value == null) {
                                  return const Text('Error - No data!');
                                }

                                // try to convert streamed data to RealtimeTable object
                                RealtimeTable table;

                                try {
                                  final Map<String, dynamic> convertedData =
                                      jsonDecode(jsonEncode(dataSnap!.value));
                                  table = RealtimeTable.fromJson(convertedData);
                                } catch (e) {
                                  return Text(
                                      'Realtime table object error HERE: $e');
                                }

                                // show widget if user is not yet at table
                                if (!table.userIsAtTable(simpleUser)) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Please go to table $tableNumber'),
                                      const SizedBox(height: 30),
                                      ElevatedButton(
                                        onPressed: () async {
                                          try {
                                            await ref
                                                .read(
                                                    realtimeDatabaseRepositoryProvider)
                                                .joinTable(
                                                  experimentDocId:
                                                      experimentDocId,
                                                  tableNumber: tableNumber,
                                                  user: simpleUser,
                                                );
                                          } catch (e) {
                                            print('ERROR');
                                            debugPrint(e.toString());
                                          }
                                        },
                                        child: const Text('I am here.'),
                                      ),
                                    ],
                                  );
                                }

                                // if user is at table, check table status
                                final tableStatus = table.status;

                                switch (tableStatus) {
                                  case TableStatus.waiting:
                                    return Text(
                                        'Waiting at table $tableNumber');
                                  case TableStatus.playing:
                                    return GameScreenOrError(
                                      experimentDocId: experimentDocId,
                                      table: table,
                                      user: simpleUser,
                                      databaseOffset: ref.watch(
                                          databaseTimeOffsetRepositoryProvider),
                                    );
                                  case TableStatus.aborted:
                                    return Text(
                                        'Game at table $tableNumber was cancelled.');
                                  case TableStatus.finished:
                                    return Text(
                                        'Game at table $tableNumber was finished.');
                                  case TableStatus.resultsCopied:
                                    return Text(
                                        'Results of table $tableNumber were copied.');
                                }
                              },
                            ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
