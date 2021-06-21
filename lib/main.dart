import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:page_transition/page_transition.dart';

import 'package:ycombinator_hacker_news/backend/hiveDatabase/shared.dart';
import 'package:ycombinator_hacker_news/backend/bloc/Data/Data_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/Login/Login_bloc.dart';
import 'package:ycombinator_hacker_news/backend/bloc/NewsAPI/NewsAPI_bloc.dart';
import 'package:ycombinator_hacker_news/backend/constants.dart';
import 'package:ycombinator_hacker_news/backend/repos/authentication.dart';

import 'package:ycombinator_hacker_news/UI/screens/clicked_newsfeed_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/splash_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/login_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/newsfeed_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/view_post_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDb();

  // Run app only after mandatory dependencies initialized.
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  final String _appTitle = 'Hacker News';

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Spreading the Business Logic and States throughout the widget tree.
      providers: [
        ChangeNotifierProvider<AppConstants>(
          create: (context) => AppConstants(),
        ),
        // Three BLoCs for Login, News API and Data respectively.
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

      /// Material App that wraps every UI component of this project.
      child: MaterialApp(
        title: _appTitle,
        theme: ThemeData(primarySwatch: Colors.blue),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: (settings) {
          // Setting up App routes and Transitions.
          // Builders are provided so state can be extracted from context and re-spread through the branches.
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
                duration: const Duration(milliseconds: 500),
                settings: settings,
              );

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
                childCurrent: ClickedNewsFeedScreen(),
                reverseDuration: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 500),
                settings: settings,
              );

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
                      child: const ClickedNewsFeedScreen(),
                    );
                  },
                ),
                type: PageTransitionType.rightToLeftWithFade,
                reverseDuration: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 500),
                settings: settings,
              );

            case ViewPostScreen.routeName:
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
                      child: const ViewPostScreen(),
                    );
                  },
                ),
                type: PageTransitionType.scale,
                alignment: Alignment.center,
                childCurrent: ClickedNewsFeedScreen(),
                reverseDuration: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 500),
                settings: settings,
              );

            default:
              return null;
          }
        },
      ),
    );
  }
}
