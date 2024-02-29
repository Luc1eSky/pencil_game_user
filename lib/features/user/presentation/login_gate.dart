import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pencil_game_user/features/authorize/data/firestore_auth_instance_provider.dart';

import '../../../constants.dart';
import '../../game/presentation/home_screen.dart';
import '../data/firestore_user_repository.dart';
import '../domain/login_status.dart';
import 'loading_screen.dart';
import 'manual_login_screen.dart';
import 'signed_out_screen.dart';

class LoginGate extends ConsumerStatefulWidget {
  const LoginGate({super.key, required this.userCode});
  final String? userCode;

  @override
  ConsumerState<LoginGate> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginGate> {
  LoginStatus loginStatus = LoginStatus.loading;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // save user code value, check if any code was given
      final userCode = widget.userCode;
      final userCodeGiven = userCode != null && userCode != noCodePlaceholder;

      // check if user is not yet signed in
      if (ref.read(firebaseAuthInstanceProvider).currentUser == null) {
        // sign them in anonymously
        debugPrint('User is not signed in. Signing in now.');
        await ref.read(firebaseAuthInstanceProvider).signInAnonymously();
      }

      // check if given code is a valid code in database
      // (user needs to be signed in to access database)
      final userCodeIsValid = userCodeGiven &&
          await ref.read(firestoreUserRepositoryProvider).userShareCodeDocExists(userCode);
      // get user uid
      final userUid = ref.read(firebaseAuthInstanceProvider).currentUser!.uid;
      debugPrint('User is signed in with UID: $userUid');

      // check if user doc exists
      final userDocExists = await ref.read(firestoreUserRepositoryProvider).userDocExists(userUid);

      // if user doc exists, send user to home screen
      if (userDocExists) {
        debugPrint('User document exists. User is logged back in.');
        setState(() => loginStatus = LoginStatus.loggedIn);
        return;
      }

      // if there is no user document yet:
      // exit to manual entry if no user code was was given
      if (!userCodeGiven) {
        debugPrint('No user code was given. Enter details manually.');
        setState(() => loginStatus = LoginStatus.showManualLogin);
        return;
      }

      // if code was given, but code is not valid
      if (!userCodeIsValid) {
        // show error in snack bar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('User share code $userCode failed.'),
            ),
          );
        }
        debugPrint('Given user code was invalid. Enter details manually.');
        setState(() => loginStatus = LoginStatus.showManualLogin);
        return;
      }
      // if code as given and is valid => try to create user doc from code + uuid
      final hasCreatedUserDoc = await ref
          .read(firestoreUserRepositoryProvider)
          .createUserDocFromCode(shareCode: userCode, uuid: userUid);

      // show error if anything went wrong
      if (!hasCreatedUserDoc) {
        // show error in snack bar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Error trying to join experiment.'),
            ),
          );
        }
        debugPrint('Error trying to create a new user.');
        setState(() => loginStatus = LoginStatus.showManualLogin);
        return;
      }

      // if everything worked out, go back to home screen
      setState(() => loginStatus = LoginStatus.loggedIn);
      return;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      //backgroundColor: Colors.yellow,
      body: StreamBuilder(
          stream: ref.watch(firebaseAuthInstanceProvider).authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error.', style: TextStyle(fontSize: 30));
            }
            // user is signed out
            if (!snapshot.hasData) {
              // either loading or done
              return loginStatus == LoginStatus.loading
                  ? const LoadingScreen()
                  : const SignedOutScreen();
            }
            // user is signed in
            // show screen based on login status
            switch (loginStatus) {
              case LoginStatus.loading:
                return const LoadingScreen();
              case LoginStatus.showManualLogin:
                return const ManualLoginScreen();
              case LoginStatus.loggedIn:
                return const HomeScreen();
            }
          }),
    );
  }
}
