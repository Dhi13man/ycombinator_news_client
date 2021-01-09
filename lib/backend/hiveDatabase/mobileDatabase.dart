import 'dart:io';

import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as paths;

import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

Future<void> initializeDb() async {
  if (Platform.isIOS || Platform.isAndroid) {
    final documentDirectory = await paths.getApplicationDocumentsDirectory();
    Hive.init(documentDirectory.path);
  } else if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    final documentDirectory = await getDatabasesPath();
    Hive.init(documentDirectory);
  }

  // Register necessary Data Adapter for Hive
  Hive.registerAdapter<StoreablePostData>(StoreablePostDataAdapter());
}
