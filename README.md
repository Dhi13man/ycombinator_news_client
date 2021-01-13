# ycombinator_hacker_news

A Flutter based client application functioning as a Real-Time News Forum, using:

1. [Bloc pattern](https://bloclibrary.dev) architecture and [ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html) for State Management.
2. Both [Local Hive Database](https://pub.dev/packages/hive) and [Cloud Firebase-](https://firebase.google.com/)[Authenticated](https://firebase.google.com/products/auth), [Firestore Database](https://firebase.google.com/products/firestore), as per need.
3. Utilizes [Material Design](https://material.io/develop/flutter) elements for UI building, as well as various other Open Source Packages as [listed below](#dependencies-used).

Acts as a client for [YcCombinator's Hacker News API](https://github.com/HackerNews/API).

Download the Android App [`.apk` directly](https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Output/HackerNews.apk), or compressed version from [Releases Page](https://github.com/Dhi13man/reservation_manager_firebase/releases/tag/0.5.0-android).

## Features

1. Firebase based Google and Email Authentication, also with option to locally.
2. Firestore or Hive based dynamic database for reservations with one tap sorting.
3. Lazy Loading of posts and comments from API for efficiency.
4. Storing user activity and favorite posts.
5. Light and Dark Themes (toggleable by tapping icon)

## Screenshots

Authentication Screen(Light): | Authentication Screen(Dark):
----------------|----------------------------
[<img height="600" width="350" src="https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/LoginScreen_Light.jpg" alt="Authentication Screen(Light)">](https://raw.githubusercontent.com/Dhi13man/SafeSyncIoT/main/Screenshots/LoginScreen_Light.jpg) | [<img height="600" width="350" src="https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/LoginScreen_Dark.jpg" alt="Authentication Screen(Dark)">](https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/LoginScreen_Dark.jpg)

News Feed Screen(Light): | News Feed Screen(Dark):
--------------------------------------|----------------------
[<img height="600" width="350" src="https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/NewsFeed_Light.jpg" alt="News Feed Screen(Light)">](https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/NewsFeed_Light.jpg) | [<img height="600" width="350" src="https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/NewsFeed_Dark.jpg" alt="News Feed Screen(Dark)">](https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/NewsFeed_Dark.jpg)

View Post Screen(Light): | View Post Screen(Dark):
--------------------------------------|----------------------
[<img height="600" width="350" src="https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/ViewPost_Light.jpg" alt="View Post Screen(Light)">](https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/ViewPost_Light.jpg) | [<img height="600" width="350" src="https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/ViewPost_Dark.jpg" alt="View Post Screen(Dark)">](https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/ViewPost_Dark.jpg)

Clicked Posts List Screen(Light): | Clicked Posts List Screen(Dark):
--------------------------------------|----------------------
[<img height="600" width="350" src="https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/ClickedPosts_Light.jpg" alt="Clicked Posts List Screen(Light)">](https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/ClickedPosts_Light.jpg) | [<img height="600" width="350" src="https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/ClickedPosts_Dark.jpg" alt="Clicked Posts List Screen(Dark)">](https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/ClickedPosts_Dark.jpg)

Animated Post URL opening Example:|
------------------------------|
[<img height="600" width="350" src="https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/PostClickDemo.mp4" alt="Animated Post URL opening Example">](https://raw.githubusercontent.com/Dhi13man/reservation_manager_firebase/main/Screenshots/PostClickDemo.mp4) |

---

## Dependencies Used

1. [material](https://material.io/develop/flutter) for UI

2. [cupertino](https://flutter.dev/docs/development/ui/widgets/cupertino) and [cupertino_icons](https://pub.dev/packages/cupertino_icons) for UI

3. [simple_animations](https://pub.dev/packages/simple_animations) for UI animations

4. [page_transition](https://pub.dev/packages/page_transition) for page transition animations

5. [flutter_spinkit](https://pub.dev/packages/flutter_spinkit) for better Animated Loading indicators.

6. [firebase_core](https://pub.dev/packages/firebase_core) and supporting Libraries for Cross Platform Authentication and Database backend
    1. [firebase_auth](https://pub.dev/packages/firebase_auth) for Firebase Authentication System interfacing
    2. [cloud_firestore](https://pub.dev/packages/cloud_firestore) for Firebase Firestore interfacing
    3. [google_sign_in](https://pub.dev/packages/google_sign_in) for Google Sign in using Firebase

7. [hive](https://pub.dev/packages/hive) for local NoSQL Database
   1. [hive_flutter](https://pub.dev/packages/hive_flutter) for initializing Hive when OS not known.
   2. [sqflite](https://pub.dev/packages/sqflite) just for getting default database storage location.
   3. [path_provider](https://pub.dev/packages/path_provider) for getting default database storage location in Desktop systems.

8. [bloc](https://pub.dev/packages/bloc) for better Architecture and State Management
   1. [flutter_bloc](https://pub.dev/packages/flutter_bloc) for interfacing blocs faster and better in Flutter
   2. [equatable](https://pub.dev/packages/equatable) for debugging blocs and proper state tracking

9. [provider](https://pub.dev/packages/provider) for less intensive State Management

10. [flutter_form_builder](https://pub.dev/packages/flutter_form_builder) for easily building forms for Authentication and Database editing front end

11. [flutter_signin_button](https://pub.dev/packages/flutter_signin_button) for a pre-made Google sign-in button

12. [data_connection_checker](https://pub.dev/packages/data_connection_checker) for checking internet connections before making network calls, and throwing appropriate erros if no network

13. [url_launcher](https://pub.dev/packages/url_launcher) for launching URLs associated with posts.

14. [html](https://pub.dev/packages/html) for parsing comments, which are scraped with inline html.
