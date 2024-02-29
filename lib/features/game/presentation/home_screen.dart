import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authorize/data/firestore_auth_instance_provider.dart';
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
            if (snapshot.hasError || !snapshot.hasData) {
              return Container();
            }
            if (snapshot.data!.data() == null) {
              return Container();
            }
            final experimentDocId = snapshot.data!.data()!['experimentDocId'];

            return StreamBuilder<DocumentSnapshot<AppUser>>(
              stream: ref
                  .read(firestoreUserRepositoryProvider)
                  .getDetailedUserDocStream(experimentDocId, userUid),
              builder: (context, snapshot) {
                if (snapshot.hasError || !snapshot.hasData) {
                  return Container();
                }
                if (snapshot.data!.data() == null) {
                  return Container();
                }
                final appUser = snapshot.data!.data()!;

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
                          if (appUser.currentTableNumber != null)
                            appUser.currentTableNumber == 0
                                ? const Text(
                                    'YOU ARE PAUSING THIS ROUND.',
                                    style: TextStyle(fontSize: 30),
                                  )
                                : Text(
                                    'GO TO TABLE: ${appUser.currentTableNumber}',
                                    style: const TextStyle(fontSize: 40),
                                  ),
                          const SizedBox(height: 50),
                          ElevatedButton(
                            onPressed: () async {
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
