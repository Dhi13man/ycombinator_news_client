import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// For unsupported Operating Systems.
Future<dynamic> initializeDb() async {
  return await Hive.initFlutter();
}
