import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

class EditUserProfileController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// True if an API/Firebase/AppWrite function is running
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  /// Editing controller for name
  TextEditingController nameController = TextEditingController();

  /// Editing controller for username
  TextEditingController usernameController = TextEditingController();

  /// Editing controller for birth date
  TextEditingController birthDateController = TextEditingController();

  /// Editing controller for bio
  TextEditingController bioController = TextEditingController();

  /// Variable for storing file path of selected image
  ValueNotifier<String> imageFilePath = ValueNotifier('');

  /// Variable for storing network path of user's current profile picture
  ValueNotifier<String> imageNetworkPath = ValueNotifier('');

  /// Selected birth date in DateTime format
  DateTime selectedBirthDate = DateTime.now();

  /// True if the name is in correct format
  ValueNotifier<bool> verifyNameFormat = ValueNotifier(false);

  /// True if the username is in correct format
  ValueNotifier<bool> verifyUsernameFormat = ValueNotifier(false);

  /// True if the birth date is in correct format
  ValueNotifier<bool> verifyBirthDateFormat = ValueNotifier(false);

  /// True if the bio is in correct format
  ValueNotifier<bool> verifyBioFormat = ValueNotifier(false);

  /// Maximum length for name
  final int nameCharacterMaxLimit = profileInputMaxLimit['name'];

  /// Minimum length for username
  final int usernameCharacterMinLimit = profileInputMinLimit['username'];

  /// Maximum length for username
  final int usernameCharacterMaxLimit = profileInputMaxLimit['username'];

  /// Maximum length for bio
  final int bioCharacterMaxLimit = profileInputMaxLimit['bio'];

  EditUserProfileController(
    this.context
  );
  
  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    runDelay(() async => fetchUserProfileData(), actionDelayTime);
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
    birthDateController.addListener(() {
      if(mounted){
        String birthDateText = birthDateController.text;
        verifyBirthDateFormat.value = birthDateText.isNotEmpty;
      }
    });
    bioController.addListener(() {
      if(mounted){
        String bioText = bioController.text;
        verifyBioFormat.value = bioText.isNotEmpty && bioText.length <= bioCharacterMaxLimit
        && bioText.length <= bioCharacterMaxLimit;
      }
    });
  }

  /// Dispose everything. Called at every page's dispose function
  void dispose(){
    isLoading.dispose();
    nameController.dispose();
    usernameController.dispose();
    birthDateController.dispose();
    bioController.dispose();
    verifyNameFormat.dispose();
    verifyUsernameFormat.dispose();
    verifyBirthDateFormat.dispose();
    verifyBioFormat.dispose();
    imageFilePath.dispose();
    imageNetworkPath.dispose();
  }

  /// Called during initialization
  void fetchUserProfileData() async{
    if(mounted){
      isLoading.value = true;

      /// Call API to fetch user profile data
      dynamic res = await fetchDataRepo.fetchData(
        context, 
        RequestGet.fetchCurrentUserProfile, 
        {
          'currentID': appStateRepo.currentID
        }
      );

      if(mounted){
        isLoading.value = false;

        /// The API call is successful
        if(res != null){
          Map userProfileData = res['userProfileData'];
          nameController.text = userProfileData['name'];
          usernameController.text = userProfileData['username'];
          bioController.text = userProfileData['bio'];
          imageNetworkPath.value = userProfileData['profile_picture_link'];
          DateTime parsedBirthDate = DateTime.parse(userProfileData['birth_date']);
          selectedBirthDate = parsedBirthDate;
          birthDateController.text = '${parsedBirthDate.day}/${parsedBirthDate.month}/${parsedBirthDate.year}';
        }
      }
    }
  }
  
  /// Called when the user pressed the TextField for the birth date
  Future<void> selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthDate,
      firstDate: DateTime(1945, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedBirthDate){
      selectedBirthDate = picked;
      int day = picked.day;
      int month = picked.month;
      int year = picked.year;
      birthDateController.text = '$day/$month/$year';
    }
  }

  /// Function to pick image
  Future<void> pickImage() async {
    bool permissionIsGranted = false;
    ph.Permission? permission;
    if(Platform.isAndroid){
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if(androidInfo.version.sdkInt <= 32){
        permission = ph.Permission.storage;
      }else{
        permission = ph.Permission.photos;
      }
    }
    permissionIsGranted = await permission!.isGranted;
    if(!permissionIsGranted){
      await permission.request();
      permissionIsGranted = await permission.isGranted;
    }

    if(permissionIsGranted){
      try {
        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
        if(pickedFile != null && mounted){
          imageFilePath.value = pickedFile.path;
          imageNetworkPath.value = '';
        }
      } catch(e) {
        debugPrint('Failed to pick image: $e');
      }
    }
  }

  /// Called when the user pressed the given button
  void editProfile() async{
    if(mounted) {
      if(!isLoading.value){
        if(checkUsernameValid(usernameController.text.trim()) == false){

          /// Display a snackbar error if the username is not valid
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            'Username format is invalid.'
          );

        }else{  
          isLoading.value = true;
          String currentID = appStateRepo.currentID;
          String nameText = nameController.text.trim();
          String usernameText = usernameController.text.trim();
          String? imagePath;
          if(imageFilePath.value.isNotEmpty){

            /// Upload selected profile picture to AppWrite
            imagePath = await cloudController.uploadImageToAppWrite(
              context,
              imageFilePath.value
            );

          }else{
            imagePath = imageNetworkPath.value;
          }
          if(mounted){

            /// Call the API to edit the user profile with the given data
            dynamic res = await fetchDataRepo.fetchData(
              context, 
              RequestPatch.editUserProfile, 
              {
                'userID': currentID,
                'name': nameText,
                'username': usernameText,
                'profilePicLink': imagePath,
                'bio': bioController.text.trim(),
                'birthDate': selectedBirthDate.toString()
              }
            );
            
            if(mounted){
              isLoading.value = false;

              /// API call is successful
              if(res != null){

                /// Reflect the updated user profile at the app state repository
                UserDataClass currentUserProfileDataClass = appStateRepo.usersDataNotifiers.value[currentID]!.notifier.value;
                UserDataClass updatedCurrentUserProfileDataClass = UserDataClass(
                  currentID, nameText, usernameText, imagePath ?? defaultUserProfilePicLink, currentUserProfileDataClass.dateJoined, 
                  selectedBirthDate.toString(), bioController.text.trim(),
                  currentUserProfileDataClass.mutedByCurrentID, currentUserProfileDataClass.blockedByCurrentID, 
                  currentUserProfileDataClass.blocksCurrentID, currentUserProfileDataClass.private,
                  currentUserProfileDataClass.requestedByCurrentID, currentUserProfileDataClass.requestsToCurrentID,
                  currentUserProfileDataClass.verified, currentUserProfileDataClass.suspended, currentUserProfileDataClass.deleted
                );
                appStateRepo.usersDataNotifiers.value[currentID]!.notifier.value = updatedCurrentUserProfileDataClass;

                /// Navigate to previous page
                Navigator.pop(context);
                
              }
            }
          }
        }
      }
    }
  }
}