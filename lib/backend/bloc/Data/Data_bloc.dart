import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ycombinator_hacker_news/backend/bloc/Data/Data_state.dart';
import 'package:ycombinator_hacker_news/backend/bloc/Login/Login_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/NewsAPI/NewsAPI_bloc.dart';
import 'package:ycombinator_hacker_news/backend/hiveDatabase/databaseHandler.dart';
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
    _initialize();
  }

  /// Token to give each user different session
  String get docToken {
    if (_loginBloc.state is SignedInLoginState) {
      SignedInLoginState _loginState = _loginBloc.state;
      if (_loginState.credential != null)
        return _loginState.credential.user?.uid.toString();
    }
    return 'default_doc';
  }

  /// Checks if usage is going on without Firebase.
  ///
  /// Used to decide if Hive Database is needed.
  bool get isLocalDatabaseInUse => docToken.compareTo('default_doc') == 0;

  /// Initialize the business logic (and Firebase if authenticated)
  void _initialize() async {
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

  /// Stream from Database.
  ///
  /// Returns [Stream<DocumentSnapshot>] when Firebase is in use.
  /// Returns [Stream<List<StoreablePostData>>] when Local Database is in use.
  Stream<dynamic> documentStream() {
    if (_loginBloc.state is SignedInLoginState && state is InDataState) {
      // Handle Firebase-less local application
      if (isLocalDatabaseInUse)
        return PostDataHiveDatabaseHandler.watchPostDataFromBox();

      InDataState _state = state;
      return _state.collection.doc('${docToken}_doc').snapshots();
    } else {
      _initialize();
      return Stream.empty();
    }
  }

  /// Get from Database
  ///
  /// Returns [Future<DocumentSnapshot>] when Firebase is in use.
  /// Returns [Future<List<StoreablePostData>>] when Local Database is in use.
  Future<dynamic> documentCheck() async {
    if (_loginBloc.state is SignedInLoginState && state is InDataState) {
      // Handle Firebase-less local application
      if (isLocalDatabaseInUse) {
        Map<dynamic, StoreablePostData> map =
            await PostDataHiveDatabaseHandler.getPostDataFromBox();
        return map.values.toList();
      }
      InDataState _state = state;
      return await _state.collection.doc('${docToken}_doc').get();
    } else {
      _initialize();
      return Future.value();
    }
  }

  /// When User wants to Open URL, Save to databases and Open
  void clickPost(Post post, {BuildContext context}) async {
    // Only tries opening the Post URL if it is a valid URL.
    bool isValidUrl(String inputString) {
      try {
        return Uri.tryParse(inputString) != null;
      } catch (_) {
        return false;
      }
    }

    bool didOpen = false;
    try {
      if (isValidUrl(post.url)) didOpen = await launch(post.url);
    } catch (_) {
      didOpen = false;
    }
    if (didOpen)
      addPost(post);
    else if (context != null)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Center(child: Text('No valid URL')),
          content: Text('There is no openable URL associated with this post!'),
        ),
      );
  }

  /// Returns how many time [Post] of id [postID] has been clicked so far
  Future<int> _timesPostClickedEarlier(int postID) async {
    String postKey = postID.toString();

    // Handle Firebase-less local application
    if (isLocalDatabaseInUse) {
      Map<dynamic, StoreablePostData> box =
          await PostDataHiveDatabaseHandler.getPostDataFromBox();

      Map<int, PostData> postDataList = {};
      box.forEach(
        (dynamic postID, StoreablePostData element) =>
            postDataList[postID] = _storeablePostDataToPostData(element),
      );

      if (!postDataList.containsKey(postID)) return 0;
      return postDataList[postID].clicks;
    }

    // Will break if somehow this code executes in Local Database mode,
    // shouldn't happen in normal conditions.
    DocumentSnapshot snap = await documentCheck();
    Map<String, dynamic> currentData = snap.data();

    if (currentData == null || !currentData.containsKey(postKey)) return 0;
    return currentData[postKey]['clicks'];
  }

  /// Called to save [post] when it is clicked by user.
  Future<bool> addPost(Post post) async {
    if (_loginBloc.state is SignedInLoginState && state is InDataState) {
      InDataState _state = state;
      int clickedTimes = await _timesPostClickedEarlier(post.id);

      // Handle Firebase-less local application
      if (isLocalDatabaseInUse) {
        await PostDataHiveDatabaseHandler.writeToDB(
          postID: post.id,
          postData: PostData(
            clicks: clickedTimes + 1,
            lastClickTime: DateTime.now(),
            futurePost: Future.value(post),
          ),
        );
        return true;
      }

      DocumentReference reference = _state.collection.doc('${docToken}_doc');

      if (clickedTimes > 0) {
        Map<String, dynamic> _editedMappedPost = _clickedPostToMap(post);
        _editedMappedPost[post.id.toString()]['clicks'] = clickedTimes + 1;

        await reference.update(_editedMappedPost);
        return true;
      }

      await reference.set(
        _clickedPostToMap(post),
        SetOptions(merge: true),
      );

      return true;
    } else {
      _loginBloc.emit(SignedOutLoginState());
      return false;
    }
  }

  /// Deletes Given [post] from saved clicked posts.
  Future<void> deletePostFromHistory(Post post) async {
    if (_loginBloc.state is SignedInLoginState && state is InDataState) {
      InDataState _state = state;
      emit(UnDataState());

      // Handle Firebase-less local application
      if (isLocalDatabaseInUse) {
        await PostDataHiveDatabaseHandler.deletePostData(postID: post.id);
        emit(_state);
        return;
      }

      CollectionReference reference = _state.collection;
      await reference
          .doc('${docToken}_doc')
          .update({'${post.id}': FieldValue.delete()});
      emit(_state);
    } else
      _loginBloc.emit(SignedOutLoginState());
  }

  /// Deletes Given [post] from saved clicked posts.
  Future<int> clearPostHistory() async {
    if (_loginBloc.state is SignedInLoginState && state is InDataState) {
      InDataState _state = state;
      emit(UnDataState());

      // Handle Firebase-less local application
      if (isLocalDatabaseInUse) {
        int out = await PostDataHiveDatabaseHandler.clearBox();
        emit(_state);
        return out;
      }

      CollectionReference reference = _state.collection;
      await reference.doc('${docToken}_doc').delete();
      emit(_state);
      return 1;
    } else
      _loginBloc.emit(SignedOutLoginState());
    return 0;
  }

  /// To implement sorted Post List Building.
  ///
  ///  [filter] specifies what property to sort with from ['Time', 'Number of Clicks']
  /// List wil be in ascending order if [isAscending] is true
  void rebuildClickedPostsStream({String filter, bool isAscending}) {
    if (state is InDataState) {
      InDataState _state = state;
      Future.delayed(Duration(milliseconds: 30))
          .then((_) => emit(UnDataState()));
      emit(
        InDataState(
          collection: _state.collection,
          criteria: filter ?? _state.criteria,
          isAscending: isAscending ?? _state.isAscending,
        ),
      );
    } else
      _initialize();
  }

  /// Utilities

  /// Sorts Post based on criteria in [InNewsState].
  List<PostData> _sortPostList(List<PostData> postDataList) {
    postDataList.sort(
      (PostData a, PostData b) {
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
      },
    );
    return postDataList;
  }

  /// Extracts Database from Firestore and converts it to a list of [PostData]
  List<PostData> extractDataFromFirebase(
    Map<String, dynamic> firebaseData,
  ) {
    List<PostData> postDataList = [];
    firebaseData?.forEach(
      (key, value) => postDataList.add(
        _mapToClickedPost(postID: key, postData: value),
      ),
    );

    return _sortPostList(postDataList);
  }

  /// Extracts a Map of values from a Reservation Class
  Map<String, dynamic> _clickedPostToMap(Post post) => {
        post.id.toString(): {'time': DateTime.now(), 'clicks': 1},
      };

  /// Extracts a Reservation Class from a Firebase Map of values
  PostData _mapToClickedPost({
    dynamic postID,
    Map<String, dynamic> postData,
  }) {
    try {
      int id;
      if (postID is String)
        id = int.parse(postID);
      else if (postID is int)
        id = postID;
      else
        throw ('Invalid Data Type');

      return PostData(
        clicks: postData['clicks'],
        lastClickTime: timestampToDatetime(postData['time']),
        futurePost: _newsAPIBloc.getPostFromID(id, repeat: 10),
      );
    } catch (e) {
      return PostData.empty;
    }
  }

  /// Utility Function to convert [StoreablePostData] to [PostData]
  PostData _storeablePostDataToPostData(StoreablePostData storeablePostData) =>
      PostData(
        clicks: storeablePostData.clicks,
        futurePost: _newsAPIBloc.getPostFromID(storeablePostData.postID),
        lastClickTime: storeablePostData.lastClickTime,
      );

  /// Utility function that converts Firebase and Hive Database output types into [List<PostData>].
  ///
  /// Input [unprocessedData] may either be [List<StoreablePostData>] or [DocumentSnapshot].
  List<PostData> extractPostDataFromStoreablePostData(
      {@required dynamic unprocessedData}) {
    // Ensure proper input
    assert(unprocessedData != null);
    if (unprocessedData is List) {
      List<StoreablePostData> temp = unprocessedData;

      // Make necessary Conversions.
      List<PostData> out = [];
      temp.forEach(
        (StoreablePostData element) =>
            out.add(_storeablePostDataToPostData(element)),
      );
      return _sortPostList(out);
    } else if (unprocessedData is DocumentSnapshot)
      return extractDataFromFirebase(unprocessedData.data());
    else
      throw ("Improper input!");
  }

  /// Reformat Date String to look Readable
  String formatDateTime(DateTime dateTime) {
    String out = dateTime.toIso8601String().replaceAll('T', ' Time: ');
    return out.substring(0, out.length - 4);
  }

  /// Converts [Timestamp] input [inputTimestamp] to [DateTime].
  DateTime timestampToDatetime(Timestamp inputTimestamp) =>
      inputTimestamp.toDate();
}
