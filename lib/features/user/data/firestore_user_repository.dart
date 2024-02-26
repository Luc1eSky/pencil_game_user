import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../firestore/firestore_instance_provider.dart';
import '../../schedule/domain/schedule.dart';
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

      // TODO: MOVE TO SCHEDULE REPOSITORY
      // TODO: CREATE SERVICE THAT COMBINES REPOSITORIES
      // start transaction to keep track of user count in schedule
      final scheduleRef = experimentRef.collection('schedule').doc('schedule');
      _firestore.runTransaction((transaction) async {
        // get experiment document
        final scheduleDoc = await transaction.get(scheduleRef);

        // exit if it does not exist
        if (!scheduleDoc.exists) {
          throw Exception('Schedule document for experiment $experimentDocId does not exist.');
        }
        // exit if there is no data
        if (scheduleDoc.data() == null) {
          throw Exception('Schedule document for experiment $experimentDocId has no data.');
        }

        // get current schedule
        final currentSchedule = Schedule.fromJson(scheduleDoc.data()!);

        // get current color code list and update it
        final colorCodeList = [...currentSchedule.playerColorCodes];
        colorCodeList.add(appUser.colorCode);

        // create updated schedule
        final updatedSchedule = currentSchedule.copyWith(playerColorCodes: colorCodeList);

        // update schedule doc with new user count and color color code list
        transaction.update(scheduleRef, updatedSchedule.toJson());
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
