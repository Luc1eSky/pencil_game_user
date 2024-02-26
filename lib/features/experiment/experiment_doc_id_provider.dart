import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExperimentDocIdRepository {
  ExperimentDocIdRepository({required this.experimentDocId});
  final String experimentDocId;

  /// try to join table as a player
  void tryToJoinTable(int tableNumber) {
    print('trying to join table $tableNumber...');
  }
}

final experimentDocIdRepositoryProvider = Provider<ExperimentDocIdRepository>((ref) {
  return ExperimentDocIdRepository(experimentDocId: '');
});
