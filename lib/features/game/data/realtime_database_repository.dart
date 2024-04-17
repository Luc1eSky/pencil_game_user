import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pencil_game_user/features/game/domain/number_copy_result.dart';
import 'package:pencil_game_user/features/game/domain/number_input.dart';

import '../../../firebase/database_time_offset_provider.dart';
import '../../user/domain/simple_user.dart';
import '../domain/click.dart';
import '../domain/realtime_table.dart';

class RealtimeDatabaseRepository {
  RealtimeDatabaseRepository(this._realtimeDatabase, this.databaseTimeOffset);
  final FirebaseDatabase _realtimeDatabase;
  final Duration databaseTimeOffset;

  /// get stream to specific table node of specific experiment
  Stream<DatabaseEvent> getTableStream({
    required String experimentDocId,
    required int tableNumber,
  }) {
    return _realtimeDatabase
        .ref(experimentDocId)
        .child('tables')
        .child('table$tableNumber')
        .onValue;
  }

  /// add user to a specific table in a specific experiment
  Future<void> joinTable({
    required String experimentDocId,
    required int tableNumber,
    required SimpleUser user,
  }) async {
    // save reference to table
    final tableRef =
        _realtimeDatabase.ref(experimentDocId).child('tables').child('table$tableNumber');

    // convert to table
    final dataSnap = await tableRef.get();
    final table = RealtimeTable.fromJson(dataSnap.value as Map<String, dynamic>);
    // get a copy of the current users set
    final currentUsersAtTable = table.usersAtTable ?? {};
    final usersAtTableCopy = {...currentUsersAtTable};
    // add new user to the set
    usersAtTableCopy.add(user);
    // create new table object with updated user set
    final updatedTable = table.copyWith(usersAtTable: usersAtTableCopy);

    // update table node with new data
    await tableRef.update(updatedTable.toJson());
  }

  /// add user to a specific table in a specific experiment
  Future<bool> tryToGrabPen({
    required String experimentDocId,
    required int tableNumber,
    required SimpleUser user,
  }) async {
    // save reference to table
    final tableRef =
        _realtimeDatabase.ref(experimentDocId).child('tables').child('table$tableNumber');

    // default state is to not follow up
    bool shouldFollowUp = false;

    await tableRef.runTransaction((Object? tableValue) {
      // exit in case there is no table
      if (tableValue == null) {
        return Transaction.abort();
        // NO FOLLOW UP
      }

      // convert data to table object
      final table = RealtimeTable.fromJson(tableValue as Map<String, dynamic>);

      // exit if table was finished already
      if (table.status == TableStatus.finished) {
        return Transaction.abort();
        // NO FOLLOW UP
      }

      // create new click object
      final newClick = Click(
        user: user,
        type: ClickType.grabPenTry,
        timestamp: _serverTimeNow(),
      );

      final newClickFail = newClick.copyWith(type: ClickType.grabPenFail);
      final newClickSuccess = newClick.copyWith(type: ClickType.grabPenSuccess);

      // archive click in case any user has pen already
      if (table.someOneHasPen) {
        final updatedTable = _addClicks(table: table, clicks: [newClickFail]);
        return Transaction.success(updatedTable.toJson());
        // NO FOLLOW UP
      }

      // check if a click already exists
      final lastClick = table.lastClick;
      if (lastClick != null) {
        // check if same user clicked already
        if (lastClick.user == user) {
          final updatedTable = _addClicks(table: table, clicks: [newClickFail]);
          return Transaction.success(updatedTable.toJson());
          // NO FOLLOW UP
        }

        // comparing two clicks and resolving action
        final String winningUid;
        List<Click> listOfAddedClicks;
        if (lastClick.timestamp.isBefore(newClick.timestamp)) {
          winningUid = lastClick.user.uid; // last click wins
          final lastClickSuccess = lastClick.copyWith(type: ClickType.grabPenSuccess);
          listOfAddedClicks = [lastClickSuccess, newClickFail];
        } else {
          winningUid = newClick.user.uid; // new click wins
          final lastClickFail = lastClick.copyWith(type: ClickType.grabPenFail);
          listOfAddedClicks = [newClickSuccess, lastClickFail];
        }
        // add both clicks to archived list of table
        final tableWithClicks = _addClicks(table: table, clicks: listOfAddedClicks);
        // update table with winning uid and remove last click
        final updatedTable = tableWithClicks.copyWith(
          uidThatHasPen: winningUid,
          lastClick: null,
        );

        // update table in database
        return Transaction.success(updatedTable.toJson());
        // NO FOLLOW UP
      }

      // if no one has pen and no click was registered yet
      // add click to table
      final updatedTable = table.copyWith(lastClick: newClick);
      shouldFollowUp = true;
      return Transaction.success(updatedTable.toJson());
      // FOLLOW UP!
    });

    return shouldFollowUp;
  }

  /// follow up initial click after a delay and check who clicked first
  Future<void> followUpClick({
    required String experimentDocId,
    required int tableNumber,
    required SimpleUser user,
  }) async {
    // save reference to table
    final tableRef =
        _realtimeDatabase.ref(experimentDocId).child('tables').child('table$tableNumber');

    await tableRef.runTransaction((Object? tableValue) {
      // exit in case there is no table
      if (tableValue == null) {
        return Transaction.abort();
      }

      // convert data to table object and get last click
      final table = RealtimeTable.fromJson(tableValue as Map<String, dynamic>);
      final lastClick = table.lastClick;

      // exit in case there is no click to process anymore
      if (lastClick == null) {
        return Transaction.abort();
      }

      // archive successful click and grab pen
      final lastClickSuccess = lastClick.copyWith(type: ClickType.grabPenSuccess);

      // add both clicks to archived list of table
      final tableWithClick = _addClicks(table: table, clicks: [lastClickSuccess]);
      // update table with winning uid and remove last click
      final updatedTable = tableWithClick.copyWith(
        uidThatHasPen: user.uid,
        lastClick: null,
      );

      // update table in database
      return Transaction.success(updatedTable.toJson());
    });
  }

  /// return pen and archive click
  Future<void> returnPen({
    required String experimentDocId,
    required int tableNumber,
    required SimpleUser user,
  }) async {
    // save reference to table
    final tableRef =
        _realtimeDatabase.ref(experimentDocId).child('tables').child('table$tableNumber');

    await tableRef.runTransaction((Object? tableValue) {
      // exit in case there is no table
      if (tableValue == null) {
        return Transaction.abort();
      }

      // convert data to table object
      final table = RealtimeTable.fromJson(tableValue as Map<String, dynamic>);

      // exit in case user does not have pen anymore
      if (!table.userHasPen(user)) {
        return Transaction.abort();
      }

      // create new click object
      final returnClick = Click(
        user: user,
        type: ClickType.returnPen,
        timestamp: _serverTimeNow(),
      );

      // create table object with click
      final tableWithClick = _addClicks(table: table, clicks: [returnClick]);
      final updatedTable = tableWithClick.copyWith(uidThatHasPen: null);

      // update data in database
      return Transaction.success(updatedTable.toJson());
    });
  }

  /// helper function that creates new table object with a new click
  /// added to the archived list of clicks
  RealtimeTable _addClicks({required RealtimeTable table, required List<Click> clicks}) {
    final archivedClicks = table.archivedClicks ?? [];
    final archivedClicksCopy = [...archivedClicks];
    archivedClicksCopy.addAll(clicks);
    final updatedTable = table.copyWith(archivedClicks: archivedClicksCopy);
    return updatedTable;
  }

  /// add new number input to realtime database
  Future<void> addNumberInput({
    required String experimentDocId,
    required int tableNumber,
    required SimpleUser user,
    required String solution,
    required String input,
  }) async {
    // save reference to numberCopyResults
    final numberCopyResultsRef = _realtimeDatabase
        .ref(experimentDocId)
        .child('tables')
        .child('table$tableNumber')
        .child('numberCopyResults');

    await numberCopyResultsRef.runTransaction((Object? currentValue) {
      // create new number input
      final newNumberInput = NumberInput(
        solution: solution,
        input: input,
        timestamp: _serverTimeNow(),
      );

      // exit in case there is no results yet
      if (currentValue == null) {
        final newResult = NumberCopyResult(user: user, numberInputs: [newNumberInput]);
        // update results list in database with first entry
        return Transaction.success([newResult.toJson()]);
      }

      // otherwise convert data to table object and get last click
      final currentResultsList = currentValue as List<dynamic>;
      // get all results for all users
      final currentResults =
          currentResultsList.map((result) => NumberCopyResult.fromJson(result)).toList();
      // get index of entry for specific user
      final myResultIndex = currentResults.indexWhere((result) => result.user == user);

      // if user has not yet entered a result (index == -1)
      if (myResultIndex == -1) {
        // add new result to existing list
        final newResult = NumberCopyResult(user: user, numberInputs: [newNumberInput]);
        currentResults.add(newResult);
      } else {
        // if user already has some results, read them
        final myResult = currentResults[myResultIndex];
        // get list of current inputs
        final currentInputsList = [...myResult.numberInputs];
        // add new input to list
        currentInputsList.add(newNumberInput);
        // update user's result and result list
        final newResult = myResult.copyWith(numberInputs: currentInputsList);
        currentResults[myResultIndex] = newResult;
      }

      // convert list of results back to list of json maps
      final jsonResultsList = currentResults.map((result) => result.toJson()).toList();
      // update list in database
      return Transaction.success(jsonResultsList);
    });
  }

  /// helper function that returns the current server time
  DateTime _serverTimeNow() {
    return DateTime.now().add(databaseTimeOffset);
  }
}

final realtimeDatabaseRepositoryProvider = Provider<RealtimeDatabaseRepository>((ref) {
  return RealtimeDatabaseRepository(
    FirebaseDatabase.instance,
    ref.watch(databaseTimeOffsetRepositoryProvider),
  );
});
