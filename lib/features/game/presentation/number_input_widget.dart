import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pencil_game_user/features/game/data/realtime_database_repository.dart';
import 'package:pencil_game_user/features/game/domain/number_copy_result.dart';

import '../../../style/color_palette.dart';
import '../../user/domain/simple_user.dart';
import '../data/numbers_to_copy.dart';

//const double numberGapWidthRatio = 0.08;
const int numberDigitCount = 16;

const double numberWidgetMaxWidth = 400.0;
const double gapToButtonRatio = 0.25;
const double paddingToButtonRatio = 0.5;
const totalWidthRatio = 3 + 4 * gapToButtonRatio + 2 * paddingToButtonRatio;
const totalHeightRatio = 6 + 5 * gapToButtonRatio + 2 * paddingToButtonRatio;
const double outerRadiusToButtonRatio = 0.2;
const double innerRadiusToButtonRatio = 0.1;

final textSizeGroup = AutoSizeGroup();

class NumberInputWidget extends StatefulWidget {
  const NumberInputWidget({
    super.key,
    required this.numberCopyResults,
    required this.experimentDocId,
    required this.tableNumber,
    required this.user,
  });

  final String experimentDocId;
  final int tableNumber;
  final SimpleUser user;
  final List<NumberCopyResult>? numberCopyResults;

  @override
  State<NumberInputWidget> createState() => _NumberInputWidgetState();
}

class _NumberInputWidgetState extends State<NumberInputWidget> {
  String _currentSolution = numbersToCopy.first;
  String _currentString = '';

  // void _createRandomNumberString() {
  //   List<String> list = [];
  //
  //   final random = Random();
  //   for (int j = 0; j < 100; j++) {
  //     String numberString = '';
  //     for (int i = 0; i < 16; i++) {
  //       numberString += random.nextInt(10).toString();
  //     }
  //     print("'$numberString',");
  //     list.add(numberString);
  //   }
  //   //print(list);
  //   // setState(() {
  //   //   _currentString = numberString;
  //   // });
  // }

  /// add number to String
  void _addNumber(int number) {
    if (_currentString.length >= numberDigitCount) {
      print('max already reached');
      return;
    }
    setState(() => _currentString += number.toString());
  }

  /// remove number from String
  void _removeNumber() {
    if (_currentString.isEmpty) {
      print('no numbers left');
      return;
    }
    setState(
      () => _currentString = _currentString.substring(0, _currentString.length - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final NumberCopyResult? myNumberResults =
        widget.numberCopyResults?.firstWhereOrNull((result) => result.user == widget.user);
    final submittedNumbersCount = myNumberResults?.numbersCount ?? 0;
    final correctAnswersCount = myNumberResults?.correctAnswersCount ?? 0;

    _currentSolution = numbersToCopy[submittedNumbersCount];

    return Container(
      alignment: Alignment.bottomCenter,
      child: Column(
        children: [
          Text('numbers submitted: $submittedNumbersCount'),
          Text('numbers correct: $correctAnswersCount'),
          Expanded(
            child: FractionallySizedBox(
              widthFactor: 0.9,
              heightFactor: 0.9,
              child: LayoutBuilder(builder: (context, constraints) {
                final availableWidth = min(constraints.maxWidth, numberWidgetMaxWidth);
                final availableHeight = constraints.maxHeight;
                final widthLimitedButtonSize = availableWidth / totalWidthRatio;
                final heightLimitedButtonSize = availableHeight / totalHeightRatio;
                final limitedButtonSize = min(widthLimitedButtonSize, heightLimitedButtonSize);
                final limitedGapSize = limitedButtonSize * gapToButtonRatio;
                final limitedPadding = limitedButtonSize * paddingToButtonRatio;
                return Center(
                  child: Container(
                    width: limitedButtonSize * totalWidthRatio,
                    height: limitedButtonSize * totalHeightRatio,
                    decoration: BoxDecoration(
                      color: ColorPalette().numberWidgetBackGround,
                      borderRadius:
                          BorderRadius.circular(limitedButtonSize * outerRadiusToButtonRatio),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(limitedPadding),
                      child: Column(
                        children: [
                          Container(
                            height: limitedButtonSize,
                            decoration: BoxDecoration(
                              color: ColorPalette().numberWidgetTextField,
                              borderRadius: BorderRadius.circular(
                                  limitedButtonSize * innerRadiusToButtonRatio),
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: EdgeInsets.all(limitedGapSize / 2),
                                child: AutoSizeText(
                                  _formatString(_currentSolution),
                                  style: const TextStyle(fontSize: 50),
                                  maxLines: 1,
                                  group: textSizeGroup,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: limitedGapSize),
                          Container(
                            height: limitedButtonSize,
                            decoration: BoxDecoration(
                              color: ColorPalette().numberWidgetTextField,
                              borderRadius: BorderRadius.circular(
                                  limitedButtonSize * innerRadiusToButtonRatio),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.all(limitedGapSize / 2),
                                child: AutoSizeText(
                                  _formatString(_currentString),
                                  style: const TextStyle(fontSize: 50),
                                  maxLines: 1,
                                  group: textSizeGroup,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: limitedGapSize),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: limitedGapSize),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                reverse: true,
                                itemCount: 12,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: limitedGapSize,
                                  crossAxisSpacing: limitedGapSize,
                                  childAspectRatio: 1.0,
                                ),
                                itemBuilder: (context, index) {
                                  if (index == 1) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red,
                                      ),
                                      child: IconButton(
                                        color: Colors.white,
                                        onPressed: () => _removeNumber(),
                                        icon: const FractionallySizedBox(
                                          widthFactor: 0.7,
                                          heightFactor: 0.7,
                                          child: FittedBox(
                                            child: Icon(
                                              Icons.arrow_back,
                                              size: 200,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  if (index == 2) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.green,
                                      ),
                                      child: Consumer(
                                        builder: (context, ref, child) {
                                          return IconButton(
                                            color: Colors.white,
                                            onPressed: () async {
                                              await ref
                                                  .read(realtimeDatabaseRepositoryProvider)
                                                  .addNumberInput(
                                                    experimentDocId: widget.experimentDocId,
                                                    tableNumber: widget.tableNumber,
                                                    user: widget.user,
                                                    solution: _currentSolution,
                                                    input: _currentString,
                                                  );
                                              setState(() => _currentString = '');
                                            },
                                            icon: const FractionallySizedBox(
                                              widthFactor: 0.7,
                                              heightFactor: 0.7,
                                              child: FittedBox(
                                                child: Icon(
                                                  Icons.check,
                                                  size: 200,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }

                                  int number;
                                  if (index == 0) {
                                    number = index;
                                  } else if (index >= 3) {
                                    number = index - 2;
                                  } else {
                                    number = -1;
                                  }

                                  return ElevatedButton(
                                    onPressed: () => _addNumber(number),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: EdgeInsets.all(limitedGapSize),
                                    ),
                                    child: FittedBox(
                                      child: AutoSizeText(
                                        number.toString(),
                                        style: const TextStyle(fontSize: 50),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatString(String inputString) {
  // Add a space after every 4 characters
  String result = '';
  for (int i = 0; i < inputString.length; i++) {
    result += inputString[i];
    if ((i + 1) % 4 == 0 && (i + 1) != inputString.length) {
      result += ' ';
    }
  }
  return result;
}
