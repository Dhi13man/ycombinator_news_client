import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:bloc/bloc.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ycombinator_hacker_news/backend/bloc/NewsAPI/NewsAPI_state.dart';
import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

export 'package:ycombinator_hacker_news/backend/bloc/NewsAPI/NewsAPI_state.dart';

class NewsAPIBloc extends Cubit<NewsAPIState> {
  NewsAPIBloc(NewsAPIState initialState) : super(initialState) {
    _initialize();
  }

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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String _getSavedCritieria = prefs.getString('newsType');
      emit(
        InNewsAPIState(
          criteria: _getSavedCritieria ?? InNewsAPIState.viewByTop,
        ),
      );
    }
  }

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
          comments: outputMap['kids'],
          postedBy: outputMap['by'],
          title: outputMap['title'],
        );
      }
    } catch (_) {
      if (repeat <= 1) return Future.value(Post.empty);
      return await getPostFromID(id, repeat: repeat - 1);
    }
  }

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
          children: outputMap['kids'],
          parentID: outputMap['parent'],
          postedBy: outputMap['by'],
          title: outputMap['text'],
        );
      }
    } catch (_) {
      if (repeat <= 1) return Future.value(Comment.empty);
      return await getCommentFromID(id, repeat: repeat - 1);
    }
  }

  Future<List<Future<Post>>> getPosts() async {
    try {
      if (state is ErrorNewsAPIState) await _initialize();

      if (state is InNewsAPIState) {
        InNewsAPIState _state = state;

        http.Response response = await http.get(
          'https://hacker-news.firebaseio.com/v0/${_state.criteria}stories.json?print=pretty',
        );
        if (response.statusCode != 200)
          throw (HttpException('Response Code ${response.statusCode}'));
        else {
          String responseOutput = response.body;
          List<dynamic> postIDList = json.decode(responseOutput);

          List<Future<Post>> outPosts = [];

          postIDList.forEach((postID) => outPosts.add(getPostFromID(postID)));
          return outPosts;
        }
      } else
        return Future.value([]);
    } catch (_) {
      return Future.value([]);
    }
  }

  /// To implement sorted Post List Building.
  ///  [filter] specifies what property to sort with from ['Time', 'Number of Clicks']
  /// List wil be in ascending order if [isAscending] is true
  void reloadPosts({String filter, bool isAscending}) {
    if (state is InNewsAPIState) {
      InNewsAPIState _state = state;
      emit(UnNewsAPIState());
      Future.delayed(Duration(milliseconds: 500)).then(
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
