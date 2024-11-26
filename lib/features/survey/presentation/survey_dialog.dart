import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pencil_game_user/features/authorize/data/firestore_auth_instance_provider.dart';
import 'package:pencil_game_user/features/survey/data/firestore_survey_repository.dart';
import 'package:pencil_game_user/features/user/data/firestore_user_repository.dart';

import '../domain/survey.dart';

final _formKey = GlobalKey<FormState>();

class SurveyDialog extends StatefulWidget {
  const SurveyDialog({super.key});

  @override
  State<SurveyDialog> createState() => _SurveyDialogState();
}

class _SurveyDialogState extends State<SurveyDialog> {
  Gender? gender;
  bool buttonIsActive = true;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      //title: Text('Add Experiment'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
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
                hintText: 'select a gender',
                labelText: 'What is your gender?',
                //icon: Icon(Icons.person),
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
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: !buttonIsActive
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancel'),
        ),
        Consumer(
          builder: (context, ref, child) {
            return ElevatedButton(
              onPressed: !buttonIsActive
                  ? null
                  : () async {
                      print('test');
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          buttonIsActive = false;
                        });
                        try {
                          print('test survey submission');
                          // get user uid
                          final userUid = ref
                              .read(firebaseAuthInstanceProvider)
                              .currentUser!
                              .uid;
                          // get experiment doc id
                          final experimentDocId = ref
                              .read(firestoreUserRepositoryProvider)
                              .getExperimentId(userUid);
                          // create survey from entries
                          final survey = Survey(gender: gender!);
                          await ref
                              .read(firestoreSurveyRepositoryProvider)
                              .addSurveyInfoToUserDocument(
                                experimentDocId: experimentDocId,
                                survey: survey,
                                userID: userUid,
                              );
                          ref.read(firebaseAuthInstanceProvider).signOut();
                        } catch (error) {
                          debugPrint(error.toString());
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.orange,
                                content: Text(
                                    'An error occurred while trying to create a new experiment.'),
                              ),
                            );
                          }
                        }

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
              child: const Text('Submit'),
            );
          },
        ),
      ],
    );
  }
}
