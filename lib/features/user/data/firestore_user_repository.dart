import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../firestore/firestore_instance_provider.dart';
import '../../schedule/domain/schedule_parameters.dart';
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

      // add new (basic) user doc to users top level collection with reference to experiment
      await _firestore.collection(userCollectionName).doc(uuid).set({
        'experimentDocId': appUser.experimentDocId,
        'createdOn': Timestamp.now(),
      });

      // add new (detailed) user doc to users sub-collection under experiment
      await experimentRef.collection(userCollectionName).doc(uuid).set(appUser.toFirestore());

      // TODO: AUTOMATE WITH CLOUD FUNCTION
      // start transaction to keep track of user count in schedule
      final parameterRef = experimentRef.collection(settingsCollectionName).doc(parameterDocName);
      _firestore.runTransaction((transaction) async {
        // get experiment document
        final parameterDoc = await transaction.get(parameterRef);

        // exit if it does not exist
        if (!parameterDoc.exists) {
          throw Exception('Schedule document for experiment $experimentDocId does not exist.');
        }
        // exit if there is no data
        if (parameterDoc.data() == null) {
          throw Exception('Schedule document for experiment $experimentDocId has no data.');
        }

        // get current schedule
        final currentParameters = ScheduleParameters.fromJson(parameterDoc.data()!);

        // get set of current users and update it
        final users = {...currentParameters.allActiveUsers};
        users.add(appUser);

        // create updated schedule
        final updatedParameters = currentParameters.copyWith(allActiveUsers: users);

        // update schedule doc with new user count and color color code list
        transaction.update(parameterRef, updatedParameters.toJson());
      });

      return true;
    } catch (error) {
      debugPrint('$error');
      return false;
    }
  }
}

final firestoreUserRepositoryProvider = Provider<FirestoreUserRepository>((ref) {
  return FirestoreUserRepository(ref.watch(firestoreInstanceProvider));
});
