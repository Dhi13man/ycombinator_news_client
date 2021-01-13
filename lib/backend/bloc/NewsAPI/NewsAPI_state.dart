import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

abstract class NewsAPIState extends Equatable {
  final List propss;
  NewsAPIState([this.propss]);

  @override
  List<Object> get props => (propss ?? []);
}

/// UnInitialized News API
class UnNewsAPIState extends NewsAPIState {
  UnNewsAPIState();

  @override
  String toString() => 'Uninitialized API State';
}

/// Loading News State
/// UnInitialized News API
class LoadingNewsAPIState extends NewsAPIState {
  LoadingNewsAPIState();

  @override
  String toString() => 'Loading News State';
}

/// News API Initialized and Loaded State
/// Can either be asking to fetch Top, New or Best News Posts
class InNewsAPIState extends NewsAPIState {
  final String selectedCriteriaButtonText;
  static const String viewByNew = 'New';
  static const String viewByBest = 'Best';
  static const String viewByTop = 'Top';

  InNewsAPIState({String criteria = 'Top'})
      : selectedCriteriaButtonText = criteria,
        super([criteria]) {
    _saveSortingPreferences();
  }

  void _saveSortingPreferences() async {
    Box box = Hive.box('settingsBox');
    await box.put('newsType', selectedCriteriaButtonText);
  }

  /// Criteria of Posts to be fetched from ['new', 'top', 'best']
  String get criteria => selectedCriteriaButtonText.toLowerCase();

  @override
  String toString() => 'News API working State';
}

/// State notifying that there was an Error while retrieving data from News API.
class ErrorNewsAPIState extends NewsAPIState {
  final String errorMessage;

  ErrorNewsAPIState(this.errorMessage) : super([errorMessage]);

  @override
  String toString() => 'ErrorNewsAPIState';
}
