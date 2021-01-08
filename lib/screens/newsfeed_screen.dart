import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ycombinator_hacker_news/backend/bloc/Data/Data_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/Login/Login_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/NewsAPI/NewsAPI_bloc.dart';
import 'package:ycombinator_hacker_news/backend/constants.dart';
import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

import 'package:ycombinator_hacker_news/screens/clicked_newsfeed_screen.dart';
import 'package:ycombinator_hacker_news/screens/login_screen.dart';
import 'package:ycombinator_hacker_news/screens/splash_screen.dart';
import 'package:ycombinator_hacker_news/screens/sort_bars.dart';

class NewsFeedListItem extends StatelessWidget {
  const NewsFeedListItem({
    Key key,
    @required this.post,
  }) : super(key: key);

  final Post post;

  bool _isValidUrl(String inputString) {
    try {
      return Uri.tryParse(inputString) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    AppConstants appConstants = context.watch<AppConstants>();

    // Final check if associated post has no data
    if (post == null || post == Post.empty) return Container();

    return Card(
      elevation: 10,
      shadowColor: appConstants.getLighterForeGroundColor,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: appConstants.getForeGroundColor),
        ),
        child: ListTile(
          onTap: (post.url != null && _isValidUrl(post.url))
              ? () => launch(post.url)
              : null,
          tileColor: appConstants.getBackGroundColor,
          isThreeLine: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(
            post?.title ?? 'error',
            style: TextStyle(
              color: appConstants.getForeGroundColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'by: ${post?.postedBy}' ?? '',
                style: TextStyle(
                  color: appConstants.getForeGroundColor,
                  fontSize: 10,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  '',
                  style: TextStyle(
                    color: appConstants.getForeGroundColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsFeedList extends StatelessWidget {
  const NewsFeedList({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    NewsAPIBloc _newsBloc = context.watch<NewsAPIBloc>();
    AppConstants _appConstants = context.watch<AppConstants>();

    // When News API Business Logic Not Ready
    if (!(_newsBloc.state is InNewsAPIState))
      return Center(
        child: Text(
          'Preparing Feed!',
          style: TextStyle(
            fontSize: 18,
            color: _appConstants.getForeGroundColor,
          ),
        ),
      );

    // News API Business Logic Ready
    return Container(
      // To Load Complete News Feed (List of Posts) based on current chosen criteria.
      child: FutureBuilder(
        future: _newsBloc.getPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          List<Future<Post>> futurePosts = snapshot.data;

          if (futurePosts.isEmpty)
            return Center(
              child: Text(
                'News feed Empty!',
                style: TextStyle(
                  fontSize: 18,
                  color: _appConstants.getForeGroundColor,
                ),
              ),
            );

          return ListView.builder(
            itemCount: futurePosts.length,
            cacheExtent: MediaQuery.of(context).size.height,
            itemBuilder: (context, index) {
              // To load each individual post.
              return FutureBuilder(
                future: futurePosts[index],
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());
                  Post thisPost = snapshot.data;

                  if (thisPost == null) // Corrupted post recieved
                    return Container();
                  return NewsFeedListItem(
                    post: thisPost ?? Post.empty,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class NewsFeedBody extends StatelessWidget {
  const NewsFeedBody({
    Key key,
    @required AppConstants appConstants,
  })  : _appConstants = appConstants,
        super(key: key);

  final AppConstants _appConstants;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _appConstants.getBackGroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        children: [
          NewsAPICriteriaSelectBar(),
          Expanded(child: NewsFeedList()),
        ],
      ),
    );
  }
}

class NewsFeedScreen extends StatelessWidget {
  static const routeName = '/newsfeed';
  NewsFeedScreen({Key key, String title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppConstants _appConstants = context.watch<AppConstants>();
    LoginBloc _loginBloc = context.watch<LoginBloc>();

    return Scaffold(
      backgroundColor: _appConstants.getForeGroundColor,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            ClickedNewsFeedScreen.routeName,
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'News Feed',
                  style: TextStyle(color: _appConstants.getBackGroundColor),
                ),
              ),
              Text(
                '0 Links Opened',
                style: TextStyle(
                  color: _appConstants.getBackGroundColor,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: _appConstants.getForeGroundColor,
        centerTitle: true,
        toolbarHeight: kToolbarHeight,
        leading: AppHeroIcon(
          appConstants: _appConstants,
          iconSize: 20.0,
          margin: EdgeInsets.symmetric(horizontal: 5),
          padding: EdgeInsets.all(8),
          backgroundColor: _appConstants.getBackGroundColor.withOpacity(0.7),
          foregroundColor: _appConstants.getForeGroundColor,
        ),
        actions: [
          TextButton(
            onPressed: () => _loginBloc.signOut(),
            child: Text(
              'Log out',
              style: TextStyle(color: _appConstants.getBackGroundColor),
            ),
          )
        ],
        elevation: 1,
        shadowColor: _appConstants.getLighterForeGroundColor,
      ),
      body: BlocListener<LoginBloc, LoginState>(
        cubit: _loginBloc,
        listener: (context, state) {
          if (state is SignedOutLoginState) {
            Navigator.of(context).pushReplacementNamed(
              LoginScreen.routeName,
            );
          }
        },
        child: NewsFeedBody(appConstants: _appConstants),
      ),
    );
  }
}
