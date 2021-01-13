import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';
import 'package:data_connection_checker/data_connection_checker.dart';

import 'package:ycombinator_hacker_news/backend/bloc/NewsAPI/NewsAPI_state.dart';
import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

export 'package:ycombinator_hacker_news/backend/bloc/NewsAPI/NewsAPI_state.dart';

class NewsAPIBloc extends Cubit<NewsAPIState> {
  NewsAPIBloc(NewsAPIState initialState) : super(initialState) {
    _initialize();
  }

  /// Checks if internet connection is working every time API reinitializes.
  ///
  /// API won't waste time trying anything if internet is not working.
  Future<bool> _canConnect() async {
    try {
      return DataConnectionChecker().hasConnection;
    } catch (_) {
      return false;
    }
  }

  /// Initialize or Reinitialize API bloc after checking internet
  Future<void> _initialize() async {
    bool hasInternet = await _canConnect();

    if (!hasInternet)
      emit(ErrorNewsAPIState('No Internet!'));
    else {
      /// Check if user has preferred saved News Type Preferences (Top default)
      Box box = Hive.box('settingsBox');
      String _getSavedCritieria = box.get('newsType');

      emit(
        InNewsAPIState(
          criteria: _getSavedCritieria ?? InNewsAPIState.viewByTop,
        ),
      );
    }
  }

  /// Convert List of IDs [inputIDs] from APIs to proper integer format.
  List<int> _parseIDs(List<dynamic> inputIDs) {
    List<int> out = [];
    inputIDs.forEach(
      (dynamic id) {
        if (id is String)
          out.add(int.parse(id));
        else if (id is int)
          out.add(id);
        else if (id is double) out.add(id.floor());
      },
    );
    return out;
  }

  /// Fetch Post having post ID [id] from News API. Returns a [Future<Post>].
  ///
  /// [repeat] is used to specify how many times the app will try to fetch data before giving up.
  Future<Post> getPostFromID(int id, {int repeat = 1}) async {
    try {
      if (state is ErrorNewsAPIState) await _initialize();
      http.Response response = await http.get(
        'https://hacker-news.firebaseio.com/v0/item/$id.json?print=pretty',
      );
      if (response.statusCode != 200)
        throw (HttpException('Response Code ${response.statusCode}'));
      else {
        String responseOutput = response.body;
        Map<String, dynamic> outputMap = json.decode(responseOutput);

        return Post(
          id: outputMap['id'],
          postedTime:
              DateTime.fromMillisecondsSinceEpoch(outputMap['time'] * 1000),
          url: outputMap['url'],
          comments: _parseIDs(outputMap['kids']),
          postedBy: outputMap['by'],
          title: outputMap['title'],
        );
      }
    } catch (_) {
      if (repeat <= 1) return Future.value(Post.empty);
      return await getPostFromID(id, repeat: repeat - 1);
    }
  }

  /// Fetch Comment having comment ID [id] from News API. Returns a [Future<Comment>].
  ///
  /// [repeat] is used to specify how many times the app will try to fetch data before giving up.
  Future<Comment> getCommentFromID(int id, {int repeat = 1}) async {
    try {
      if (state is ErrorNewsAPIState) await _initialize();

      http.Response response = await http.get(
        'https://hacker-news.firebaseio.com/v0/item/$id.json?print=pretty',
      );
      if (response.statusCode != 200)
        throw (HttpException('Response Code ${response.statusCode}'));
      else {
        String responseOutput = response.body;
        Map<String, dynamic> outputMap = json.decode(responseOutput);
        return Comment(
          id: outputMap['id'],
          postedTime:
              DateTime.fromMillisecondsSinceEpoch(outputMap['time'] * 1000),
          children: _parseIDs(outputMap['kids']),
          parentID: outputMap['parent'],
          postedBy: outputMap['by'],
          // As comment text comes with inline HTML, text must be extracted from them
          title: parse(outputMap['text']).body.text,
        );
      }
    } catch (_) {
      if (repeat <= 1) return Future.value(Comment.empty);
      return await getCommentFromID(id, repeat: repeat - 1);
    }
  }

  /// Get Comments from a list of comment IDs [commentIDs]. Returns a [List<Future<Comment>>].
  ///
  /// Each item is a [Future<Comment>] that will load as needed.
  /// More Efficient than waiting for all comments to load at once.
  List<Future<Comment>> getCommentsFromCommentIDList(List<int> commentIDs) {
    List<Future<Comment>> comments = [];
    commentIDs.forEach(
      (commentID) => comments.add(
        getCommentFromID(commentID, repeat: 3),
      ),
    );
    return comments;
  }

  /// Get posts from Database. Returns a [Future<List<Future<Post>>>].
  ///
  /// Each item is a [Future<Post>] that will load as needed.
  /// More Efficient than waiting for all posts to load at once.
  Future<List<Future<Post>>> getPosts() async {
    try {
      if (state is ErrorNewsAPIState) await _initialize();

      if (state is InNewsAPIState) {
        InNewsAPIState _state = state;

        http.Response response = await http.get(
          'https://hacker-news.firebaseio.com/v0/${_state.criteria}stories.json',
        );
        if (response.statusCode != 200)
          throw (HttpException('Response Code ${response.statusCode}'));
        else {
          String responseOutput = response.body;
          List<dynamic> postIDList = json.decode(responseOutput);

          // Start Fetching posts from IDs.
          List<Future<Post>> outPosts = [];
          postIDList.forEach(
            (postID) => outPosts.add(getPostFromID(postID, repeat: 3)),
          );

          return outPosts;
        }
      } else
        return Future.value([]);
    } catch (_) {
      return Future.value([]);
    }
  }

  /// To choose what kind of posts are to be viewed.
  ///
  ///  [filter] specifies what property to sort with from ['New', 'Top', 'Best']
  /// [isAscending] does nothing and is only there for compatibility.
  void reloadPosts({String filter, bool isAscending}) {
    if (state is InNewsAPIState) {
      InNewsAPIState _state = state;
      emit(UnNewsAPIState());
      Future.delayed(Duration(milliseconds: 60)).then(
        (_) => emit(
          InNewsAPIState(
            criteria: filter ?? _state.criteria,
          ),
        ),
      );
    } else
      _initialize();
  }
}
