import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../user/domain/app_user.dart';
import '../data/firestore_table_repository.dart';
import '../domain/table.dart' as t;

class JoinTableWidget extends ConsumerWidget {
  const JoinTableWidget({
    super.key,
    required this.user,
    required this.tableNumber,
    required this.experimentDocId,
  });

  final AppUser user;
  final int? tableNumber;
  final String experimentDocId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 1. no table assigned yet
        tableNumber == null
            ? const Text(
                'PLEASE WAIT. YOUR SEAT IS BEING ASSIGNED.',
                style: TextStyle(fontSize: 30),
                textAlign: TextAlign.center,
              )
            // 2. player is pausing this round
            : tableNumber == 0
                ? const Text(
                    'YOU ARE PAUSING THIS ROUND.',
                    style: TextStyle(fontSize: 30),
                  )
                // 3. table number was assigned
                : StreamBuilder<DocumentSnapshot<t.Table>>(
                    stream: ref.read(firestoreTableRepositoryProvider).getTableStream(
                          experimentDocId: experimentDocId,
                          tableNumber: tableNumber!,
                        ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Error with table stream.');
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      t.Table table;
                      DocumentReference tableDocRef;
                      try {
                        table = snapshot.data!.data()!;
                        tableDocRef = snapshot.data!.reference;
                      } catch (e) {
                        return Text('Error with table object: ${e.toString()}');
                      }

                      return table.userIsAtTable(user)
                          ? Text(
                              'YOU ARE AT TABLE $tableNumber. PLEASE WAIT UNTIL GAME STARTS',
                              style: const TextStyle(fontSize: 30),
                              textAlign: TextAlign.center,
                            )
                          : Column(
                              children: [
                                Text(
                                  'PLEASE GO TO TABLE $tableNumber',
                                  style: const TextStyle(fontSize: 30),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () async {
                                    // add user to table
                                    await ref.read(firestoreTableRepositoryProvider).joinTable(
                                          tableDocRef: tableDocRef,
                                          user: user,
                                        );
                                  },
                                  child: Text('Join table $tableNumber'),
                                ),
                              ],
                            );
                    },
                  ),
      ],
    );
  }
}
