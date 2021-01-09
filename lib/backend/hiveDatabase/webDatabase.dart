import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

Future<void> initializeDb() async {
  Hive.initFlutter();

  // Register necessary Data Adapter for Hive
  Hive.registerAdapter<StoreablePostData>(StoreablePostDataAdapter());
}
