import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/complete_sign_up_profile.dart';
import 'package:social_media_app/email_verification.dart';
import 'package:social_media_app/appdata/global_library.dart';
import 'package:social_media_app/class/shared_preferences_class.dart';
import 'package:social_media_app/class/user_data_class.dart';
import 'package:social_media_app/class/user_social_class.dart';
import 'package:social_media_app/custom/custom_button.dart';
import 'package:social_media_app/firebase/firebase_constants.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/transition/right_to_left_transition.dart';
import 'styles/app_styles.dart';

var dio = Dio();

class SignUpStateless extends StatelessWidget {
  const SignUpStateless({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignUpStateful();
  }
}

class SignUpStateful extends StatefulWidget {
  const SignUpStateful({super.key});

  @override
  State<SignUpStateful> createState() => _SignUpStatefulState();
}

class _SignUpStatefulState extends State<SignUpStateful> {
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  DateTime selectedBirthDate = DateTime.now();
  ValueNotifier<bool> verifyNameFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyUsernameFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyEmailFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyPasswordFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyBirthDateFormat = ValueNotifier(false);
  final int nameCharacterMaxLimit = profileInputMaxLimit['name'];
  final int usernameCharacterMinLimit = profileInputMinLimit['username'];
  final int passwordCharacterMinLimit = profileInputMinLimit['password'];
  final int usernameCharacterMaxLimit = profileInputMaxLimit['username'];
  final int passwordCharacterMaxLimit = profileInputMaxLimit['password'];

  @override
  void initState(){
    super.initState();
    nameController.addListener(() {
      if(mounted){
        String nameText = nameController.text;
        verifyNameFormat.value = nameText.isNotEmpty && nameText.length <= nameCharacterMaxLimit;
      }
    });
    usernameController.addListener(() {
      if(mounted){
        String usernameText = usernameController.text;
        verifyUsernameFormat.value = usernameText.isNotEmpty && checkUsernameValid(usernameText) &&
        usernameText.length >= usernameCharacterMinLimit && usernameText.length <= usernameCharacterMaxLimit;
      }
    });
    emailController.addListener(() {
      if(mounted){
        String emailText = emailController.text;
        verifyEmailFormat.value = emailText.isNotEmpty && checkEmailValid(emailText);
      }
    });
    passwordController.addListener(() {
      if(mounted){
        String passwordText = passwordController.text;
        verifyPasswordFormat.value = passwordText.isNotEmpty && passwordText.length >= passwordCharacterMinLimit
        && passwordText.length <= passwordCharacterMaxLimit;
      }
    });
    birthDateController.addListener(() {
      if(mounted){
        String birthDateText = birthDateController.text;
        verifyBirthDateFormat.value = birthDateText.isNotEmpty;
      }
    });
  }

  @override void dispose(){
    super.dispose();
    isLoading.dispose();
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    birthDateController.dispose();
    verifyNameFormat.dispose();
    verifyUsernameFormat.dispose();
    verifyEmailFormat.dispose();
    verifyPasswordFormat.dispose();
    verifyBirthDateFormat.dispose();
  }
  
  Future<void> _selectBirthDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedBirthDate,
        firstDate: DateTime(1945, 1, 1),
        lastDate: DateTime.now(),
      );
      if (picked! != selectedBirthDate){
        selectedBirthDate = picked;
        int day = picked.day;
        int month = picked.month;
        int year = picked.year;
        birthDateController.text = '$day/$month/$year';
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  void displayAlertDialog(String title, List<String> actionText){
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert!!!', style: TextStyle(fontSize: defaultTextFontSize)),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(title, style: TextStyle(fontSize: defaultTextFontSize)),
              ],
            ),
          ),
          actions: <Widget>[
            for(int i = 0; i < actionText.length; i++)
            TextButton(
              child: Text(actionText[i], style: TextStyle(fontSize: defaultTextFontSize)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> checkAccountExistsSignUp() async{
    String stringified = jsonEncode({
      'email': emailController.text.trim(),
      'username': usernameController.text.trim(),
    });
    var res = await dio.get('$serverDomainAddress/users/checkAccountExistsSignUp', data: stringified);
    return res.data;
  }

  void signUp() async{
    try {
      if(!isLoading.value){
        if(checkUsernameValid(usernameController.text.trim()) == false){
          displayAlertDialog('The username is invalid', ['Ok']);
        }else{  
          try {
            var verifyAccountExistence = await checkAccountExistsSignUp();
            if(verifyAccountExistence['message'] == 'Successfully checked account existence'){
              if(verifyAccountExistence['exists']){
                displayAlertDialog('Email or username has already been used', ['Ok']);
              }else{
                await auth.createUserWithEmailAndPassword(
                  email: emailController.text, password: passwordController.text
                ).then((value) async{
                  var verified = await Navigator.push(
                    context,
                    SliderRightToLeftRoute(
                      page: const EmailVerificationPage()
                    )
                  );
                  if(verified == true){
                    String stringified = jsonEncode({
                      'name': nameController.text.trim(),
                      'username': usernameController.text.trim(),
                      'profilePicLink': defaultUserProfilePicLink,
                      'email': emailController.text.trim(),
                      'password': passwordController.text.trim(),
                      'birthDate': selectedBirthDate.toString()
                    });
                    if(mounted){
                      isLoading.value = true;
                    }
                    var res = await dio.post('$serverDomainAddress/users/signUp', data: stringified);
                    if(res.data.isNotEmpty){
                      if(res.data['message'] == 'Successfully signed up'){
                        appStateClass.currentID = res.data['userID'];
                        UserDataClass userDataClass = UserDataClass(
                          res.data['userID'], nameController.text.trim(), usernameController.text.trim(), defaultUserProfilePicLink,
                          DateTime.now().toString(), selectedBirthDate.toString(), '',  false, false, false, false,
                          false, false, false, false, false
                        );
                        UserSocialClass userSocialClass = UserSocialClass(
                          0, 0, false, false
                        );
                        if(mounted){
                          updateUserData(userDataClass);
                          updateUserSocials(userDataClass, userSocialClass);
                        }
                        SharedPreferencesClass().updateCurrentUser(res.data['userID'], AppLifecycleState.resumed);
                        runDelay(() => Navigator.push(
                          context,
                          SliderRightToLeftRoute(
                            page: const CompleteSignUpProfileStateless()
                          )
                        ), navigatorDelayTime);
                      }else{
                        displayAlertDialog(res.data['message'], ['Ok']);
                      }
                      if(mounted){
                        isLoading.value = false;
                      }
                    }
                  }
                });
              }
            }
          } on FirebaseAuthException catch (e) {
            if (e.code == 'weak-password') {
              displayAlertDialog('The password is too weak', ['Ok']);
            } else if (e.code == 'email-already-in-use') {
              displayAlertDialog('The email has already been used', ['Ok']);
            }else if (e.code == 'invalid-email') {
              displayAlertDialog('Invalid email format', ['Ok']);
            }
            return null;
          } catch (e) {
            debugPrint(e.toString());
            return null;
          }
        }
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Sign Up'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: defaultFrontPageDecoration,
          child: Stack(
            children: [
              Positioned(
                      left: -getScreenWidth() * 0.45,
                      top: -getScreenWidth() * 0.25,
                      child: Container(
                        width: getScreenWidth(),
                        height: getScreenWidth(),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(200),
                          color: Colors.amber.withOpacity(0.65)
                        ),
                      ),
                    ),
              Positioned(
                right: -getScreenWidth() * 0.55,
                top: getScreenWidth() * 0.85,
                child: Container(
                  width: getScreenWidth(),
                  height: getScreenWidth(),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
                    color: Colors.blue.withOpacity(0.8)
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding),
                child: ListView(
                  children: <Widget>[
                    SizedBox(
                      height: titleToContentMargin,
                    ),
                    containerMargin(
                      textFieldWithDescription(
                        TextField(
                          controller: emailController,
                          decoration: generateProfileTextFieldDecoration('your email', Icons.mail),
                        ),
                        'Email',
                        ''
                      ),
                      EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                    ),
                    containerMargin(
                      textFieldWithDescription(
                        TextField(
                          controller: passwordController,
                          decoration: generateProfileTextFieldDecoration('password', Icons.lock),
                          keyboardType: TextInputType.visiblePassword,
                          maxLength: passwordCharacterMaxLimit
                        ),
                        'Password',
                        "Your password should be between $passwordCharacterMinLimit and $passwordCharacterMaxLimit characters",
                      ),
                      EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                    ),
                    containerMargin(
                      textFieldWithDescription(
                        TextField(
                          controller: nameController,
                          decoration: generateProfileTextFieldDecoration('your name', Icons.person),
                          maxLength: nameCharacterMaxLimit,
                        ),
                        'Name',
                        "Your name should be between 1 and $nameCharacterMaxLimit characters",
                      ), EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)),
                    containerMargin(
                      textFieldWithDescription(
                          TextField(
                          controller: usernameController,
                          decoration: generateProfileTextFieldDecoration('username', Icons.person),
                          maxLength: usernameCharacterMaxLimit
                        ),
                        'Username',
                        "Your username should be between $usernameCharacterMinLimit and $usernameCharacterMaxLimit characters",
                      ),
                      EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                    ),
                    containerMargin(
                      textFieldWithDescription(
                        GestureDetector(
                          onTap: () => _selectBirthDate(context),
                          child: TextField(
                            controller: birthDateController,
                            decoration: generateProfileTextFieldDecoration('birth date', Icons.cake),
                            enabled: false,
                          ),
                        ),
                        'Birth Date',
                        ''
                      ),
                      EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                    ),
                    SizedBox(
                      height: textFieldToButtonMargin
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: verifyNameFormat,
                          builder: (context, nameVerified, child) {
                            return ValueListenableBuilder(
                              valueListenable: verifyUsernameFormat,
                              builder: (context, usernameVerified, child) {
                                return ValueListenableBuilder(
                                  valueListenable: verifyEmailFormat,
                                  builder: (context, emailVerified, child) {
                                    return ValueListenableBuilder(
                                      valueListenable: verifyPasswordFormat,
                                      builder: (context, passwordVerified, child) {
                                        return ValueListenableBuilder(
                                          valueListenable: verifyBirthDateFormat,
                                          builder: (context, birthDateVerified, child) {
                                            return ValueListenableBuilder(
                                              valueListenable: isLoading,
                                              builder: (context, isLoadingValue, child) {
                                                return CustomButton(
                                                  width: defaultTextFieldButtonSize.width, height: defaultTextFieldButtonSize.height,
                                                  buttonColor: nameVerified && usernameVerified && emailVerified 
                                                  && passwordVerified && birthDateVerified && !isLoadingValue ? Colors.red : Colors.grey, 
                                                  buttonText: 'Sign Up', 
                                                  onTapped: nameVerified && usernameVerified && emailVerified 
                                                  && passwordVerified && birthDateVerified && !isLoadingValue ? signUp : () {},
                                                  setBorderRadius: true,
                                                );
                                              }
                                            );
                                          }
                                        );
                                      }
                                    );
                                  }
                                );
                              }
                            );
                          }
                        )
                      ]
                    ),
                    SizedBox(
                      height: defaultVerticalPadding
                    )
                  ],
                ),
              ),
              ValueListenableBuilder(
                valueListenable: isLoading,
                builder: (context, isLoadingValue, child) {
                  return isLoadingValue ?
                    loadingPageWidget()
                  : Container();
                } 
              ),
            ]
          ),
        )
      ),
    );
  }
}
