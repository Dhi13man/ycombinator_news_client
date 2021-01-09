import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

class PostDataHiveDatabaseHandler {
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

  static Future<void> deletePostData({@required int postID}) async {
    // Make sure valid Data
    assert(postID != null);

    Box<StoreablePostData> box =
        await Hive.openBox<StoreablePostData>('clickedPosts');
    await box.delete(postID);
    if (box.isOpen) box.close();
  }

  static Stream<List<StoreablePostData>> watchPostDataFromBox() async* {
    Box<StoreablePostData> box =
        await Hive.openBox<StoreablePostData>('clickedPosts');
    List<StoreablePostData> out = [];

    box.watch().map(
      (_) async* {
        out = box.values;
        yield out;
      },
    );

    yield out;
  }

  static Future<Map<int, StoreablePostData>> getPostDataFromBox() async {
    Box<StoreablePostData> box =
        await Hive.openBox<StoreablePostData>('clickedPosts');
    return box.toMap();
  }
}
