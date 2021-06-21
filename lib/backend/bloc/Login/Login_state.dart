import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart'
    as data;

abstract class LoginState extends Equatable {
  final List? propss;
  LoginState([this.propss]);

  @override
  List<Object?> get props => (propss ?? []);
}

/// UnInitialized
class UnLoginState extends LoginState {
  UnLoginState();

  @override
  String toString() => 'UnLoginState';
}

class LoadingLoginState extends LoginState {
  final data.User? user;

  LoadingLoginState({this.user}) : super([user]);

  @override
  String toString() => (user == null)
      ? 'Loading Google Account State'
      : 'Loading Account with Email: ${user!.email}';
}

/// Initialized
class SignedOutLoginState extends LoginState {
  SignedOutLoginState() : super([]);

  @override
  String toString() => 'Signed out State';
}

class SignedInLoginState extends LoginState {
  final data.User? user;
  final UserCredential? credential;

  SignedInLoginState({this.user, this.credential}) : super([credential]) {
    if (user == null) _openBoxIfLocalUse();
  }

  void _openBoxIfLocalUse() async =>
      await Hive.openBox<data.StoreablePostData>('clickedPosts');

  @override
  String toString() {
    if (user == data.User(email: 'googleAuth', password: ''))
      return 'Signed in with Google State';
    else if (user != null)
      return 'Signed in State. Email: ${user!.email}';
    else
      return 'Authentication not done!';
  }
}

/// Error
class ErrorLoginState extends LoginState {
  final String errorMessage;

  ErrorLoginState(this.errorMessage) : super([errorMessage]) {
    _closeBoxIfLocalUseEnded();
  }

  @override
  String toString() => 'ErrorLoginState';

  void _closeBoxIfLocalUseEnded() async {
    Box<data.StoreablePostData> box =
        Hive.box<data.StoreablePostData>('clickedPosts');

    if (box.isOpen) box.close();
  }
}
