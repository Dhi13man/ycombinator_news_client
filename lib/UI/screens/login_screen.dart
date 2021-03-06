import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

import 'package:ycombinator_hacker_news/backend/bloc/Login/Login_bloc.dart';
import 'package:ycombinator_hacker_news/backend/constants.dart';

import 'package:ycombinator_hacker_news/UI/screens/splash_screen.dart';
import 'package:ycombinator_hacker_news/UI/screens/newsfeed_screen.dart';

/// Contains Sign In, Sign Up, Sign in with Google, Local Sign In and Forgot Password Button.
class LoginButtons extends StatelessWidget {
  const LoginButtons({
    Key? key,
    required AppConstants appConstants,
    required bool? isFormValid,
    required Map<String, TextEditingController> controlmap,
  })  : _isFormValid = isFormValid,
        _controlmap = controlmap,
        _appConstants = appConstants,
        buttonPadding = const EdgeInsets.symmetric(
          horizontal: 35,
          vertical: 18,
        ),
        super(key: key);

  final AppConstants _appConstants;
  final EdgeInsets buttonPadding;
  final bool? _isFormValid;
  final Map<String, TextEditingController> _controlmap;

  Color _buttonForegroundColor(bool isEnabled) =>
      (isEnabled) ? _appConstants.getForeGroundColor : Colors.grey;

  @override
  Widget build(BuildContext context) {
    LoginBloc loginBloc = BlocProvider.of<LoginBloc>(context);

    // Build Button Styles
    final ButtonStyle _buttonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(
        _buttonForegroundColor(_isFormValid!),
      ),
      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(buttonPadding),
    );

    bool isEmailValid = (_controlmap['user'] == null)
        ? false
        : FormBuilderValidators.email(context)(_controlmap['user']!.text) ==
            null;

    return Container(
      margin: EdgeInsets.only(top: 5, bottom: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            alignment: Alignment.bottomRight,
            child: TextButton(
              onPressed: (!isEmailValid)
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          padding:
                              EdgeInsets.symmetric(vertical: 2, horizontal: 15),
                          content:
                              Text('Check Email For Password Reset Link...'),
                        ),
                      );
                      loginBloc.forgotPassword(_controlmap['user']!.text);
                    },
              child: Text(
                'Forgot password',
                style: TextStyle(
                  color: _buttonForegroundColor(isEmailValid),
                  fontSize: 10,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: (!_isFormValid!)
                    ? null
                    : () {
                        loginBloc.signInEmail(
                          email: _controlmap['user']!.text,
                          password: _controlmap['pass']!.text,
                        );
                      },
                style: _buttonStyle,
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: (!_isFormValid!)
                    ? null
                    : () {
                        loginBloc.signUpEmail(
                          email: _controlmap['user']!.text,
                          password: _controlmap['pass']!.text,
                        );
                      },
                style: _buttonStyle,
                child: Text(
                  'Sign up',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          CupertinoButton(
            onPressed: () => loginBloc.signInAnonymous(),
            padding: EdgeInsets.zero,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              padding: EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              color: _buttonForegroundColor(true),
              child: Text(
                'Use Locally without Sign-in',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SignInButton(
            (_appConstants.isThemeLight) ? Buttons.Google : Buttons.GoogleDark,
            onPressed: () => loginBloc.signInGoogle(),
          )
        ],
      ),
    );
  }
}

/// Auto-validated Form allowing user to enter or choose authentication method.
class LoginForm extends StatefulWidget {
  final AppConstants _appConstants;

  const LoginForm({Key? key, required AppConstants appConstants})
      : _appConstants = appConstants,
        super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  GlobalKey<FormState>? _formKey;

  final Map<String, TextEditingController> _controlMap = {
    'user': TextEditingController(),
    'pass': TextEditingController(),
  };
  bool? _validatedForm;

  void _update() {
    setState(() => _validatedForm = _formKey!.currentState!.validate());
  }

  @override
  void initState() {
    _validatedForm = false;
    _formKey = GlobalKey<FormState>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: widget._appConstants.getForeGroundColor),
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      color: widget._appConstants.getForeGroundColor.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15),
      shadowColor: widget._appConstants.getLighterForeGroundColor,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 30),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.always,
          onChanged: _update,
          child: Column(
            children: [
              FormBuilderTextField(
                validator: FormBuilderValidators.compose(
                  [
                    FormBuilderValidators.required(context),
                    FormBuilderValidators.email(context),
                  ],
                ),
                decoration: const InputDecoration(labelText: 'Email Address'),
                controller: _controlMap['user'],
                name: 'user',
              ),
              FormBuilderTextField(
                validator: FormBuilderValidators.compose(
                  [
                    FormBuilderValidators.required(context),
                    FormBuilderValidators.minLength(context, 6),
                  ],
                ),
                decoration: const InputDecoration(labelText: 'Password'),
                controller: _controlMap['pass'],
                name: 'pass',
              ),
              LoginButtons(
                appConstants: widget._appConstants,
                isFormValid: _validatedForm,
                controlmap: _controlMap,
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controlMap.forEach((_, TextEditingController c) => c.dispose());
    super.dispose();
  }
}

/// Allows to login into Firebase based Account, or Local Database facilitated by Hive.
///
/// works with [LoginBloc], facilitating Firebase.
class LoginScreen extends StatelessWidget {
  final String _title;

  static const routeName = '/login';
  LoginScreen({Key? key, String? title})
      : _title = title ?? 'App Title',
        super(key: key);

  @override
  Widget build(BuildContext context) {
    AppConstants _appConstants = context.watch<AppConstants>();

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoadingLoginState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(days: 30),
              padding: const EdgeInsets.all(2),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text('Attempting to Log you in...'),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        if (state is SignedInLoginState) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          Navigator.pushReplacementNamed(
            context,
            NewsFeedScreen.routeName,
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
        } else if (state is ErrorLoginState) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ErrorLoginState errorState = state;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Center(child: Text('Sign in Error')),
              content: Text('${errorState.errorMessage}'),
            ),
          );
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
        }
      },
      child: Scaffold(
        backgroundColor: _appConstants.getBackGroundColor,
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AppHeroIcon(appConstants: _appConstants, iconSize: 150.0),
                Container(
                  margin: const EdgeInsets.all(20),
                  child: Text(
                    _title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _appConstants.getForeGroundColor,
                      fontSize: 30,
                    ),
                  ),
                ),
                LoginForm(appConstants: _appConstants),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
