import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:ycombinator_hacker_news/backend/bloc/Data/Data_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/NewsAPI/NewsAPI_bloc.dart';
import 'package:ycombinator_hacker_news/backend/constants.dart';

class SortButton extends StatelessWidget {
  const SortButton({
    Key key,
    @required String sortByText,
    @required String selectedCriteriaButtonText,
    @required void Function({String filter, bool isAscending}) rebuildFunction,
  })  : _sortByText = sortByText ?? 'null',
        _selectedCriteriaButtonText = selectedCriteriaButtonText ?? sortByText,
        assert(rebuildFunction != null),
        _rebuildClickedPostsStream = rebuildFunction,
        super(key: key);

  final String _sortByText;
  final String _selectedCriteriaButtonText;
  final void Function({String filter, bool isAscending})
      _rebuildClickedPostsStream;

  @override
  Widget build(BuildContext context) {
    AppConstants appConstants = context.watch<AppConstants>();
    return Container(
      alignment: Alignment.bottomRight,
      height: 20,
      margin: EdgeInsets.symmetric(horizontal: 7),
      child: CupertinoButton(
        padding: EdgeInsets.all(5),
        color: appConstants.getForeGroundColor.shade800,
        disabledColor: Colors.teal[900],
        child: Text(
          _sortByText,
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
        onPressed: (_sortByText != _selectedCriteriaButtonText)
            ? () => _rebuildClickedPostsStream(
                  filter: _sortByText,
                )
            : null,
      ),
    );
  }
}

class FirebaseDataSortBar extends StatelessWidget {
  const FirebaseDataSortBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppConstants _appConstants = context.watch<AppConstants>();
    DataBloc dataBloc = context.watch<DataBloc>();
    bool isAscendingSort = true;
    String selectedCriteriaButtonText = InDataState.sortedByClickTime;

    if (dataBloc.state is InDataState) {
      InDataState state = dataBloc.state;
      isAscendingSort = state.isAscending;
      selectedCriteriaButtonText = state.selectedCriteriaButtonText;
    }

    return Container(
      height: 30,
      margin: EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sort By: ',
              style: TextStyle(
                color: _appConstants.getForeGroundColor,
              ),
            ),
          ),
          SortButton(
            sortByText: InDataState.sortedByClickTime,
            rebuildFunction: dataBloc.rebuildClickedPostsStream,
            selectedCriteriaButtonText: selectedCriteriaButtonText,
          ),
          SortButton(
            sortByText: InDataState.sortedByClicksNumber,
            rebuildFunction: dataBloc.rebuildClickedPostsStream,
            selectedCriteriaButtonText: selectedCriteriaButtonText,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => dataBloc.rebuildClickedPostsStream(
                  isAscending: !isAscendingSort,
                  filter: selectedCriteriaButtonText,
                ),
                icon: (isAscendingSort)
                    ? Icon(Icons.arrow_downward_rounded)
                    : Icon(Icons.arrow_upward_rounded),
                color: _appConstants.getForeGroundColor.shade800,
                iconSize: 18,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class NewsAPICriteriaSelectBar extends StatelessWidget {
  const NewsAPICriteriaSelectBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppConstants appConstants = context.watch<AppConstants>();
    NewsAPIBloc newsAPIBloc = context.watch<NewsAPIBloc>();
    String selectedCriteriaButtonText = InNewsAPIState.viewByTop;

    if (newsAPIBloc.state is InNewsAPIState) {
      InNewsAPIState state = newsAPIBloc.state;
      selectedCriteriaButtonText = state.selectedCriteriaButtonText;
    }

    return Container(
      height: 30,
      margin: EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              'View Posts: ',
              style: TextStyle(
                color: appConstants.getForeGroundColor,
              ),
            ),
          ),
          SortButton(
            sortByText: InNewsAPIState.viewByTop,
            rebuildFunction: newsAPIBloc.reloadPosts,
            selectedCriteriaButtonText: selectedCriteriaButtonText,
          ),
          SortButton(
            sortByText: InNewsAPIState.viewByBest,
            rebuildFunction: newsAPIBloc.reloadPosts,
            selectedCriteriaButtonText: selectedCriteriaButtonText,
          ),
          SortButton(
            sortByText: InNewsAPIState.viewByNew,
            rebuildFunction: newsAPIBloc.reloadPosts,
            selectedCriteriaButtonText: selectedCriteriaButtonText,
          ),
          ReloadPostsButton(
            rebuildFunction: newsAPIBloc.reloadPosts,
            selectedCriteriaButtonText: selectedCriteriaButtonText,
            appConstants: appConstants,
          ),
        ],
      ),
    );
  }
}

class ReloadPostsButton extends StatelessWidget {
  const ReloadPostsButton({
    Key key,
    @required Function({String filter, bool isAscending}) rebuildFunction,
    @required this.selectedCriteriaButtonText,
    @required this.appConstants,
  })  : _rebuildClickedPostsStream = rebuildFunction,
        super(key: key);

  final void Function({String filter, bool isAscending})
      _rebuildClickedPostsStream;
  final String selectedCriteriaButtonText;
  final AppConstants appConstants;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.topRight,
        child: IconButton(
          onPressed: () => _rebuildClickedPostsStream(
            filter: selectedCriteriaButtonText,
          ),
          padding: const EdgeInsets.only(bottom: 2),
          icon: Icon(Icons.refresh),
          iconSize: 30,
          color: appConstants.getForeGroundColor,
        ),
      ),
    );
  }
}
