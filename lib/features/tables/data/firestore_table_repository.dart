import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firestore/firestore_instance_provider.dart';

class FirestoreTableRepository {
  FirestoreTableRepository({required this.firestore});
  final FirebaseFirestore firestore;

  /// try to join table as a player
  void tryToJoinTable(int tableNumber) {
    print('trying to join table $tableNumber...');
  }
}

final firestoreTableRepositoryProvider = Provider<FirestoreTableRepository>((ref) {
  return FirestoreTableRepository(firestore: ref.watch(firestoreInstanceProvider));
});
