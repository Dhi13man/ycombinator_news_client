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
import 'package:ycombinator_hacker_news/UI/screens/login_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/splash_screen.dart';
import 'package:ycombinator_hacker_news/UI/app_bars.dart';

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
    DataBloc dataBloc = BlocProvider.of<DataBloc>(context);

    // Final check if associated post has no data
    if (post == null) return Container();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: appConstants.getForeGroundColor),
          bottom: BorderSide(color: appConstants.getForeGroundColor),
        ),
      ),
      child: ListTile(
        onTap: (_isValidUrl(post.url)) ? () => dataBloc.clickPost(post) : null,
        tileColor: appConstants.getBackGroundColor,
        isThreeLine: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          post.title ?? 'error',
          style: appConstants.listItemTextStyle,
        ),
        subtitle: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By: ${post.postedBy}' ?? '',
                style: appConstants.listItemSubTextStyle,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  'Posted: ${dataBloc.formatDateTime(post.postedTime)}' ?? '',
                  style: appConstants.listItemSubTextStyle,
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

    // News API Business Logic Ready
    return Container(
      // To Load Complete News Feed (List of Posts) based on current chosen criteria.
      child: FutureBuilder(
        future: _newsBloc.getPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(
              child: SpinKitPouringHourglass(
                color: _appConstants.getForeGroundColor,
              ),
            );

          List<Future<Post>> futurePosts = snapshot.data;

          if (futurePosts.isEmpty)
            return Center(
              child: Text(
                "News feed Empty!\nCheck connection to Hackernews API!",
                textAlign: TextAlign.center,
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
                    return SpinKitWave(
                      color: _appConstants.getForeGroundColor,
                    );

                  Post thisPost = snapshot.data;

                  // Check if post not loaded correctly
                  if (thisPost == null || thisPost.id == -9999999)
                    return Center(child: Container());
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
                    ),
                  );
                if (state is ErrorNewsAPIState)
                  return Center(
                    child: Row(
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

class NewsFeedScreen extends StatelessWidget {
  static const routeName = '/newsfeed';
  NewsFeedScreen({Key key, String title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppConstants appConstants = context.watch<AppConstants>();
    LoginBloc loginBloc = context.watch<LoginBloc>();
    DataBloc dataBloc = context.watch<DataBloc>();

    return Scaffold(
      backgroundColor: appConstants.getForeGroundColor,
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
                  style: appConstants.appBarTitleTextStyle,
                ),
              ),
              StreamBuilder(
                stream: dataBloc.documentStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Text(
                      '...checking Links Opened',
                      style: appConstants.appBarSubTitleTextStyle,
                    );
                  DocumentSnapshot docSnap = snapshot.data;
                  List<PostData> postDataList =
                      dataBloc.extractDataFromFirebase(docSnap.data());
                  return Text(
                    '${postDataList.length} Links Opened',
                    style: appConstants.appBarSubTitleTextStyle,
                  );
                },
              ),
            ],
          ),
        ),
        backgroundColor: appConstants.getForeGroundColor,
        centerTitle: true,
        toolbarHeight: kToolbarHeight,
        leading: AppHeroIcon(
          appConstants: appConstants,
          iconSize: 20.0,
          margin: EdgeInsets.symmetric(horizontal: 5),
          padding: EdgeInsets.all(8),
          backgroundColor: appConstants.getBackGroundColor.withOpacity(0.7),
          foregroundColor: appConstants.getForeGroundColor,
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
        elevation: 1,
        shadowColor: appConstants.getLighterForeGroundColor,
      ),
      body: BlocListener<LoginBloc, LoginState>(
        cubit: loginBloc,
        listener: (context, state) {
          if (state is SignedOutLoginState)
            Navigator.of(context).pushReplacementNamed(
              LoginScreen.routeName,
            );
        },
        child: NewsFeedBody(appConstants: appConstants),
      ),
    );
  }
}