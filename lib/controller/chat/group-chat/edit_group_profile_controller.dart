import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

class EditGroupProfileController {
  BuildContext context;
  String chatID;
  ValueNotifier<GroupProfileClass> groupProfile;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  ValueNotifier<String> imageFilePath = ValueNotifier('');
  ValueNotifier<String> imageNetworkPath = ValueNotifier('');
  ValueNotifier<bool> verifyNameFormat = ValueNotifier(false);
  final int nameCharacterMaxLimit = groupProfileInputMaxLimit['name'];
  final int descriptionCharacterMaxLimit = groupProfileInputMaxLimit['description'];

  EditGroupProfileController(
    this.context,
    this.chatID,
    this.groupProfile
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
    socket.on("send-leave-group-announcement-$chatID", ( data ) async{
      if(mounted && data != null){
        groupProfile.value = GroupProfileClass(
          groupProfile.value.name, groupProfile.value.profilePicLink, 
          groupProfile.value.description, List<String>.of(data['recipients'])
        );
      }
    });
    socket.on("send-add-users-to-group-announcement-$chatID", ( data ) async{
      if(mounted && data != null){
        groupProfile.value = GroupProfileClass(
          groupProfile.value.name, groupProfile.value.profilePicLink, 
          groupProfile.value.description, List<String>.of([...data['recipients'], ...data['addedUsersID']])
        );
      }
    });
  }

  void dispose(){
    isLoading.dispose();
    nameController.dispose();
    descriptionController.dispose();
    imageFilePath.dispose();
    imageNetworkPath.dispose();
    verifyNameFormat.dispose();
    groupProfile.dispose();
    socket.disconnect();
  }

  void fetchUserProfileData(){
    if(mounted){
      nameController.text = groupProfile.value.name;
      imageNetworkPath.value = groupProfile.value.profilePicLink;
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
        final XFile? pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
          maxWidth: 1000,
          maxHeight: 1000,
        );
        if(pickedFile != null && mounted){
          imageFilePath.value = pickedFile.path;
          imageNetworkPath.value = '';
        }
      } catch (e) {
        debugPrint(e.toString());
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

  void editGroupProfile() async{
    if(mounted) {
      try {
        Navigator.pop(context);
        String messageID = const Uuid().v4();
        String senderName = appStateClass.usersDataNotifiers.value[appStateClass.currentID]!.notifier.value.name;
        String content = '$senderName has edited the group profile';
        socket.emit("edit-group-profile-to-server", {
          'chatID': chatID,
          'messageID': messageID,
          'content': content,
          'type': 'edit_group_profile',
          'sender': appStateClass.currentID,
          'recipients': groupProfile.value.recipients,
          'mediasDatas': [],
          'newData': {
            'name': nameController.text.trim(),
            'profilePicLink': imageFilePath.value.isEmpty ? imageNetworkPath.value : imageFilePath.value,
            'description': descriptionController.text.trim()
          }
        });
        await fetchDataRepo.fetchData(
          context, 
          RequestPatch.editGroupProfileData, 
          {
            'chatID': chatID,
            'messageID': messageID,
            'sender': appStateClass.currentID,
            'recipients': groupProfile.value.recipients,
            'newData': {
              'name': nameController.text.trim(),
              'profilePicLink': imageFilePath.value.isEmpty ? imageNetworkPath.value : imageFilePath.value,
              'description': descriptionController.text.trim()
            }
          }
        );
      } catch (_) {
        if(mounted) {
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            tErr.api
          );
        }
      }
    }
  }
}