import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

/// Controller which is used when the user wants to sign up
class SignUpController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// True if an API/Firebase/AppWrite function is running
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  /// An editing controller for the user to insert a name
  TextEditingController nameController = TextEditingController();

  /// An editing controller for the user to insert a username
  TextEditingController usernameController = TextEditingController();

  /// An editing controller for the user to insert an email
  TextEditingController emailController = TextEditingController();

  /// An editing controller for the user to insert a password
  TextEditingController passwordController = TextEditingController();

  /// An editing controller for the user to select and display the birth date
  TextEditingController birthDateController = TextEditingController();

  /// Selected birth date in DateTime format
  DateTime selectedBirthDate = DateTime.now();

  /// True if the name is in acceptable format
  ValueNotifier<bool> verifyNameFormat = ValueNotifier(false);

  /// True if the username is in acceptable format
  ValueNotifier<bool> verifyUsernameFormat = ValueNotifier(false);

  /// True if the email is in acceptable format
  ValueNotifier<bool> verifyEmailFormat = ValueNotifier(false);

  /// True if the password is in acceptable format
  ValueNotifier<bool> verifyPasswordFormat = ValueNotifier(false);

  /// True if the birth date is in acceptable format
  ValueNotifier<bool> verifyBirthDateFormat = ValueNotifier(false);

  /// Maximum length of a name
  final int nameCharacterMaxLimit = profileInputMaxLimit['name'];

  /// Minimum length of a username
  final int usernameCharacterMinLimit = profileInputMinLimit['username'];
  
  /// Minimum length of a password
  final int passwordCharacterMinLimit = profileInputMinLimit['password'];

  /// Maximum length of a username
  final int usernameCharacterMaxLimit = profileInputMaxLimit['username'];

  /// Maximum length of a password
  final int passwordCharacterMaxLimit = profileInputMaxLimit['password'];

  SignUpController(
    this.context
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
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

  /// Dispose everything. Called at every page's dispose function
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
  
  /// Called when the user pressed on the TextField of the birth date controller
  Future<void> selectBirthDate(BuildContext context) async {

    /// Display a DatePicker
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthDate,
      firstDate: DateTime(1945, 1, 1),
      lastDate: DateTime.now(),
    );

    if (picked! != selectedBirthDate){

      /// Update the variables once the user selected a date
      selectedBirthDate = picked;
      int day = picked.day;
      int month = picked.month;
      int year = picked.year;
      birthDateController.text = '$day/$month/$year';

    }
  }

  /// Called when the user signs up
  Future<dynamic> checkAccountExistsSignUp() async{

    /// Call the API to check if the email or username inserted has been used before by an active account
    dynamic res = await fetchDataRepo.fetchData(
      context, 
      RequestGet.checkAccountExistsSignUp, 
      {
        'email': emailController.text.trim(),
        'username': usernameController.text.trim(),
      }
    );

    return res;
  }

  /// Called when the user pressed the given button
  void signUp() async{
    if(mounted){
      if(!isLoading.value){
        
        /// Check if the username format is valid or not
        if(checkUsernameValid(usernameController.text.trim()) == false){
          handler.displaySnackbar(
            context,
            SnackbarType.error,
            'The username is invalid'
          );
        }else{  
          try {

            /// Check whether the username or email has been used previously by an active account
            var verifyAccountExistence = await checkAccountExistsSignUp();
            if(verifyAccountExistence != null && mounted){
              if(verifyAccountExistence['exists']){

                /// Display a snackbar error if the email or username has been previously used
                handler.displaySnackbar(
                  context,
                  SnackbarType.error,
                  'Email or username has already been used'
                );

              }else{
                if(mounted){
                  isLoading.value = true;

                  /// Call the authentication repository to sign the user up to FirebaseAuth with email and password
                  await authRepo.createUserWithEmailAndPassword(
                    context, 
                    emailController.text.trim(), 
                    passwordController.text.trim()
                  ).then((value) async{
                    User? user = authRepo.currentUser.value;
                    if(user != null){

                      /// Call the API to sign the user up
                      dynamic res = await fetchDataRepo.fetchData(
                        context, 
                        RequestPost.signUp, 
                        {
                          'userId': user.uid,
                          'name': nameController.text.trim(),
                          'username': usernameController.text.trim(),
                          'profilePicLink': defaultUserProfilePicLink,
                          'email': emailController.text.trim(),
                          'password': passwordController.text.trim(),
                          'birthDate': selectedBirthDate.toString()
                        }
                      );

                      if(mounted) {
                        isLoading.value = false;
                        if(res != null) {

                          /// Once the user account has been created in the Firebase and API, verify the user's email address
                          var verified = await Navigator.push(
                            context,
                            SliderRightToLeftRoute(
                              page: const EmailVerificationPage()
                            )
                          );

                          /// User successfully verified
                          if(verified == true && mounted){

                            /// Start updating the current id, user data, and user socials at the app state repository
                            appStateRepo.currentID = res['userID'];
                            UserDataClass userDataClass = UserDataClass(
                              res['userID'], nameController.text.trim(), usernameController.text.trim(), defaultUserProfilePicLink,
                              DateTime.now().toString(), selectedBirthDate.toString(), '',  false, false, false, false,
                              false, false, false, false, false
                            );
                            UserSocialClass userSocialClass = UserSocialClass(
                              0, 0, false, false
                            );
                            updateUserData(userDataClass);
                            updateUserSocials(userDataClass, userSocialClass);

                            /// Store the current lifecycle state of the app in a secured storage
                            secureStorageController.writeUserState(
                              AppLifecycleState.resumed.name, 
                              DateTime.now().toIso8601String()
                            );

                            /// Navigate to main page
                            runDelay(() => Navigator.push(
                              context,
                              SliderRightToLeftRoute(
                                page: const CompleteSignUpProfileStateless()
                              )
                            ), navigatorDelayTime);

                          }
                        }
                      }
                    }
                  });
                }
              }
            }
          } on FirebaseAuthException catch (e) {
            if(mounted){
              isLoading.value = false;

              /// Display a snackbar error based on the FirebaseAuthException's error info
              if (e.code == 'weak-password') {
                handler.displaySnackbar(
                  context, 
                  SnackbarType.error, 
                  'The password is too weak'
                );
              } else if (e.code == 'email-already-in-use') {
                handler.displaySnackbar(
                  context, 
                  SnackbarType.error, 
                  'The email has already been used'
                );
              }else if (e.code == 'invalid-email') {
                handler.displaySnackbar(
                  context, 
                  SnackbarType.error, 
                  'Invalid email format'
                );
              }
              
            }
            return null;
          } catch (e) {
            debugPrint(e.toString());
            return null;
          }
        }
      }
    }
  }
}