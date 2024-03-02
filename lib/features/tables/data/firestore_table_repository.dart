import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pencil_game_user/constants.dart';

import '../../../firestore/firestore_instance_provider.dart';
import '../../user/domain/app_user.dart';
import '../domain/table.dart';

class FirestoreTableRepository {
  FirestoreTableRepository(this._firestore);
  final FirebaseFirestore _firestore;

  /// helper function to get tables collection ref of specific experiment
  CollectionReference<Map<String, dynamic>> _getTablesCollectionRef(String experimentDocId) {
    return _firestore
        .collection(experimentCollectionName)
        .doc(experimentDocId)
        .collection(tableCollectionName);
  }

  /// get the stream of a specific table of a specific experiment
  Stream<DocumentSnapshot<Table>> getTableStream({
    required String experimentDocId,
    required int tableNumber,
  }) {
    return _getTablesCollectionRef(experimentDocId)
        .doc('table$tableNumber')
        .withConverter(
          fromFirestore: (snapshot, _) => Table.fromJson(snapshot.data()!),
          toFirestore: (table, _) => table.toJson(),
        )
        .snapshots();
  }

  /// join table as a player
  Future<void> joinTable({
    required DocumentReference tableDocRef,
    required AppUser user,
  }) async {
    await tableDocRef.update(
      {
        'signedInUsers': FieldValue.arrayUnion([user.toJson()]),
      },
    );
  }
}

final firestoreTableRepositoryProvider = Provider<FirestoreTableRepository>((ref) {
  return FirestoreTableRepository(ref.watch(firestoreInstanceProvider));
});
