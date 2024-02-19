import 'package:flutter/material.dart';

/// simple loading screen shown while app tries
/// to login user automatically
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          Text('Signing in...'),
        ],
      ),
    );
  }
}
