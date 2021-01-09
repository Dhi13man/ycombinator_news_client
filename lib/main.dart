import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:page_transition/page_transition.dart';

import 'package:ycombinator_hacker_news/backend/bloc/Data/Data_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/Login/Login_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/NewsAPI/NewsAPI_bloc.dart';
import 'package:ycombinator_hacker_news/backend/constants.dart';
import 'package:ycombinator_hacker_news/backend/repos/authentication.dart';

import 'package:ycombinator_hacker_news/UI/screens/clicked_newsfeed_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/splash_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/login_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/newsfeed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConstants _appConstants = AppConstants();
  runApp(
    ChangeNotifierProvider<AppConstants>.value(
      value: _appConstants,
      builder: (context, child) => ReservationApp(),
    ),
  );
}

class ReservationApp extends StatelessWidget {
  final String _appTitle = 'Hacker News';

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(
            authenticationRepository: AuthenticationRepository(),
          ),
        ),
        BlocProvider<NewsAPIBloc>(
          create: (context) => NewsAPIBloc(UnNewsAPIState()),
        ),
        BlocProvider<DataBloc>(
          create: (context) => DataBloc(
            initialState: UnDataState(),
            loginBloc: BlocProvider.of<LoginBloc>(context),
            newsAPIBloc: BlocProvider.of<NewsAPIBloc>(context),
          ),
        ),
      ],
      child: MaterialApp(
        title: _appTitle,
        theme: ThemeData(primarySwatch: Colors.blue),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case SplashScreen.routeName:
              return PageTransition(
                child: Builder(
                  builder: (context) =>
                      ChangeNotifierProvider<AppConstants>.value(
                    value: context.watch<AppConstants>(),
                    child: SplashScreen(),
                  ),
                ),
                type: PageTransitionType.fade,
                settings: settings,
              );
              break;

            case LoginScreen.routeName:
              return PageTransition(
                child: Builder(
                  builder: (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider<AppConstants>.value(
                        value: context.watch<AppConstants>(),
                      ),
                      BlocProvider<LoginBloc>.value(
                        value: context.watch<LoginBloc>(),
                      )
                    ],
                    child: LoginScreen(title: _appTitle),
                  ),
                ),
                type: PageTransitionType.fade,
                duration: Duration(seconds: 1),
                settings: settings,
              );
              break;

            case ClickedNewsFeedScreen.routeName:
              return PageTransition(
                child: Builder(
                  builder: (context) {
                    return MultiProvider(
                      providers: [
                        ChangeNotifierProvider<AppConstants>.value(
                          value: context.watch<AppConstants>(),
                        ),
                        BlocProvider<DataBloc>.value(
                          value: context.watch<DataBloc>(),
                        )
                      ],
                      child: ClickedNewsFeedScreen(),
                    );
                  },
                ),
                type: PageTransitionType.bottomToTop,
                duration: Duration(milliseconds: 500),
                settings: settings,
              );
              break;

            case NewsFeedScreen.routeName:
              return PageTransition(
                child: Builder(
                  builder: (context) {
                    return MultiProvider(
                      providers: [
                        ChangeNotifierProvider<AppConstants>.value(
                          value: context.watch<AppConstants>(),
                        ),
                        BlocProvider<DataBloc>.value(
                          value: context.watch<DataBloc>(),
                        ),
                        BlocProvider<NewsAPIBloc>.value(
                          value: context.watch<NewsAPIBloc>(),
                        )
                      ],
                      child: NewsFeedScreen(),
                    );
                  },
                ),
                type: PageTransitionType.rightToLeftWithFade,
                settings: settings,
              );
              break;

            default:
              return null;
          }
        },
      ),
    );
  }
}
