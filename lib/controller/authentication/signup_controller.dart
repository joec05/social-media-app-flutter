import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SignUpController {
  BuildContext context;
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

  SignUpController(
    this.context
  );

  bool get mounted => context.mounted;

  void initializeController(){
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

  void dispose(){
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
  
  Future<void> selectBirthDate(BuildContext context) async {
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
      
    }
  }

}