import 'dart:io';

import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;

import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart';

/// Initialize Hive Database for Mobile Operating Systems.
Future<void> initializeDb() async {
  if (Platform.isIOS || Platform.isAndroid) {
    Directory appDir = await getApplicationDocumentsDirectory();
    String path = appDir.path;
    Hive.init(path);
  } else if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    final documentDirectory = await getDatabasesPath();
    Hive.init(documentDirectory);
  }

  // Register necessary Data Adapter for Hive, if not Registered.
  if (!Hive.isAdapterRegistered(0))
    Hive.registerAdapter<StoreablePostData>(StoreablePostDataAdapter());
  if (!Hive.isBoxOpen('settingsBox')) await Hive.openBox('settingsBox');
  return;
}
