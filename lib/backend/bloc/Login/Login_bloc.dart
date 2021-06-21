import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ycombinator_hacker_news/backend/bloc/Login/Login_state.dart';
import 'package:ycombinator_hacker_news/backend/repos/authentication.dart';
import 'package:ycombinator_hacker_news/backend/repos/data_classes.dart'
    as data;

export 'package:ycombinator_hacker_news/backend/bloc/Login/Login_state.dart';

class LoginBloc extends Cubit<LoginState> {
  final AuthenticationRepository _authenticationRepository;

  LoginBloc({
    required AuthenticationRepository authenticationRepository,
  })  : _authenticationRepository = authenticationRepository,
        super(UnLoginState());

  /// Anonymous Login without Firebase account.
  void signInAnonymous() => emit(SignedInLoginState());

  /// Signs in with the provided [email] and [password].
  void signInEmail({
    required String email,
    required String password,
  }) async {
    try {
      data.User _user = data.User(email: email, password: password);
      emit(LoadingLoginState(user: _user));
      UserCredential cred =
          await _authenticationRepository.logInWithEmailAndPassword(
        email: email,
        password: password,
      );
      emit(SignedInLoginState(user: _user, credential: cred));
    } catch (e) {
      if (e is LogInWithEmailAndPasswordFailure)
        emit(ErrorLoginState('Check Credentials and Network Connection.'));
      else
        emit(ErrorLoginState(e.toString()));
    }
  }

  /// Starts the Sign In with Google Flow.
  void signInGoogle() async {
    try {
      emit(LoadingLoginState());
      UserCredential cred = await _authenticationRepository.logInWithGoogle();
      emit(
        SignedInLoginState(
            user: data.User(email: 'googleAuth', password: ''),
            credential: cred),
      );
    } catch (e) {
      if (e is LogInWithGoogleFailure)
        emit(ErrorLoginState(
          'Error while interfacing Google. Check Network Connection.',
        ));
      else
        emit(ErrorLoginState('Sign-in Process was not completed!'));
    }
  }

  /// Creates a new user with the provided [email] and [password].
  void signUpEmail({
    required String email,
    required String password,
  }) async {
    try {
      data.User _user = data.User(email: email, password: password);
      emit(LoadingLoginState(user: _user));
      UserCredential cred = await _authenticationRepository.signUp(
        email: email,
        password: password,
      );
      emit(SignedInLoginState(user: _user, credential: cred));
    } catch (e) {
      if (e is SignUpFailure)
        emit(ErrorLoginState(
          'Try Different Credentials and check Network Connection.',
        ));
      else if (e is LogInWithEmailAndPasswordFailure)
        emit(ErrorLoginState('Check Credentials.'));
      else
        emit(ErrorLoginState(e.toString()));
    }
  }

  /// Emits a [SignedOutLoginState], which efficiently signs user out.
  void signOut() async {
    await _authenticationRepository.logOut();
    emit(SignedOutLoginState());
  }

  /// Allows User to Reset password for entered [email],
  /// using Firebase's Password Recovery Email system.
  void forgotPassword(String email) async {
    try {
      await _authenticationRepository.forgotPassword(email);
    } catch (e) {
      emit(
        ErrorLoginState('Check Network Connection and if Email is Registered!'),
      );
    }
  }
}
