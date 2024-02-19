import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _formKey = GlobalKey<FormState>();

class JoinTableWidget extends StatefulWidget {
  const JoinTableWidget({super.key});

  @override
  State<JoinTableWidget> createState() => _JoinTableWidgetState();
}

class _JoinTableWidgetState extends State<JoinTableWidget> {
  final tableNumberController = TextEditingController();
  int? selectedValue;
  bool buttonIsActive = true;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: Form(
            key: _formKey,
            child: DropdownButtonFormField(
              borderRadius: BorderRadius.circular(10),
              value: selectedValue,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
                DropdownMenuItem(value: 3, child: Text('3')),
                DropdownMenuItem(value: 4, child: Text('4')),
                DropdownMenuItem(value: 5, child: Text('5')),
              ],
              onChanged: (value) {
                print(value);
                selectedValue = value;
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Consumer(
          builder: (context, ref, child) {
            return ElevatedButton(
              onPressed: !buttonIsActive
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => buttonIsActive = false);
                        print('$selectedValue was selected!');
                        await Future.delayed(const Duration(milliseconds: 1000));
                        setState(() => buttonIsActive = true);
                      }
                    },
              child: const Text('join'),
            );
          },
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
