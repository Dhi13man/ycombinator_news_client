import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ycombinator_hacker_news/backend/bloc/Data/Data_state.dart';
import 'package:ycombinator_hacker_news/backend/bloc/Login/Login_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/NewsAPI/NewsAPI_bloc.dart';
import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

export 'package:ycombinator_hacker_news/backend/bloc/Data/Data_state.dart';

class DataBloc extends Cubit<DataState> {
  final FirebaseFirestore _firestore;
  final LoginBloc _loginBloc;
  final NewsAPIBloc _newsAPIBloc;
  final String _collectionName = 'posts';

  DataBloc({
    FirebaseFirestore firestore,
    DataState initialState,
    @required NewsAPIBloc newsAPIBloc,
    @required LoginBloc loginBloc,
  })  : _firestore = firestore ?? (kIsWeb)
            ? FirebaseFirestore.instance.enablePersistence()
            : FirebaseFirestore.instance,
        _loginBloc = loginBloc,
        _newsAPIBloc = newsAPIBloc,
        super(initialState ?? UnDataState()) {
    _firestore.settings = Settings(persistenceEnabled: false);
    _initialise();
  }

  /// Token to give each user different session
  String get docToken {
    if (_loginBloc.state is SignedInLoginState) {
      SignedInLoginState _loginState = _loginBloc.state;

      return _loginState.credential.user.uid.toString();
    } else
      return 'default_doc';
  }

  void _initialise() async {
    await _firestore.enableNetwork();
    CollectionReference reservations = FirebaseFirestore.instance.collection(
      _collectionName,
    );

    // Check if user has preffered saved Sorting Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedCriteria = prefs.getString('criteria');
    bool savedOrder = prefs.getBool('isAscending');

    emit(InDataState(
      collection: reservations,
      criteria: savedCriteria ?? InDataState.sortedByClickTime,
      isAscending: savedOrder ?? true,
    ));
  }

  /// Stream from Firestore
  Stream<DocumentSnapshot> documentStream() {
    if (_loginBloc.state is SignedInLoginState && state is InDataState) {
      InDataState _state = state;
      return _state.collection.doc('${docToken}_doc').snapshots();
    } else {
      _initialise();
      return Stream.empty();
    }
  }

  /// Get from Firestore
  Future<DocumentSnapshot> documentCheck() {
    if (_loginBloc.state is SignedInLoginState && state is InDataState) {
      InDataState _state = state;
      return _state.collection.doc('${docToken}_doc').get();
    } else {
      _initialise();
      return Future.value();
    }
  }

  /// To implement sorted Reservation List Building.
  ///  [filter] specifies what property to sort with from ['Time', 'Number of Clicks']
  /// List wil be in ascending order if [isAscending] is true
  void rebuildClickedPostsStream({String filter, bool isAscending}) {
    if (state is InDataState) {
      InDataState _state = state;
      emit(
        InDataState(
          collection: _state.collection,
          criteria: filter ?? _state.criteria,
          isAscending: isAscending ?? _state.isAscending,
        ),
      );
    } else
      _initialise();
  }

  Future<int> _timesPostClickedEarlier(int postID) async {
    String postKey = postID.toString();
    DocumentSnapshot snap = await documentCheck();
    Map<String, dynamic> currentData = snap.data();
    if (currentData == null || !currentData.containsKey(postKey)) return 0;
    return currentData[postKey]['clicks'];
  }

  Future<bool> addPost(Post post) async {
    if (_loginBloc.state is SignedInLoginState && state is InDataState) {
      InDataState _state = state;
      DocumentReference reference = _state.collection.doc('${docToken}_doc');
      int clickedTimes = await _timesPostClickedEarlier(post.id);

      if (clickedTimes > 0) {
        Map<String, dynamic> _editedMappedPost = clickedPostToMap(post);
        _editedMappedPost['clicks'] = clickedTimes + 1;

        await reference.update(_editedMappedPost);
        return true;
      }

      await reference.set(
        clickedPostToMap(post),
        SetOptions(merge: true),
      );
      return true;
    } else {
      _loginBloc.emit(SignedOutLoginState());
      return false;
    }
  }

  Future<void> deletePostFromHistory(Post post) async {
    if (_loginBloc.state is SignedInLoginState && state is InDataState) {
      InDataState _state = state;
      CollectionReference reference = _state.collection;
      await reference
          .doc('${docToken}_doc')
          .update({'${post.id}': FieldValue.delete()});
    } else
      _loginBloc.emit(SignedOutLoginState());
  }

  /// Utilities

  /// Extracts Database from Firestore and converts it to a list of [PostData]
  List<PostData> extractDataFromFirebase(Map<dynamic, dynamic> firebaseData) {
    List<PostData> outputPostsList = [];
    firebaseData?.forEach(
      (key, value) => outputPostsList.add(
        _mapToClickedPost(postID: key, postData: value),
      ),
    );
    outputPostsList.sort((PostData a, PostData b) {
      if (state is InDataState) {
        InDataState _state = state;
        String _criteria = _state.criteria;
        int isAscending = (_state.isAscending) ? 1 : -1;
        if (_criteria == 'time')
          return isAscending * a.lastClickTime.compareTo(b.lastClickTime);
        if (_criteria == 'clicks')
          return isAscending * a.clicks.compareTo(b.clicks);
      }
      return 0;
    });
    return outputPostsList;
  }

  /// Extracts a Map of values from a Reservation Class
  Map<String, dynamic> clickedPostToMap(Post post) => {
        post.id.toString(): {'time': DateTime.now(), 'clicks': 1},
      };

  /// Extracts a Reservation Class from a Firebase Map of values
  PostData _mapToClickedPost({dynamic postID, Map<String, dynamic> postData}) {
    try {
      int id;
      if (postID is String)
        id = int.parse(postID);
      else if (postID is int)
        id = postID;
      else
        throw ('Invalid Data Type');

      Post _post = Post.empty; // TODO: Implement id to Post getter
      return PostData(
        clicks: postData['clicks'],
        lastClickTime: postData['time'],
        post: _post,
      );
    } catch (e) {
      return PostData.empty;
    }
  }

  /// Reformat Date String to enable parsing
  /// from mm/dd/yyyy HH:MM:SS to yyyy-dd-mmmm HH:MM:SS
  String reformatDate(String inDateString) {
    String _dateString = inDateString.replaceAll('/', '-');
    List<String> dateTimeTemp = _dateString.split(' ');
    List<String> dateTemp = dateTimeTemp[0].split('-');

    // 0 padding if needed
    for (int i = 0; i < dateTemp.length; i++) {
      String element = dateTemp[i];
      if (element.length == 1) dateTemp[i] = '0$element';
    }

    // Swap Month and day
    String temp = dateTemp[0];
    dateTemp[0] = dateTemp[1];
    dateTemp[1] = temp;

    dateTimeTemp[0] = dateTemp.reversed.join('-');
    _dateString = dateTimeTemp.join(' ');
    return _dateString;
  }

  String dateTimeToString(DateTime dateTime) =>
      dateTime.toIso8601String().replaceAll('T', ' Time: ');

  DateTime timestampToDatetime(Timestamp inputTimestamp) =>
      inputTimestamp.toDate();
}
