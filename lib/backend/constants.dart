import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:provider/provider.dart';

class AppConstants extends ChangeNotifier {
  bool _isThemeLight = false;

  AppConstants() {
    _findTheme();
  }

  // Getters
  // Theme Data
  bool get isThemeLight => _isThemeLight;

  MaterialColor get getForeGroundColor =>
      (_isThemeLight) ? Colors.indigo : Colors.amber;

  MaterialColor get getLighterForeGroundColor =>
      (_isThemeLight) ? Colors.blue : Colors.yellow;

  Color get getLighterBackGroundColor =>
      (_isThemeLight) ? Colors.indigo[900] : Colors.grey[800];

  Color get getBackGroundColor => (_isThemeLight) ? Colors.white : Colors.black;

  // Styles
  TextStyle get textStyleListItem => TextStyle(
        color: getForeGroundColor,
        fontWeight: FontWeight.w500,
      );

  TextStyle get textStyleSubListItem => TextStyle(
        color: getForeGroundColor,
        fontSize: 10,
      );

  TextStyle get textStyleAppBarTitle => TextStyle(
        color: getBackGroundColor,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      );

  TextStyle get textStyleAppBarSubTitle => TextStyle(
        color: getBackGroundColor,
        fontSize: 12,
      );

  TextStyle get textStyleBodyMessage => TextStyle(
        fontSize: 18,
        color: getForeGroundColor,
      );

  /// Other Functions
  void _findTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isThemeLight = prefs.getBool('isThemeLight') ?? false;

    await prefs.setBool('isThemeLight', _isThemeLight);
    notifyListeners();
  }

  void toggleTheme() async {
    _isThemeLight = !_isThemeLight;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isThemeLight', _isThemeLight);
  }
}
