import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:ycombinator_hacker_news/backend/constants.dart';
import 'package:ycombinator_hacker_news/backend/hiveDatabase/shared.dart';

import 'package:ycombinator_hacker_news/UI/screens/login_screen.dart';

/// Used all over the UI. Can be tapped to toggle theme between Light to Dark.
class AppHeroIcon extends StatelessWidget {
  const AppHeroIcon({
    Key key,
    num iconSize,
    EdgeInsets margin,
    EdgeInsets padding,
    this.backgroundColor,
    this.foregroundColor,
    @required AppConstants appConstants,
  })  : _appConstants = appConstants,
        _size = iconSize ?? 170.0,
        _margin = margin ?? const EdgeInsets.all(20),
        _padding = padding ?? const EdgeInsets.all(50),
        super(key: key);

  final AppConstants _appConstants;
  final EdgeInsets _margin, _padding;
  final num _size;
  final Color backgroundColor, foregroundColor;

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: () => _appConstants.toggleTheme(),
      child: Tooltip(
        message: 'Toggle Theme',
        child: Hero(
          tag: 'icon',
          transitionOnUserGestures: true,
          child: Container(
            margin: _margin,
            padding: _padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: (backgroundColor) ??
                  _appConstants.getLighterForeGroundColor.withOpacity(0.1),
            ),
            child: Icon(
              CupertinoIcons.news,
              size: _size.toDouble(),
              color: (foregroundColor) ??
                  _appConstants.getForeGroundColor.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown while Firebase and Hive Initializes.
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key key}) : super(key: key);

  static const routeName = '/';
  @override
  Widget build(BuildContext context) {
    AppConstants _appConstants = context.watch<AppConstants>();
    Future.wait(
      [
        Firebase.initializeApp(),
        initializeDb(), // For Local Hive Database Working
      ],
    ).then(
      (_) => Navigator.pushReplacementNamed(context, LoginScreen.routeName),
    );

    return Scaffold(
      backgroundColor: _appConstants.getBackGroundColor,
      body: Center(
        child: AppHeroIcon(appConstants: _appConstants),
      ),
    );
  }
}
