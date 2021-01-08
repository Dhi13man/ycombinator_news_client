import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ycombinator_hacker_news/backend/bloc/Data/Data_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/Login/Login_bloc.dart';
import 'package:ycombinator_hacker_news/backend/constants.dart';
import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

import 'package:ycombinator_hacker_news/screens/login_screen.dart';
import 'package:ycombinator_hacker_news/screens/newsfeed_screen.dart';
import 'package:ycombinator_hacker_news/screens/splash_screen.dart';
import 'package:ycombinator_hacker_news/screens/sort_bars.dart';

class ClickedNewsFeedList extends StatelessWidget {
  const ClickedNewsFeedList({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DataBloc dataBloc = context.watch<DataBloc>();
    AppConstants appConstants = context.watch<AppConstants>();

    return Container(
      // For Streaming favorite posts from Firebase or Local storage.
      child: StreamBuilder(
        stream: dataBloc.documentStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          DocumentSnapshot docSnap = snapshot.data;
          List<PostData> postDataList =
              dataBloc.extractDataFromFirebase(docSnap.data());

          return ListView.builder(
            itemCount: postDataList.length,
            itemBuilder: (context, index) {
              PostData postData = postDataList[index];
              // To get associated Post from PostData.
              return FutureBuilder(
                future: postData.futurePost,
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());

                  Post post = snapshot.data;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            NewsFeedListItem(
                              post: post ?? Post.empty,
                            ),
                            Text(
                              'Last Clicked: ${dataBloc.formatDateTime(postData.lastClickTime)}',
                              style: appConstants.listItemSubTextStyle,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: appConstants.getForeGroundColor.shade800,
                              ),
                              tooltip: 'Delete Post from Clicked History!',
                              onPressed: () =>
                                  dataBloc.deletePostFromHistory(post),
                            ),
                            Text(
                              '${postData.clicks} Clicks',
                              style: appConstants.listItemTextStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class ClickedNewsFeedBody extends StatelessWidget {
  const ClickedNewsFeedBody({
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
          FirebaseDataSortBar(),
          Expanded(child: ClickedNewsFeedList()),
        ],
      ),
    );
  }
}

class ClickedNewsFeedScreen extends StatelessWidget {
  static const routeName = '/clickedfeed';
  ClickedNewsFeedScreen({Key key, String title}) : super(key: key);

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
        cubit: BlocProvider.of<LoginBloc>(context),
        listener: (context, state) {
          if (state is SignedOutLoginState) {
            Navigator.of(context).pushReplacementNamed(
              LoginScreen.routeName,
            );
          }
        },
        child: ClickedNewsFeedBody(appConstants: _appConstants),
      ),
    );
  }
}
