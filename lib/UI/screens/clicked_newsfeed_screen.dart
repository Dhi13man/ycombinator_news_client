import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:ycombinator_hacker_news/backend/bloc/Data/Data_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/Login/Login_bloc.dart';
import 'package:ycombinator_hacker_news/backend/constants.dart';
import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

import 'package:ycombinator_hacker_news/UI/screens/login_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/newsfeed_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/splash_screen.dart';
import 'package:ycombinator_hacker_news/UI/app_bars.dart';

class ClickedNewsFeedList extends StatelessWidget {
  const ClickedNewsFeedList({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DataBloc dataBloc = context.watch<DataBloc>();
    AppConstants appConstants = context.watch<AppConstants>();

    return Container(
      // For Streaming favorite posts from Firebase or Local storage.
      child: FutureBuilder(
        future: dataBloc.documentCheck(),
        builder: (BuildContext context, AsyncSnapshot futureSnapshot) {
          if (!futureSnapshot.hasData)
            return Text(
              '...',
              style: appConstants.textStyleBodyMessage,
            );
          return StreamBuilder(
            stream: dataBloc.documentStream(),
            initialData: futureSnapshot.data,
            builder: (context, snapshot) {
              if (dataBloc.state is UnDataState || !snapshot.hasData)
                return Center(
                  child: SpinKitPouringHourglass(
                    color: appConstants.getForeGroundColor,
                    size: 100,
                  ),
                );

              /// Is a [DocumentSnapshot] when firebase is being used,
              /// and direct [List<PostData>] when Local Hive Database
              dynamic docSnap = snapshot.data;

              // Convert to common format.
              List<PostData> postDataList =
                  dataBloc.extractPostDataFromStoreablePostData(
                unprocessedData: docSnap,
              );

              if (postDataList.length == 0)
                return Center(
                  child: Text(
                    "No Posts Clicked yet!\nClick on Some News Stories!",
                    textAlign: TextAlign.center,
                    style: appConstants.textStyleBodyMessage,
                  ),
                );

              return ListView.builder(
                itemCount: postDataList.length,
                itemBuilder: (context, index) {
                  PostData postData = postDataList[index];
                  // To get associated Post from PostData.
                  return FutureBuilder(
                    future: postData.futurePost,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return SpinKitWave(
                          color: appConstants.getForeGroundColor,
                        );

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
                                    color: appConstants
                                        .getForeGroundColor.shade800,
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
    AppConstants appConstants = context.watch<AppConstants>();

    return Scaffold(
      backgroundColor: appConstants.getForeGroundColor,
      appBar: AppBar(
        title: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Post History',
            style: appConstants.appBarTitleTextStyle.copyWith(fontSize: 18),
          ),
        ),
        backgroundColor: appConstants.getForeGroundColor,
        toolbarHeight: kToolbarHeight,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_sharp),
          color: appConstants.getBackGroundColor,
        ),
        actions: [
          AppHeroIcon(
            appConstants: appConstants,
            iconSize: 20.0,
            margin: EdgeInsets.symmetric(horizontal: 0),
            padding: EdgeInsets.all(8),
            backgroundColor: Colors.transparent,
            foregroundColor: appConstants.getBackGroundColor,
          ),
          IconButton(
            onPressed: () async =>
                await BlocProvider.of<DataBloc>(context).clearPostHistory(),
            tooltip: 'Delete all post Click history.',
            icon: Icon(Icons.delete_forever),
            iconSize: 40,
            color: appConstants.getBackGroundColor,
          ),
        ],
        elevation: 1,
        shadowColor: appConstants.getLighterForeGroundColor,
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
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity > 0) Navigator.of(context).pop();
          },
          child: ClickedNewsFeedBody(appConstants: appConstants),
        ),
      ),
    );
  }
}
