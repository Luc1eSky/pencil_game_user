import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authorize/data/firestore_auth_instance_provider.dart';
import '../../tables/presentation/join_table_widget.dart';
import '../../user/data/firestore_user_repository.dart';
import '../../user/domain/app_user.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userUid = ref.watch(firebaseAuthInstanceProvider).currentUser!.uid;
    return Center(
      child: StreamBuilder(
          stream: ref.read(firestoreUserRepositoryProvider).getUserDocStream(userUid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error with user data stream.');
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            String experimentDocId;
            try {
              experimentDocId = snapshot.data!.data()!['experimentDocId'];
            } catch (e) {
              return const Text('Error - Could not find experiment ID.');
            }

            return StreamBuilder<DocumentSnapshot<AppUser>>(
              stream: ref
                  .read(firestoreUserRepositoryProvider)
                  .getDetailedUserDocStream(experimentDocId, userUid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error with detailed user data stream.');
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                AppUser appUser;
                try {
                  appUser = snapshot.data!.data()!;
                } catch (e) {
                  return Text('Error with user object: ${e.toString()}');
                }

                final tableNumber = appUser.currentTableNumber;

                return Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Your Color: ${appUser.colorCode}',
                      style: const TextStyle(fontSize: 40),
                    ),
                    Text(
                      '${appUser.firstName} ${appUser.lastName.substring(0, 1)}.',
                      style: const TextStyle(fontSize: 20),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          JoinTableWidget(
                            user: appUser,
                            tableNumber: tableNumber,
                            experimentDocId: experimentDocId,
                          ),
                          const SizedBox(height: 100),
                          ElevatedButton(
                            onPressed: () async {
                              // TODO: CHANGE USER STATUS
                              //  TODO: ALLOW SIGN OUT?!
                              await ref.read(firebaseAuthInstanceProvider).signOut();
                            },
                            child: const Text('sign out'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          }),
    );
  }
}
