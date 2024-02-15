import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

/// Controller which is used when the user wants to edit the group chat's profile
class EditGroupProfileController {
   
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// The chatID of the group chat that will be passed to the controller
  String chatID;

  /// The group profile that will be passed to the controller
  ValueNotifier<GroupProfileClass> groupProfile;

  /// True if an API/Firebase/AppWrite function is running
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  
  /// An editing controller for the user to insert a name
  TextEditingController nameController = TextEditingController();

  /// An editing controller for the user to insert a description
  TextEditingController descriptionController = TextEditingController();

  /// Variable storing image file path
  ValueNotifier<String> imageFilePath = ValueNotifier('');

  /// Variable storing image network path
  ValueNotifier<String> imageNetworkPath = ValueNotifier('');

  /// True if the name is in acceptable format
  ValueNotifier<bool> verifyNameFormat = ValueNotifier(false);

  /// Maximum length of a name
  final int nameCharacterMaxLimit = groupProfileInputMaxLimit['name'];

  /// Maximum length of a description
  final int descriptionCharacterMaxLimit = groupProfileInputMaxLimit['description'];

  EditGroupProfileController(
    this.context,
    this.chatID,
    this.groupProfile
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

    /// Listen to sockets to handle group profile data
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

  /// Dispose everything. Called at every page's dispose function
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

  /// Called when controller is initialized
  void fetchUserProfileData(){
    if(mounted){
      
      /// Update the editing controller and image network path based on the group profile data passed to the controller
      nameController.text = groupProfile.value.name;
      imageNetworkPath.value = groupProfile.value.profilePicLink;

    }
  }
  
  /// Function to pick image
  Future<void> pickImage() async {

    /// Handle permission
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

    /// Proceed once permission is granted
    if(permissionIsGranted){
      try {
        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
        if(pickedFile != null && mounted){

          /// Update the variable once image is selected
          imageFilePath.value = pickedFile.path;
        }
      } catch(e) {
        debugPrint('Failed to pick image: $e');
      }
    }
  }

  /// Called when the user presssed the given button
  void editGroupProfile() async{
    if(mounted) {
      try {

        /// Navigate the user out of the page
        Navigator.pop(context);

        String messageID = const Uuid().v4();
        String senderName = appStateRepo.usersDataNotifiers.value[appStateRepo.currentID]!.notifier.value.name;
        String content = '$senderName has edited the group profile';

        /// Call the socket to edit the group profile
        socket.emit("edit-group-profile-to-server", {
          'chatID': chatID,
          'messageID': messageID,
          'content': content,
          'type': 'edit_group_profile',
          'sender': appStateRepo.currentID,
          'recipients': groupProfile.value.recipients,
          'mediasDatas': [],
          'newData': {
            'name': nameController.text.trim(),
            'profilePicLink': imageFilePath.value.isEmpty ? imageNetworkPath.value : imageFilePath.value,
            'description': descriptionController.text.trim()
          }
        });

        /// Call the API to edit the group profile
        await fetchDataRepo.fetchData(
          context, 
          RequestPatch.editGroupProfileData, 
          {
            'chatID': chatID,
            'messageID': messageID,
            'sender': appStateRepo.currentID,
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