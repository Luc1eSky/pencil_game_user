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
      child: Column(
        children: [
          StreamBuilder(
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

                    return Text(
                      '${appUser.firstName} ${appUser.lastName} / ${appUser.colorCode}',
                      style: const TextStyle(fontSize: 30),
                    );
                  },
                );
              }),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // const JoinTableWidget(),
                // const SizedBox(height: 50),
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
      ),
    );
  }
}
