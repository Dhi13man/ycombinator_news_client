import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class DataState extends Equatable {
  final List propss;
  DataState([this.propss]);

  @override
  List<Object> get props => (propss ?? []);
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
    @required this.collection,
    String criteria = 'Time',
    this.isAscending = true,
  })  : selectedCriteriaButtonText = criteria,
        super([collection, criteria, isAscending]) {
    _saveSortingPreferences();
  }

  void _saveSortingPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('criteria', selectedCriteriaButtonText);
    await prefs.setBool('isAscending', isAscending);
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
