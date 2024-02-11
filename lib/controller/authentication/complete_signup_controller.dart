import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

class CompleteSignUpController {
  BuildContext context;
  ValueNotifier<String> imageFilePath = ValueNotifier('');
  TextEditingController bioController = TextEditingController();
  ValueNotifier<bool> verifyBioFormat = ValueNotifier(false);
  final int bioCharacterMaxLimit = profileInputMaxLimit['bio'];
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  CompleteSignUpController(
    this.context
  );

  bool get mounted => context.mounted;

  void initializeController(){
    bioController.addListener(() {
      if(mounted){
        String bioText = bioController.text;
        verifyBioFormat.value = bioText.isNotEmpty && bioText.length <= bioCharacterMaxLimit
        && bioText.length <= bioCharacterMaxLimit;
      }
    });
  }

  void dispose(){
    imageFilePath.dispose();
    bioController.dispose();
    verifyBioFormat.dispose();
    isLoading.dispose();
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
      debugPrint(error.response);
    });
    return loadedUri;
  }
  
  void completeSignUpProfile() async{
    try {
      if(mounted){
        if(!isLoading.value){
          isLoading.value = true;
          String uploadProfilePic = await uploadMediaToAppWrite(appStateClass.currentID, storageBucketIDs['image'], imageFilePath.value);
          String stringified = jsonEncode({
            'userId': appStateClass.currentID,
            'profilePicLink': uploadProfilePic,
            'bio': bioController.text.trim(),
          });
          var res = await dio.post('$serverDomainAddress/users/completeSignUpProfile', data: stringified);
          if(res.data.isNotEmpty){
            if(res.data['message'] == 'Successfully updated your account'){
              appStateClass.usersDataNotifiers.value[appStateClass.currentID]!.notifier.value.profilePicLink = uploadProfilePic;
              runDelay(() => Navigator.pushAndRemoveUntil(
                context,
                SliderRightToLeftRoute(
                  page: const MainPageWidget()
                ),
                (Route<dynamic> route) => false
              ), navigatorDelayTime);
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
      }
    } catch (_) {
      isLoading.value = false;
      if(mounted){
        handler.displaySnackbar(
          context, 
          SnackbarType.error,
          tErr.unknown, 
        );
      }
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
        }
      } catch(e) {
        debugPrint('Failed to pick image: $e');
      }
    }
  }
}