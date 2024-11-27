import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pencil_game_user/features/authorize/data/firestore_auth_instance_provider.dart';
import 'package:pencil_game_user/features/survey/data/firestore_survey_repository.dart';
import 'package:pencil_game_user/features/user/data/firestore_user_repository.dart';

import '../../user/presentation/signed_out_screen.dart';
import '../domain/survey.dart';

final _formKey = GlobalKey<FormState>();

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({Key? key}) : super(key: key);

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  Gender? gender;
  AgeGroup? ageGroup;
  bool buttonIsActive = true;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Returning false prevents navigation
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Survey'),
          automaticallyImplyLeading: false, // Removes the back button
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // DropdownButtonFormField<AgeGroup>(
                //   value: ageGroup,
                //   onChanged: (AgeGroup? newValue) {
                //     setState(() {
                //       ageGroup = newValue;
                //     });
                //   },
                //   validator: (value) {
                //     if (value == null) {
                //       return 'Please indicate your age range';
                //     }
                //     return null;
                //   },
                //   decoration: const InputDecoration(
                //     hintText: 'Select your age',
                //     labelText: 'What is your age?',
                //   ),
                //   items: AgeGroup.values.map((AgeGroup age) {
                //     return DropdownMenuItem<AgeGroup>(
                //       value: age,
                //       child: Text(
                //         ageGroup!.name,
                //       ),
                //     );
                //   }).toList(),
                // ),
                DropdownButtonFormField<Gender>(
                  value: gender,
                  onChanged: (Gender? newValue) {
                    setState(() {
                      gender = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a gender';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Select a gender',
                    labelText: 'What is your gender?',
                  ),
                  items: Gender.values.map((Gender gender) {
                    return DropdownMenuItem<Gender>(
                      value: gender,
                      child: Text(
                        gender.name,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                Consumer(
                  builder: (context, ref, child) {
                    return ElevatedButton(
                      onPressed: !buttonIsActive
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  buttonIsActive = false;
                                });
                                try {
                                  // Get user UID
                                  final userUid = ref
                                      .read(firebaseAuthInstanceProvider)
                                      .currentUser!
                                      .uid;
                                  // Get experiment doc ID
                                  final experimentDocId = ref
                                      .read(firestoreUserRepositoryProvider)
                                      .getExperimentId(userUid);
                                  // Create survey from entries
                                  final survey = Survey(gender: gender!);
                                  await ref
                                      .read(firestoreSurveyRepositoryProvider)
                                      .addSurveyInfoToUserDocument(
                                        experimentDocId: experimentDocId,
                                        survey: survey,
                                        userID: userUid,
                                      );
                                  ref
                                      .read(firebaseAuthInstanceProvider)
                                      .signOut();

                                  // Navigate to SignedOutScreen
                                  if (context.mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignedOutScreen(),
                                      ),
                                    );
                                  }
                                  // ScaffoldMessenger.of(context).showSnackBar(
                                  //   const SnackBar(
                                  //     backgroundColor: Colors.green,
                                  //     content: Text(
                                  //         'Survey submitted successfully!'),
                                  //   ),
                                  // );
                                } catch (error) {
                                  debugPrint(error.toString());
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Colors.orange,
                                        content: Text(
                                            'An error occurred while trying to submit the survey.'),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      child: const Text('Submit'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
