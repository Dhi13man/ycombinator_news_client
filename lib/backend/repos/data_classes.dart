import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'data_classes.g.dart';

/// Comment model
///
/// [Comment.empty] represents an unauthenticated reservation.
class Comment extends Equatable {
  const Comment({
    required int this.id,
    required this.postedTime,
    List<int>? children,
    this.parentID,
    this.postedBy = '',
    this.title = '',
  }) : childComments = children ?? const [];

  /// Ycombinator Hacker News comment ID and parent comment Id (if any).
  final int? id, parentID;

  /// Name of the one who posted this (display name).
  final String? postedBy;

  /// The Text of the Comment.
  final String title;

  /// Time of Comment.
  final DateTime postedTime;

  /// List of Comments under this post
  final List<int> childComments;

  /// Empty Comment.
  static final Comment empty = Comment(
    id: 0,
    postedTime: DateTime.now(),
    postedBy: '',
    title: '',
    children: [],
  );

  @override
  List<Object?> get props => [id];
}

/// Post model
///
/// [Post.empty] represents an unauthenticated reservation.
class Post extends Equatable {
  const Post({
    required this.id,
    required this.postedTime,
    required this.url,
    List<int>? comments,
    this.postedBy = '',
    this.title = '',
  })  : comments = comments ?? const [],
        super();

  /// Ycombinator Hacker News post ID.
  final int id;

  /// Name of the one who posted this (display name).
  final String? postedBy;

  /// Url of Full Post.
  final String? url;

  /// The Title of the post.
  final String? title;

  /// Time of Post.
  final DateTime postedTime;

  /// List of Comments under this post
  final List<int> comments;

  /// Empty post.
  static final Post empty = Post(
    id: -9999999, // Corrupted/Empty post identifier
    postedTime: DateTime.now(),
    postedBy: '',
    url: '',
    title: '',
    comments: [],
  );

  @override
  List<Object> get props => [id];

  @override
  String toString() => 'Post ID $id, posted at $postedTime';
}

/// Contains a [post], the number of times it was clicked [clicks], and when it was last clicked [lastClickTime]
class PostData {
  PostData({this.futurePost, this.clicks, this.lastClickTime});

  static PostData empty = PostData(
    futurePost: Future.value(Post.empty),
    clicks: 1,
    lastClickTime: DateTime.now(),
  );

  /// Associated post as a loading Future..
  final Future<Post>? futurePost;

  /// Number of Times Post Clicked.
  final int? clicks;

  /// Last time this Post was Clicked.
  final DateTime? lastClickTime;
}

/// Class Representing Storable Post Data for Hive compatibility.
///
/// properties include [postID], [clicks], [lastClickTime].
@HiveType(typeId: 0)
class StoreablePostData {
  /// Ycombinator Hacker News post ID.
  @HiveField(0)
  final int? postID;

  /// Number of Times Post Clicked.
  @HiveField(1)
  final int? clicks;

  /// Last time this Post was Clicked.
  @HiveField(2)
  final DateTime? lastClickTime;

  const StoreablePostData({
    required this.postID,
    required this.clicks,
    required this.lastClickTime,
  });
}

/// User model
///
/// [User.empty] represents an unauthenticated user.
class User extends Equatable {
  const User({
    this.name,
    required this.email,
    this.id,
    required this.password,
  });

  /// The current user's email address.
  final String email;

  /// The current user's id.
  final String? id;

  /// The current user's name (display name).
  final String? name;

  /// The current user's name (display name).
  final String password;

  /// Empty user which represents an unauthenticated user.
  static const User empty = User(email: '', id: '', password: '', name: null);

  @override
  List<Object?> get props => [email, id, name];
}
