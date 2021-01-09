import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:provider/provider.dart';

class AppConstants extends ChangeNotifier {
  bool _isThemeLight = true;

  AppConstants() {
    findTheme();
  }

  // Getters
  // Theme Data
  bool get isThemeLight => _isThemeLight;

  MaterialColor get getForeGroundColor =>
      (_isThemeLight) ? Colors.indigo : Colors.amber;

  Color get getLighterForeGroundColor =>
      (_isThemeLight) ? Colors.blue : Color.fromARGB(0, 252, 163, 17);

  Color get getLighterBackGroundColor =>
      (_isThemeLight) ? Color.fromRGBO(20, 33, 61, 1) : Colors.indigo[900];

  Color get getBackGroundColor => (_isThemeLight) ? Colors.white : Colors.black;

  // Styles
  TextStyle get listItemTextStyle => TextStyle(
        color: getForeGroundColor,
        fontWeight: FontWeight.w500,
      );

  TextStyle get listItemSubTextStyle => TextStyle(
        color: getForeGroundColor,
        fontSize: 10,
      );

  TextStyle get appBarTitleTextStyle => TextStyle(color: getBackGroundColor);

  TextStyle get appBarSubTitleTextStyle => TextStyle(
        color: getBackGroundColor,
        fontSize: 12,
      );

  /// Other Functions
  void findTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isThemeLight = prefs.getBool('isThemeLight') ?? true;

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
