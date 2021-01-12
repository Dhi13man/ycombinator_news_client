import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

/// Utility class having Static Functions for facilitating Hive Database.
class PostDataHiveDatabaseHandler {
  /// Write [postData] to Database.
  static Future<void> writeToDB({
    @required int postID,
    @required PostData postData,
  }) async {
    // Make sure valid Data
    assert(postData != null);
    assert(postID != null);

    Box<StoreablePostData> box =
        await Hive.openBox<StoreablePostData>('clickedPosts');
    StoreablePostData temp = StoreablePostData(
      clicks: postData.clicks,
      lastClickTime: postData.lastClickTime,
      postID: postID,
    );
    await box.put(postID, temp);
    if (box.isOpen) box.close();
  }

  /// Delete [postData] from Database.
  static Future<void> deletePostData({@required int postID}) async {
    // Make sure it is valid Data
    assert(postID != null);

    Box<StoreablePostData> box =
        await Hive.openBox<StoreablePostData>('clickedPosts');
    await box.delete(postID);
    if (box.isOpen) box.close();
  }

  /// Remove all [PostData] items from Database.
  static Future<int> clearBox() async {
    Box<StoreablePostData> box =
        await Hive.openBox<StoreablePostData>('clickedPosts');
    int out = await box.clear();
    box.close();
    return out;
  }

  /// Stream all [postData] in real time from Database.
  static Stream<List<StoreablePostData>> watchPostDataFromBox() async* {
    Box<StoreablePostData> box =
        await Hive.openBox<StoreablePostData>('clickedPosts');

    yield* box.watch().map((e) {
      return box.values.toList();
    });
  }

  /// Get all [postData] from Database.
  static Future<Map<dynamic, StoreablePostData>> getPostDataFromBox() async {
    Box<StoreablePostData> box =
        await Hive.openBox<StoreablePostData>('clickedPosts');
    return box.toMap();
  }
}
