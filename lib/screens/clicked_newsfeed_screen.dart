import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ycombinator_hacker_news/backend/bloc/Data/Data_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/Login/Login_bloc.dart';
import 'package:ycombinator_hacker_news/backend/constants.dart';
import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

import 'package:ycombinator_hacker_news/screens/login_screen.dart';
import 'package:ycombinator_hacker_news/screens/splash_screen.dart';
import 'package:ycombinator_hacker_news/screens/sort_bars.dart';

class ClickedNewsFeedListItem extends StatelessWidget {
  const ClickedNewsFeedListItem({
    Key key,
    @required this.post,
  }) : super(key: key);

  final Post post;

  @override
  Widget build(BuildContext context) {
    AppConstants appConstants = context.watch<AppConstants>();
    DataBloc dataBloc = context.watch<DataBloc>();
    return Card(
      elevation: 10,
      shadowColor: appConstants.getLighterForeGroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: appConstants.getForeGroundColor),
        ),
        child: ListTile(
          onTap: () => Navigator.of(context).pushNamed(
            ClickedNewsFeedScreen.routeName,
            arguments: post,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(
            post?.postedBy ?? 'error',
            style: TextStyle(
              color: appConstants.getForeGroundColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '',
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
          isThreeLine: true,
          trailing: IconButton(
            icon: Icon(
              Icons.delete,
              color: appConstants.getForeGroundColor.shade800,
            ),
            onPressed: () => dataBloc.deletePostFromHistory(post),
          ),
          tileColor: appConstants.getBackGroundColor,
        ),
      ),
    );
  }
}

class ClickedNewsFeedList extends StatelessWidget {
  const ClickedNewsFeedList({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DataBloc _dataBloc = context.watch<DataBloc>();
    AppConstants _appConstants = context.watch<AppConstants>();

    return Container(
      // For Streaming favorite posts from Firebase or Local storage.
      child: StreamBuilder(
        stream: _dataBloc.documentStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          DocumentSnapshot docSnap = snapshot.data;
          Future<List<PostData>> clickedPostsFuture =
              _dataBloc.extractDataFromFirebase(docSnap.data());

          // To wait for current list of Favorite posts.
          return FutureBuilder(
            future: clickedPostsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              List<PostData> clickedPosts = snapshot.data;

              if (clickedPosts.isEmpty)
                return Center(
                  child: Text(
                    'No Posts Clicked yet!',
                    style: TextStyle(
                      fontSize: 18,
                      color: _appConstants.getForeGroundColor,
                    ),
                  ),
                );

              return ListView.builder(
                itemCount: clickedPosts.length,
                itemBuilder: (context, index) {
                  return ClickedNewsFeedListItem(
                    post: clickedPosts[index] ?? Post.empty,
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
