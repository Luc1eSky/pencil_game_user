import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../firestore/firestore_instance_provider.dart';
import '../domain/app_user.dart';

class FirestoreUserRepository {
  FirestoreUserRepository(this._firestore);
  final FirebaseFirestore _firestore;

  /// check if user document already exists
  Future<bool> userDocExists(String docId) async {
    final docSnap = await _firestore.collection(userCollectionName).doc(docId).get();
    return docSnap.exists;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserDocStream(String uid) {
    return _firestore
        .collection(userCollectionName)
        .doc(uid)
        // .withConverter(
        //     fromFirestore: (snapshot, _) => AppUser.fromFirestore(snapshot.data()!, uid),
        //     toFirestore: (appUser, _) => appUser.toFirestore())
        .snapshots();
  }

  Stream<DocumentSnapshot<AppUser>> getDetailedUserDocStream(String experimentDocId, String uid) {
    return _firestore
        .collection(experimentCollectionName)
        .doc(experimentDocId)
        .collection(userCollectionName)
        .doc(uid)
        .withConverter(
            fromFirestore: (snapshot, _) => AppUser.fromFirestore(snapshot.data()!, uid),
            toFirestore: (appUser, _) => appUser.toFirestore())
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getUserShareCodeDoc(String shareCode) async {
    return await _firestore
        .collection(userShareCodeCollectionName)
        .where('code', isEqualTo: shareCode)
        .limit(1)
        .get();
  }

  /// check if user share code document exists
  Future<bool> userShareCodeDocExists(String shareCode) async {
    final querySnap = await _getUserShareCodeDoc(shareCode);
    return querySnap.docs.isNotEmpty && querySnap.docs.first.exists;
  }

  /// create new user document from user share code and user uid
  Future<bool> createUserDocFromCode({
    required String shareCode,
    required String uuid,
  }) async {
    debugPrint('Creating user doc from code $shareCode and uuid $uuid.');
    try {
      // check if user share code doc exists
      final querySnap = await _getUserShareCodeDoc(shareCode);

      // throw exception if document was not found or is empty
      if (querySnap.docs.isEmpty || !querySnap.docs.first.exists) {
        throw Exception('No documents for user share code $shareCode was found.');
      }

      // get info from user share code doc
      final data = querySnap.docs.first.data();

      // convert to AppUser object
      final appUser = AppUser.fromFirestore(data, uuid);

      // get ref to experiment doc
      final experimentDocId = appUser.experimentDocId;
      final experimentRef = _firestore.collection(experimentCollectionName).doc(experimentDocId);

      // delete user share code doc
      await querySnap.docs.first.reference.delete();

      // add new user doc to users sub-collection under experiment
      await _firestore.collection(userCollectionName).doc(uuid).set({
        'experimentDocId': appUser.experimentDocId,
      });
      await experimentRef.collection(userCollectionName).doc(uuid).set(appUser.toFirestore());

      // start transaction to keep track of user count in experiment
      _firestore.runTransaction((transaction) async {
        // get experiment document
        final experimentDoc = await transaction.get(experimentRef);

        // exit if it does not exist
        if (!experimentDoc.exists) {
          throw Exception('Document $experimentDocId not exist.');
        }

        // calculate new user count
        final int newUserCount = (experimentDoc.data()?['userCount'] ?? -1) + 1;

        // update experiment doc field with new user count
        transaction.update(experimentRef, {'userCount': newUserCount});
      });

      return true;
    } catch (error) {
      debugPrint('Error: $error');
      return false;
    }
  }
}

final firestoreUserRepositoryProvider = Provider<FirestoreUserRepository>((ref) {
  return FirestoreUserRepository(ref.watch(firestoreInstanceProvider));
});
