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
      return await DataConnectionChecker().hasConnection;
    } catch (_) {
      return false;
    }
  }

  void _initialize() async {
    bool hasInternet = await _canConnect();

    // Check if user has preffered saved Sorting Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedCriteria = prefs.getString('newsType');

    if (!hasInternet)
      emit(ErrorNewsAPIState('No Internet!'));
    else
      emit(InNewsAPIState(criteria: savedCriteria ?? InNewsAPIState.viewByTop));
  }

  Future<Post> getPostFromID(int id) async {
    try {
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
          postedTime: DateTime.fromMillisecondsSinceEpoch(outputMap['time']),
          url: outputMap['url'],
          comments: outputMap['kids'],
          postedBy: outputMap['by'],
          title: outputMap['title'],
        );
      }
    } catch (e) {
      emit(ErrorNewsAPIState(e.toString()));
      return Post.empty;
    }
  }

  Future<Comment> getCommentFromID(int id) async {
    try {
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
          postedTime: DateTime.fromMillisecondsSinceEpoch(outputMap['time']),
          children: outputMap['kids'],
          parentID: outputMap['parent'],
          postedBy: outputMap['by'],
          title: outputMap['text'],
        );
      }
    } catch (e) {
      emit(ErrorNewsAPIState(e.toString()));
      return Comment.empty;
    }
  }
}
