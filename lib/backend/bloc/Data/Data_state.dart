import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class DataState extends Equatable {
  final List? propss;
  DataState([this.propss]);

  @override
  List<Object> get props => (propss as List<Object>? ?? []);
}

/// UnInitialized
class UnDataState extends DataState {
  @override
  String toString() => 'FireBase Uninitialised';
}

/// Initialized
class InDataState extends DataState {
  final CollectionReference collection;
  final String selectedCriteriaButtonText;
  final bool isAscending;
  static const String sortedByClickTime = 'Time';
  static const String sortedByClicksNumber = 'Number of Clicks';

  InDataState({
    required this.collection,
    String criteria = 'Time',
    this.isAscending = true,
  })  : selectedCriteriaButtonText = criteria,
        super([collection, criteria, isAscending]) {
    _saveSortingPreferences();
  }

  void _saveSortingPreferences() async {
    Box box = Hive.box('settingsBox');
    await box.put('criteria', selectedCriteriaButtonText);
    await box.put('isAscending', isAscending);
  }

  /// Default filter is ['time']
  String get criteria {
    if (selectedCriteriaButtonText
            .compareTo(InDataState.sortedByClicksNumber) ==
        0) return 'clicks';
    return 'time';
  }

  @override
  String toString() => 'Firebase Initialised and working State';
}

/// Error
class ErrorDataState extends DataState {
  final String errorMessage;

  ErrorDataState(this.errorMessage) : super([errorMessage]);

  @override
  String toString() => 'ErrorDataState';
}
