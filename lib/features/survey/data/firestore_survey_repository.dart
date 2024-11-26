import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../firebase/firestore_instance_provider.dart';
import '../domain/survey.dart';

class FirestoreSurveyRepository {
  FirestoreSurveyRepository(this._firestore);

  final FirebaseFirestore _firestore;

  // /// get survey stream
  // Stream<DocumentSnapshot<Map<String, dynamic>>> getSurveyStatusStream(
  //     String experimentDocId) {
  //   return _firestore
  //       .collection(experimentCollectionName)
  //       .doc(experimentDocId)
  //       .snapshots();
  // }

  Future<void> addSurveyInfoToUserDocument({
    required Future<String?> experimentDocId,
    required Survey survey,
    required String? userID,
  }) async {
    // Validate inputs
    final experimentId = await experimentDocId;
    if (experimentId == null) {
      throw Exception('Experiment document ID is null.');
    }
    if (userID == null) {
      throw Exception('User ID is null.');
    }

    try {
      await _firestore
          .collection(experimentCollectionName)
          .doc(experimentId)
          .collection('users')
          .doc(userID)
          .update({'surveyTest': survey.toJson()});
      //.update({'Surveytest': true});
      //
      debugPrint('Survey info successfully added.');
    } catch (e) {
      debugPrint('Failed to add survey info: $e');
      rethrow;
    }
  }
//   Future<void> activateSurvey({
//     required String experimentDocId,
//   }) async {
//     // activate survey
//     await _firestore
//         .collection(experimentCollectionName)
//         .doc(experimentDocId)
//         .collection(settingsCollectionName)
//         .doc('survey')
//         .update({'showSurvey': true});
//   }
// }
}

final firestoreSurveyRepositoryProvider =
    Provider<FirestoreSurveyRepository>((ref) {
  return FirestoreSurveyRepository(ref.watch(firestoreInstanceProvider));
});
