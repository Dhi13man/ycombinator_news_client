import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:ycombinator_hacker_news/backend/bloc/Data/Data_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/Login/Login_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/NewsAPI/NewsAPI_bloc.dart';
import 'package:ycombinator_hacker_news/backend/constants.dart';
import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

import 'package:ycombinator_hacker_news/UI/screens/clicked_newsfeed_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/view_post_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/login_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/splash_screen.dart';
import 'package:ycombinator_hacker_news/UI/app_bars.dart';

class NewsFeedListItem extends StatelessWidget {
  const NewsFeedListItem({
    Key key,
    @required this.post,
  }) : super(key: key);

  final Post post;

  @override
  Widget build(BuildContext context) {
    AppConstants appConstants = context.watch<AppConstants>();
    DataBloc dataBloc = BlocProvider.of<DataBloc>(context);

    // Final check if associated post has no data
    if (post == null) return Container();

    String numCommentsText = 'with ${post.comments.length} ' +
        ((post.comments.length != 1) ? 'Comments' : 'Comment');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: appConstants.getForeGroundColor),
          bottom: BorderSide(color: appConstants.getForeGroundColor),
        ),
      ),
      child: ListTile(
        onTap: () => Navigator.of(context)
            .pushNamed(ViewPostScreen.routeName, arguments: post),
        tileColor: appConstants.getBackGroundColor,
        isThreeLine: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          post.title ?? 'error',
          style: appConstants.textStyleListItem,
        ),
        subtitle: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Hero(
              //  tag: '${post.id}_${post.postedTime.toIso8601String()}_post',
              //child:
              Text(
                'By: ${post.postedBy}, $numCommentsText' ?? '',
                style: appConstants.textStyleSubListItem,
              ),
              //),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  'Posted: ${dataBloc.formatDateTime(post.postedTime)}' ?? '',
                  style: appConstants.textStyleSubListItem,
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
    NewsAPIBloc newsBloc = context.watch<NewsAPIBloc>();
    AppConstants appConstants = context.watch<AppConstants>();

    // News API Business Logic Ready
    return Container(
      // To Load Complete News Feed (List of Posts) based on current chosen criteria.
      child: FutureBuilder(
        future: newsBloc.getPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(
              child: SpinKitPouringHourglass(
                color: appConstants.getForeGroundColor,
                size: 100,
              ),
            );

          List<Future<Post>> futurePosts = snapshot.data;

          Widget noValidPostsRecievedMessage = Center(
            child: Text(
              "News feed Empty!\nCheck connection to Hackernews API!",
              textAlign: TextAlign.center,
              style: appConstants.textStyleBodyMessage,
            ),
          );
          if (futurePosts.isEmpty) return noValidPostsRecievedMessage;

          int countCorruptedPosts = 0; // Ideally zero
          return ListView.builder(
            itemCount: futurePosts.length,
            cacheExtent: MediaQuery.of(context).size.height,
            itemBuilder: (context, index) {
              // To load each individual post.
              return FutureBuilder(
                future: futurePosts[index],
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return SpinKitWave(color: appConstants.getForeGroundColor);

                  Post thisPost = snapshot.data;

                  // Check if post not loaded correctly
                  if (thisPost == null || thisPost.id == -9999999) {
                    if (++countCorruptedPosts == futurePosts.length)
                      return noValidPostsRecievedMessage;
                    return Center(child: Container());
                  }
                  return NewsFeedListItem(post: thisPost);
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
          Expanded(
            child: BlocBuilder<NewsAPIBloc, NewsAPIState>(
              builder: (context, state) {
                // When News API Business Logic Not Ready
                if (state is UnNewsAPIState)
                  return Center(
                    child: SpinKitPouringHourglass(
                      color: _appConstants.getForeGroundColor,
                      size: 100,
                    ),
                  );
                if (state is ErrorNewsAPIState)
                  return Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.error_outline_outlined,
                          color: _appConstants.getForeGroundColor,
                        ),
                        Text(
                          'Error during Post Loading From API!',
                          style: TextStyle(
                            fontSize: 18,
                            color: _appConstants.getForeGroundColor,
                          ),
                        ),
                      ],
                    ),
                  );
                if (state is InNewsAPIState) return NewsFeedList();
                return SpinKitPouringHourglass(
                  color: _appConstants.getForeGroundColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NumberOfOpenedLinks extends StatelessWidget {
  const NumberOfOpenedLinks({
    Key key,
    @required this.appConstants,
  }) : super(key: key);

  final AppConstants appConstants;

  @override
  Widget build(BuildContext context) {
    DataBloc dataBloc = context.watch<DataBloc>();
    return FutureBuilder(
      future: dataBloc.documentCheck(),
      builder: (BuildContext context, AsyncSnapshot futureSnapshot) {
        if (!futureSnapshot.hasData)
          return Text(
            '...checking Links Opened',
            style: appConstants.textStyleAppBarSubTitle,
          );
        return StreamBuilder(
          stream: dataBloc.documentStream(),
          initialData: futureSnapshot.data,
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return Text(
                '...checking Links Opened',
                style: appConstants.textStyleAppBarSubTitle,
              );

            /// Is a [DocumentSnapshot] when firebase is being used,
            /// and direct [List<PostData>] when Local Hive Database
            dynamic docSnap = snapshot.data;
            List<dynamic> postDataList = [];
            if (docSnap is List)
              postDataList = docSnap;
            else if (docSnap is DocumentSnapshot)
              postDataList = dataBloc.extractDataFromFirebase(docSnap.data());
            return Text(
              '${postDataList.length} Links clicked so far!',
              style: appConstants.textStyleAppBarSubTitle,
            );
          },
        );
      },
    );
  }
}

class NewsFeedScreen extends StatelessWidget {
  static const routeName = '/newsfeed';
  NewsFeedScreen({Key key, String title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppConstants appConstants = context.watch<AppConstants>();
    LoginBloc loginBloc = context.watch<LoginBloc>();

    return Scaffold(
      backgroundColor: appConstants.getForeGroundColor,
      appBar: AppBar(
        backgroundColor: appConstants.getForeGroundColor,
        centerTitle: true,
        toolbarHeight: kToolbarHeight,
        elevation: 0,
        leading: AppHeroIcon(
          appConstants: appConstants,
          iconSize: 35.0,
          margin: EdgeInsets.symmetric(horizontal: 5),
          padding: EdgeInsets.all(8),
          backgroundColor: Colors.transparent,
          foregroundColor: appConstants.getBackGroundColor,
        ),
        actions: [
          TextButton(
            onPressed: () => loginBloc.signOut(),
            child: Text(
              'Log out',
              style: TextStyle(color: appConstants.getBackGroundColor),
            ),
          )
        ],
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
                  style: appConstants.textStyleAppBarTitle,
                ),
              ),
              NumberOfOpenedLinks(appConstants: appConstants),
            ],
          ),
        ),
      ),
      body: BlocListener<LoginBloc, LoginState>(
        cubit: loginBloc,
        listener: (context, state) {
          if (state is SignedOutLoginState)
            Navigator.of(context).pushReplacementNamed(
              LoginScreen.routeName,
            );
        },
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity < 0)
              Navigator.of(context).pushNamed(ClickedNewsFeedScreen.routeName);
          },
          child: NewsFeedBody(appConstants: appConstants),
        ),
      ),
    );
  }
}
