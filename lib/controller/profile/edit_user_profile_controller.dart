import 'dart:convert';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

class EditUserProfileController {
  BuildContext context;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  ValueNotifier<String> imageFilePath = ValueNotifier('');
  ValueNotifier<String> imageNetworkPath = ValueNotifier('');
  DateTime selectedBirthDate = DateTime.now();
  ValueNotifier<bool> verifyNameFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyUsernameFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyBirthDateFormat = ValueNotifier(false);
  ValueNotifier<bool> verifyBioFormat = ValueNotifier(false);
  final int nameCharacterMaxLimit = profileInputMaxLimit['name'];
  final int usernameCharacterMinLimit = profileInputMinLimit['username'];
  final int usernameCharacterMaxLimit = profileInputMaxLimit['username'];
  final int passwordCharacterMaxLimit = profileInputMaxLimit['password'];
  final int bioCharacterMaxLimit = profileInputMaxLimit['bio'];

  EditUserProfileController(
    this.context
  );
  
  bool get mounted => context.mounted;

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

  void fetchUserProfileData() async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = jsonEncode({
          'currentID': appStateClass.currentID
        });
        var res = await dio.get('$serverDomainAddress/users/fetchCurrentUserProfile', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            if(mounted){
              Map userProfileData = res.data['userProfileData'];
              nameController.text = userProfileData['name'];
              usernameController.text = userProfileData['username'];
              bioController.text = userProfileData['bio'];
              imageNetworkPath.value = userProfileData['profile_picture_link'];
              DateTime parsedBirthDate = DateTime.parse(userProfileData['birth_date']);
              selectedBirthDate = parsedBirthDate;
              birthDateController.text = '${parsedBirthDate.day}/${parsedBirthDate.month}/${parsedBirthDate.year}';
            }
          }else{
            if(mounted){
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Alert!!!', style: TextStyle(fontSize: defaultTextFontSize)),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: [
                          Text(res.data['message'], style: TextStyle(fontSize: defaultTextFontSize)),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Continue', style: TextStyle(fontSize: defaultTextFontSize)),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          }
          if(mounted){
            isLoading.value = false;
          }
        }
      }
    } on Exception catch (e) {
      
    }
  }
  
  Future<void> selectBirthDate(BuildContext context) async {
    try {
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
    } on Exception catch (e) {
      
    }
  }

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

  Future<String> uploadMediaToAppWrite(String uniqueID, String bucketID, String uri) async{
    String loadedUri = '';
    final appWriteStorage = Storage(updateAppWriteClient());
    await appWriteStorage.createFile(
      bucketId: bucketID,
      fileId: uniqueID,
      file: fileToInputFile(uri, uniqueID)
    ).then((response){
      loadedUri = 'https://cloud.appwrite.io/v1/storage/buckets/$bucketID/files/$uniqueID/view?project=$appWriteUserID&mode=admin';
    })
    .catchError((error) {
      debugPrint(error.toString());
    });
    return loadedUri;
  }

  void editProfile() async{
    try {
      if(!isLoading.value){
        if(checkUsernameValid(usernameController.text.trim()) == false){
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Alert!!!', style: TextStyle(fontSize: defaultTextFontSize)),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text('Username format is invalid.', style: TextStyle(fontSize: defaultTextFontSize)),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Ok', style: TextStyle(fontSize: defaultTextFontSize)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }else{  
          String currentID = appStateClass.currentID;
          String nameText = nameController.text.trim();
          String usernameText = usernameController.text.trim();
          String imagePath = '';
          if(imageFilePath.value.isNotEmpty){
            imagePath = await uploadMediaToAppWrite(appStateClass.currentID, storageBucketIDs['image'], imageFilePath.value);
          }else{
            imagePath = imageNetworkPath.value;
          }
          String stringified = jsonEncode({
            'userID': currentID,
            'name': nameText,
            'username': usernameText,
            'profilePicLink': imagePath,
            'bio': bioController.text.trim(),
            'birthDate': selectedBirthDate.toString()
          });
          var res = await dio.patch('$serverDomainAddress/users/editUserProfile', data: stringified);
          if(res.data.isNotEmpty){
            if(res.data['message'] == 'Successfully updated user profile'){
              UserDataClass currentUserProfileDataClass = appStateClass.usersDataNotifiers.value[currentID]!.notifier.value;
              UserDataClass updatedCurrentUserProfileDataClass = UserDataClass(
                currentID, nameText, usernameText, imagePath, currentUserProfileDataClass.dateJoined, 
                selectedBirthDate.toString(), bioController.text.trim(),
                currentUserProfileDataClass.mutedByCurrentID, currentUserProfileDataClass.blockedByCurrentID, 
                currentUserProfileDataClass.blocksCurrentID, currentUserProfileDataClass.private,
                currentUserProfileDataClass.requestedByCurrentID, currentUserProfileDataClass.requestsToCurrentID,
                currentUserProfileDataClass.verified, currentUserProfileDataClass.suspended, currentUserProfileDataClass.deleted
              );
              appStateClass.usersDataNotifiers.value[currentID]!.notifier.value = updatedCurrentUserProfileDataClass;
              if(mounted){
                Navigator.pop(context);
              }
            }else{
              if(mounted){
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Alert!!!', style: TextStyle(fontSize: defaultTextFontSize)),
                      content: SingleChildScrollView(
                        child: ListBody(
                          children: [
                            Text(res.data['message'], style: TextStyle(fontSize: defaultTextFontSize)),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Continue', style: TextStyle(fontSize: defaultTextFontSize)),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            }
          }
        }
      }
    } on Exception catch (e) {
      
    }
  }
}