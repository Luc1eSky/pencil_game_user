import 'package:flutter/material.dart';

class SignedOutScreen extends StatelessWidget {
  const SignedOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.green,
        child: const Center(
          child: Text(
            'Thanks for playing!',
            style: TextStyle(fontSize: 30),
          ),
        ),
      ),
    );
  }
}
