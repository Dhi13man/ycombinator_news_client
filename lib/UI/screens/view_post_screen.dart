import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:ycombinator_hacker_news/backend/bloc/NewsAPI/NewsAPI_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/Data/Data_bloc.dart';
import 'package:ycombinator_hacker_news/backend/constants.dart';
import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

/// Clickable Comment Card Widget, capable of displaying or hiding [CommentsList]
/// for it's children Comments.
class CommentsListItem extends StatefulWidget {
  final Comment _comment;
  const CommentsListItem({required Comment comment, Key? key})
      : _comment = comment,
        super(key: key);

  @override
  _CommentsListItemState createState() => _CommentsListItemState();
}

class _CommentsListItemState extends State<CommentsListItem> {
  late bool _areChildrenVisible;

  @override
  void initState() {
    _areChildrenVisible = false;
    super.initState();
  }

  Widget _childrenInfoTextDecoration({
    Widget? child,
    Color color = Colors.white,
  }) {
    if (child == null) return Container();
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: color,
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppConstants appConstants = context.watch<AppConstants>();
    final DataBloc dataBloc = context.watch<DataBloc>();
    final int numChildren = widget._comment.childComments.length;

    // Modified Text Style Just for the cards here
    final TextStyle textStyleListItemModified =
        appConstants.textStyleListItem.copyWith(
      color: appConstants.getBackGroundColor,
    );

    // Build widgets below based on whether Children comments are to be visible or not.
    Widget childWidget = Container();
    Widget hasChildrenText = Container();
    if (numChildren > 0 && _areChildrenVisible) {
      hasChildrenText = _childrenInfoTextDecoration(
        child: Text(
          "Tap to Collapse Children.",
          style: textStyleListItemModified,
        ),
        color: appConstants.getBackGroundColor,
      );
      childWidget = Container(
        height: ((numChildren <= 4) ? numChildren : 4) * 100.0,
        padding: EdgeInsets.only(left: 20, bottom: 10, top: 5),
        child: CommentsList(
          commentIDList: widget._comment.childComments,
          appConstants: appConstants,
        ),
      );
    } else if (numChildren > 0)
      hasChildrenText = _childrenInfoTextDecoration(
        child: Text(
          "Tap to View $numChildren Children.",
          style: textStyleListItemModified,
        ),
        color: appConstants.getBackGroundColor,
      );

    return Column(
      children: [
        RawMaterialButton(
          onPressed: (numChildren > 0)
              ? () => setState(() => _areChildrenVisible = !_areChildrenVisible)
              : null,
          child: Card(
            color: appConstants.getForeGroundColor,
            elevation: 3,
            shadowColor: appConstants.getLighterForeGroundColor[800],
            margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          'By: ${widget._comment.postedBy}, ',
                          style: textStyleListItemModified,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            'Posted: ${dataBloc.formatDateTime(widget._comment.postedTime)}',
                            style: textStyleListItemModified,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      '${widget._comment.title}',
                      style: TextStyle(
                        color: appConstants.getBackGroundColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  hasChildrenText,
                ],
              ),
            ),
          ),
        ),
        childWidget,
      ],
    );
  }
}

/// List of Comments rendered from [List<int>] [commentIDList]
/// which [NewsAPIBloc] fetches from API.
///
/// Recursively called for each Child comment List as needed.
class CommentsList extends StatelessWidget {
  final List<int> _commentIDList;
  final AppConstants _appConstants;
  const CommentsList(
      {required List<int> commentIDList,
      required AppConstants appConstants,
      Key? key})
      : _commentIDList = commentIDList,
        _appConstants = appConstants,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    NewsAPIBloc newsAPIBloc = context.watch<NewsAPIBloc>();
    List<Future<Comment>> _comments =
        newsAPIBloc.getCommentsFromCommentIDList(_commentIDList);
    int countCorruptedComments = 0; // Ideally zero
    return ListView.builder(
      itemCount: _comments.length,
      itemBuilder: (BuildContext context, int index) {
        return FutureBuilder(
          future: _comments[index],
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData)
              return SpinKitWave(color: _appConstants.getForeGroundColor);

            Comment comment = snapshot.data;
            if (comment.childComments.length == 0 && comment.title.isEmpty) {
              if (++countCorruptedComments == _comments.length)
                return Center(
                  child: Text(
                    "No comments!",
                    style: _appConstants.textStyleBodyMessage,
                  ),
                );
              return Container();
            }
            return CommentsListItem(comment: comment);
          },
        );
      },
    );
  }
}

/// Interactable, animated card showing [Post] in UI. Acts as app bar.
class ExpandedPostView extends StatefulWidget {
  const ExpandedPostView({
    Key? key,
    required this.appConstants,
    required this.viewedPost,
  }) : super(key: key);

  final AppConstants appConstants;
  final Post viewedPost;

  @override
  _ExpandedPostViewState createState() => _ExpandedPostViewState();
}

class _ExpandedPostViewState extends State<ExpandedPostView> {
  final double _basePadding = 30, _maxPadding = 60;
  double? _dynamicPadding;

  bool _postHasValidUrl(DataBloc bloc) =>
      bloc.isValidUrl(widget.viewedPost.url!);

  @override
  void initState() {
    _dynamicPadding = _basePadding;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    DataBloc dataBloc = context.watch<DataBloc>();
    return GestureDetector(
      onVerticalDragUpdate: (_postHasValidUrl(dataBloc))
          ? (details) => setState(
                () {
                  if (_dynamicPadding == _basePadding && details.delta.dy < 0)
                    return;
                  else if (_dynamicPadding! >= _maxPadding) {
                    _dynamicPadding = _maxPadding;
                    return;
                  } else
                    _dynamicPadding = _basePadding + 3 * details.delta.dy;
                },
              )
          : null,
      onVerticalDragEnd: (_postHasValidUrl(dataBloc))
          ? (details) {
              if (_dynamicPadding == _maxPadding)
                dataBloc.clickPost(widget.viewedPost);
              setState(() => _dynamicPadding = _basePadding);
            }
          : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding:
            EdgeInsets.only(bottom: _dynamicPadding!, top: _dynamicPadding!),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
          color: (_dynamicPadding != _maxPadding)
              ? widget.appConstants.getLighterForeGroundColor[800]
              : widget.appConstants.getForeGroundColor[900],
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: (_postHasValidUrl(dataBloc))
                ? () => dataBloc.clickPost(widget.viewedPost)
                : null,
            child: Column(
              children: [
                // To complete Transitions from NewsFeedScreen and ClickedNewsFeedScreen
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back),
                      color: widget.appConstants.getBackGroundColor,
                      iconSize: (_dynamicPadding != _maxPadding) ? 28 : 24,
                    ),
                    Text(
                      'By: ${widget.viewedPost.postedBy}',
                      style: widget.appConstants.textStyleAppBarTitle,
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.only(left: 50, right: 15, bottom: 15),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${widget.viewedPost.title}',
                    style: TextStyle(
                      color: widget.appConstants.getBackGroundColor,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 50, right: 15),
                  padding: EdgeInsets.only(top: 5, bottom: 5),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: widget.appConstants.getBackGroundColor),
                    ),
                  ),
                  child: Text(
                    (_postHasValidUrl(dataBloc))
                        ? 'Full Story Link: ${widget.viewedPost.url}'
                        : 'No URL!',
                    style: widget.appConstants.textStyleAppBarTitle
                        .copyWith(fontSize: 10),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the Post [post] in an expanded way, followed by its comments.
class ViewPostScreen extends StatelessWidget {
  final Post? _post;
  static const String routeName = '/postScreen';

  const ViewPostScreen({Post? post, Key? key})
      : _post = post,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    AppConstants appConstants = context.watch<AppConstants>();
    Post viewedPost =
        _post ?? ModalRoute.of(context)!.settings.arguments as Post;

    return Scaffold(
      backgroundColor: appConstants.getBackGroundColor,
      body: Column(
        children: <Widget>[
          ExpandedPostView(appConstants: appConstants, viewedPost: viewedPost),
          Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.only(left: 10, top: 30, bottom: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: appConstants.getForeGroundColor),
              ),
            ),
            child: Text(
              'Comments:',
              style: appConstants.textStyleBodyMessage.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: CommentsList(
              commentIDList: viewedPost.comments,
              appConstants: appConstants,
            ),
          ),
        ],
      ),
    );
  }
}
