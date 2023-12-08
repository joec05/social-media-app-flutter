// ignore_for_file: library_prefixes, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:appwrite/appwrite.dart';
import 'package:dio/dio.dart' as d;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/class/GroupProfileClass.dart';
import 'package:social_media_app/class/MediaDataClass.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/socket/main.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'Chats.dart';
import 'GroupProfilePage.dart';
import 'SearchTagUsers.dart';
import 'class/GroupMessageClass.dart';
import 'class/GroupMessageNotifier.dart';
import 'class/WebsiteCardClass.dart';
import 'custom/CustomPagination.dart';
import 'custom/CustomGroupMessageWidget.dart';
import 'custom/CustomTextEditingController.dart';
import 'package:custom_image_editor/EditImage.dart' as ImageEditor;
import 'package:custom_video_editor/VideoEditor.dart' as VideoEditor;
import 'extenstions/StringEllipsis.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';

var dio = d.Dio();

class GroupChatRoomWidget extends StatelessWidget {
  final String? chatID;
  final List<String>? recipients;
  const GroupChatRoomWidget({super.key, required this.chatID, required this.recipients});

  @override
  Widget build(BuildContext context) {
    return _GroupChatRoomWidgetStateful(chatID: chatID, recipients: recipients);
  }
}

class _GroupChatRoomWidgetStateful extends StatefulWidget {
  final String? chatID;
  final List<String>? recipients;
  const _GroupChatRoomWidgetStateful({required this.chatID, required this.recipients});

  @override
  State<_GroupChatRoomWidgetStateful> createState() => _GroupChatRoomWidgetStatefulState();
}

class _GroupChatRoomWidgetStatefulState extends State<_GroupChatRoomWidgetStateful> with LifecycleListenerMixin{
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<bool> isListeningLink = ValueNotifier(false);
  ValueNotifier<List<GroupMessageNotifier>> messages = ValueNotifier([]);
  ValueNotifier<GroupProfileClass> groupProfile = ValueNotifier(GroupProfileClass('', '', '', []));
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  CustomTextFieldEditingController messageController = CustomTextFieldEditingController();
  ValueNotifier<bool> verifyMessageFormat = ValueNotifier(false);
  late ValueNotifier<String?> chatID = ValueNotifier(null);
  ValueNotifier<String?> newChatID = ValueNotifier(null);
  ValueNotifier<List<MediaDatasClass>> mediasDatas = ValueNotifier([]);
  ValueNotifier<List<Widget>> mediasComponents = ValueNotifier([]);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    if(mounted){
      chatID.value = widget.chatID;
      newChatID.value = chatID.value == null ? const Uuid().v4() : null;
    }
    runDelay(() async => fetchGroupChatData(messages.value.length, false, false), actionDelayTime);
    messageController.addListener(() {
      if(mounted){
        String messageText = messageController.text;
        verifyMessageFormat.value = messageText.isNotEmpty && messageText.length <= messageCharacterMaxLimit;
      }
    });
    String socketChatID = mounted ? chatID.value == null ? newChatID.value! : chatID.value! : '';
    socket.on("send-group-message-$socketChatID", ( data ) async{
      if(mounted && data != null){
        messages.value = [GroupMessageNotifier(data['messageID'], ValueNotifier(
          GroupMessageClass(
            data['messageID'], 'message', data['content'], data['sender'], DateTime.now().toIso8601String(), 
            await loadMediasDatas(data['mediasDatas']), []
          )
        )), ...messages.value];
      }
    });
    socket.on("delete-group-message-${appStateClass.currentID}-$socketChatID", ( data ) async{
      if(mounted && data != null){
        for(int i = 0; i < messages.value.length; i++){
          GroupMessageClass groupMessageData = messages.value[i].notifier.value;
          if(groupMessageData.messageID == data['messageID']){
            var messagesList = [...messages.value];
            messagesList.removeAt(i);
            messages.value = [...messagesList];
            break;
          }
        }
      }
    });
    socket.on("delete-group-message-for-all-$socketChatID", ( data ) async{
      if(mounted && data != null){
        for(int i = 0; i < messages.value.length; i++){
          GroupMessageClass groupMessageData = messages.value[i].notifier.value;
          if(groupMessageData.messageID == data['messageID']){
            var messagesList = [...messages.value];
            messagesList.removeAt(i);
            messages.value = [...messagesList];
            break;
          }
        }
      }
    });
    socket.on("send-edit-group-announcement-$socketChatID", ( data ) async{
      if(mounted && data != null){
        messages.value = [GroupMessageNotifier(data['messageID'], ValueNotifier(
          GroupMessageClass(
            data['messageID'], data['type'], data['content'], data['sender'], DateTime.now().toIso8601String(), 
            await loadMediasDatas(data['mediasDatas']), []
          )
        )), ...messages.value];
        groupProfile.value = GroupProfileClass(
          data['newData']['name'], data['newData']['profilePicLink'], data['newData']['description'], groupProfile.value.recipients
        );
      }
    });
    socket.on("send-leave-group-announcement-$socketChatID", ( data ) async{
      if(mounted && data != null){
        messages.value = [GroupMessageNotifier(data['messageID'], ValueNotifier(
          GroupMessageClass(
            data['messageID'], data['type'], data['content'], data['sender'], DateTime.now().toIso8601String(), 
            await loadMediasDatas(data['mediasDatas']), []
          )
        )), ...messages.value];
        groupProfile.value = GroupProfileClass(
          groupProfile.value.name, groupProfile.value.profilePicLink, 
          groupProfile.value.description, List<String>.from(data['recipients'])
        );
      }
    });
    socket.on("leave-group-sender-${appStateClass.currentID}", ( data ) async{
      if(mounted && data != null){
        runDelay(() => Navigator.pushReplacement(
          context,
          SliderRightToLeftRoute(
            page: const ChatsWidget()
          )
        ), navigatorDelayTime);
      }
    });
    socket.on("send-add-users-to-group-announcement-$socketChatID", ( data ) async{
      if(mounted && data != null){
        for(int i = 0; i < data['addedUsersData'].length; i++){
          if(mounted){
            updateUserData(UserDataClass.fromMap(data['addedUsersData'][i]), context);
          }
        }
        for(int i = 0; i < data['contentsList'].length; i++){
          messages.value = [GroupMessageNotifier(data['messagesID'][i
          ], ValueNotifier(
            GroupMessageClass(
              data['messagesID'][i], data['type'], data['contentsList'][i], data['sender'], DateTime.now().toIso8601String(), 
              await loadMediasDatas(data['mediasDatas']), []
            )
          )), ...messages.value];
        }
        groupProfile.value = GroupProfileClass(
          groupProfile.value.name, groupProfile.value.profilePicLink, 
          groupProfile.value.description, List<String>.from([...data['recipients'], ...data['addedUsersID']])
        );
      }
    });
    _scrollController.addListener(() {
      if(mounted){
        if(_scrollController.position.pixels > animateToTopMinHeight){
          if(!displayFloatingBtn.value){
            displayFloatingBtn.value = true;
          }
        }else{
          if(displayFloatingBtn.value){
            displayFloatingBtn.value = false;
          }
        }
      }
    });
  }
  
  @override
  void dispose(){
    super.dispose();
    isLoading.dispose();
    messages.dispose();
    groupProfile.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    messageController.dispose();
    verifyMessageFormat.dispose();
    chatID.dispose();
    newChatID.dispose();
    mediasDatas.dispose();
    mediasComponents.dispose();
    isListeningLink.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchGroupChatData(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        if(widget.recipients == null){
          isLoading.value = true;
          String stringified = jsonEncode({
            'chatID': chatID.value,
            'currentID': appStateClass.currentID,
            'currentLength': currentPostsLength,
            'paginationLimit': messagesPaginationLimit,
            'maxFetchLimit': messagesServerFetchLimit
          }); 
          d.Response res;
          if(isPaginating){
            res = await dio.get('$serverDomainAddress/users/fetchGroupChatPagination', data: stringified);
          }else{
            res = await dio.get('$serverDomainAddress/users/fetchGroupChat', data: stringified);
          }
          if(res.data.isNotEmpty){
            if(res.data['message'] != 'blacklisted'){
              if(mounted){
                chatID.value = res.data['chatID'];
              }
              List messagesData = res.data['messagesData'];
              List usersProfileDatasList = res.data['membersProfileData'];
              List usersSocialsDatasList = res.data['membersSocialsData'];
              
              if(!isPaginating && mounted){
                List<String> groupMembersID = List<String>.from(res.data['groupMembersID']);
                Map groupProfileData = res.data['groupProfileData'];
                groupProfile.value = GroupProfileClass(
                  groupProfileData['name'], groupProfileData['profile_pic_link'], 
                  groupProfileData['description'], groupMembersID
                );
              }
        
              if(isRefreshing && mounted){
                messages.value = [];
              }
              if(mounted){
                canPaginate.value = res.data['canPaginate'];
              }
              for(int i = 0; i < usersProfileDatasList.length; i++){
                Map userProfileData = usersProfileDatasList[i];
                UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
                UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
                if(mounted){
                  updateUserData(userDataClass, context);
                  updateUserSocials(userDataClass, userSocialClass, context);
                }
              }
              for(int i = 0; i < messagesData.length; i++){
                Map messageData = messagesData[i];
                if(messageData['type'] != 'message'){
                  String senderName = usersProfileDatasList.where((e) => e['user_id'] == messageData['sender']).toList()[0]['name'];
                  if(messageData['type'] == 'edit_group_profile'){
                    messageData['content'] = '$senderName has edited the group profile';
                  }else if(messageData['type'] == 'leave_group'){
                    messageData['content'] = '$senderName has left the group';
                  }else if(messageData['type'].contains('add_users_to_group')){
                    String addedUserID = messageData['type'].replaceAll('add_users_to_group_', '');
                    String addedUserName = usersProfileDatasList.where((e) => e['user_id'] == addedUserID).toList()[0]['name'];
                    messageData['content'] = '$senderName has added $addedUserName to the group';
                  }
                } 
                List<MediaDatasClass> newMediasDatas = await loadMediasDatas(jsonDecode(messageData['medias_datas']));
                if(mounted){
                  messages.value = [...messages.value, GroupMessageNotifier(
                    messageData['message_id'], ValueNotifier(
                      GroupMessageClass.fromMap(messageData, newMediasDatas)
                    )
                  )];
                }
              }
            }
            if(mounted){
              isLoading.value = false;
            }
          }
        }else{
          if(mounted){
            groupProfile.value = GroupProfileClass(
              'You and ${widget.recipients!.length - 1} others', 
              defaultGroupChatProfilePicLink, 
              '', 
              widget.recipients!
            );
          }
        }
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<void> loadMoreChats() async{
    try {
      if(mounted){
        paginationStatus.value = PaginationStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchGroupChatData(messages.value.length, false, true);
          if(mounted){
            paginationStatus.value = PaginationStatus.loaded;
          }
        });
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<void> pickImage(ImageSource source, {BuildContext? context}) async {
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
        if(mediasDatas.value.length < maxMediaCount){
          final XFile? pickedFile = await ImagePicker().pickImage(
            source: source,
            imageQuality: 100,
            maxWidth: 1000,
            maxHeight: 1000,
          );
          if(pickedFile != null && mediasDatas.value.length < maxMediaCount){
            String imageUrl = pickedFile.path;
            ui.Image imageDimension = await calculateImageFileDimension(imageUrl);
            Size scaledDimension = getSizeScale(imageDimension.width.toDouble(), imageDimension.height.toDouble());
            if(mounted){
              mediasDatas.value = [
                ...mediasDatas.value,
                MediaDatasClass(MediaType.image, imageUrl, null, '', MediaSourceType.file, null, scaledDimension)
              ];
              mediasComponents.value = [
                ...mediasComponents.value, mediaDataDraftMessageComponentWidget(mediasDatas.value.last, scaledDimension
                )
              ];
            }
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  Future _pickVideo() async {
    bool permissionIsGranted = false;
    ph.Permission? permission;
    if(Platform.isAndroid){
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if(androidInfo.version.sdkInt <= 32){
        permission = ph.Permission.storage;
      }else{
        permission = ph.Permission.videos;
      }
    }
    permissionIsGranted = await permission!.isGranted;
    if(!permissionIsGranted){
      await permission.request();
      permissionIsGranted = await permission.isGranted;
    }

    if(permissionIsGranted){
      try {
        if(mediasDatas.value.length < maxMediaCount){
          final XFile? file = await ImagePicker().pickVideo(source: ImageSource.gallery);
          if (mounted && file != null && mediasDatas.value.length < maxMediaCount) {
            var playerController = VideoPlayerController.file(File(file.path));
            await playerController.initialize();
            Size scaledDimension = getSizeScale(playerController.value.size.width, playerController.value.size.height);
            if(mounted){
              mediasDatas.value = [...mediasDatas.value, MediaDatasClass(MediaType.video, file.path, playerController, '', MediaSourceType.file, null, scaledDimension)];
              mediasComponents.value = [
                ...mediasComponents.value, mediaDataDraftMessageComponentWidget(mediasDatas.value.last, scaledDimension)
              ];
            }
          }
        }
      } on Exception catch (e) {
        doSomethingWithException(e);
      }
    }
  }

  Future<void> editImage(File imageFile, int index) async {
    try {
      runDelay(()async {
        final fileResult = await Navigator.push(
          context,
          SliderRightToLeftRoute(
            page: ImageEditor.EditImageComponent(imageFile: imageFile)
          )
        );
        if (fileResult != null && fileResult is ImageEditor.FinishedImageData) {
          String imageUrl = fileResult.file.path; //file path of the newly updated image
          ui.Image imageDimension = await calculateImageFileDimension(imageUrl);
          Size scaledDimension = getSizeScale(imageDimension.width.toDouble(), imageDimension.height.toDouble());
          List<MediaDatasClass> mediasDatasList = [...mediasDatas.value];
          if(mounted){
            mediasDatasList[index] = MediaDatasClass(MediaType.image, imageUrl, null, '', MediaSourceType.file, null, scaledDimension);
            mediasDatas.value = [...mediasDatasList];
            List<Widget> mediasComponentsList = [...mediasComponents.value];
            mediasComponentsList[index] = mediaDataDraftMessageComponentWidget(mediasDatas.value[index], scaledDimension);
            mediasComponents.value = [...mediasComponentsList];
          }
        }
      }, navigatorDelayTime); 
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<void> editVideo(String videoLink, int index) async {
    try {
      runDelay(()async {
        final updatedRes = await Navigator.push(
          context,
          SliderRightToLeftRoute(
            page: VideoEditor.EditVideoComponent(videoLink: videoLink)
          )
        );
        if(updatedRes != null && updatedRes is VideoEditor.FinishedVideoData){
          VideoPlayerController playerController = VideoPlayerController.file(File(updatedRes.url));
          await playerController.initialize();
          Size scaledDimension = getSizeScale(playerController.value.size.width, playerController.value.size.height);
          List<MediaDatasClass> mediasDatasList = [...mediasDatas.value];
          if(mounted){
            mediasDatasList[index] = MediaDatasClass(MediaType.video, updatedRes.url, playerController, '', MediaSourceType.file, null, scaledDimension);
            mediasDatas.value = [...mediasDatasList];
            List<Widget> mediasComponentsList = [...mediasComponents.value];
            mediasComponentsList[index] = mediaDataDraftMessageComponentWidget(mediasDatas.value[index], scaledDimension);
            mediasComponents.value = [...mediasComponentsList];
          }
        }
      }, navigatorDelayTime);
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<String> uploadImageToAppWrite(String bucketID, int index) async{
    String loadedUri = '';
    final appWriteStorage = Storage(updateAppWriteClient());
    String uniqueID = const Uuid().v4();
    await appWriteStorage.createFile(
      bucketId: bucketID,
      fileId: uniqueID,
      file: fileToInputFile(mediasDatas.value[index].url, uniqueID)
    ).then((response) async{
      loadedUri = 'https://cloud.appwrite.io/v1/storage/buckets/$bucketID/files/$uniqueID/view?project=$appWriteUserID&mode=admin';
      mediasDatas.value[index].storagePath = uniqueID;
    })
    .catchError((error) {
      debugPrint(error.toString());
    });
    return loadedUri;
  }

  Future<String> uploadVideoToFirebase(BuildContext context, int index) async {
    String storageUrl = '';
    try {
      File mediaFilePath = File(mediasDatas.value[index].url);
      FirebaseStorage storage = FirebaseStorage.instance;
      String childDirectory = '/${appStateClass.currentID}/${const Uuid().v4()}';
      mediasDatas.value[index].storagePath = childDirectory;
      Reference ref = storage.ref('/videos').child(childDirectory);
      UploadTask uploadTask = ref.putFile(mediaFilePath, SettableMetadata(contentType: 'video/mp4'));
      var mediaUrl = await (await uploadTask).ref.getDownloadURL();
      storageUrl = mediaUrl.toString();
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
    return storageUrl;
  }

  Widget mediaComponentIndex(mediaComponent, index){
    return Container(
      margin: EdgeInsets.only(top: mediaComponentMargin),
      child: Stack(
        children: [
          SizedBox(
            child: mediaComponent
          ),
          Positioned(
            top: 0, right: 0,
            child: Container(
              width: getScreenWidth() * 0.1,
              height: getScreenWidth() * 0.1,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: GestureDetector(
                onTap: (){
                  if(mounted){
                    List<Widget> mediasComponents2 = [...mediasComponents.value];
                    mediasComponents2.removeAt(index);
                    mediasComponents.value = mediasComponents2;
                    List<MediaDatasClass> mediasDatas2 = [...mediasDatas.value];
                    if(mediasDatas2[index].mediaType == MediaType.video){
                      mediasDatas2[index].playerController!.dispose();
                    }
                    mediasDatas2.removeAt(index);
                    mediasDatas.value = mediasDatas2;
                  }
                },
                child: const Icon(FontAwesomeIcons.trash, size: 17.5, color: Colors.black)
              )
            )
          ),
          Positioned(
            top: 0, right: getScreenWidth() * 0.125,
            child: Container(
              width: getScreenWidth() * 0.1,
              height: getScreenWidth() * 0.1,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: GestureDetector(
                onTap: (){
                  if(mediasDatas.value[index].mediaType == MediaType.image){
                    editImage(File(mediasDatas.value[index].url), index);
                  }else if(mediasDatas.value[index].mediaType == MediaType.video){
                    editVideo(mediasDatas.value[index].url, index);
                  }
                },
                child: const Icon(FontAwesomeIcons.pencil, size: 17.5, color: Colors.black)
              )
            )
          ),
        ],
      )
    );
  }

  void listenTextField(String value){
    if(isUserTagged(messageController)){
      displayUsernamesToTag();
    }
  }

  void listenTextController(text) async{
    if(mounted){
      if(!isListeningLink.value && !isLoading.value && mediasDatas.value.length < maxMessageMediaCount){
        isListeningLink.value = true;
        List textList = text.split(' ');
        for(int i = 0; i < textList.length; i++){
          if(textList[i].isNotEmpty){
            List lines = textList[i].split('\n');
            for(int j = 0; j < lines.length; j++){
              if(isLinkRegex.hasMatch(lines[j])){
                WebsiteCardClass linkPreview = await fetchLinkPreview(lines[j]);
                if(mounted){
                  if(linkPreview.title.isNotEmpty && mediasDatas.value.length < maxMessageMediaCount){
                    mediasDatas.value = [...mediasDatas.value, MediaDatasClass(
                      MediaType.websiteCard, lines[j], null, '', MediaSourceType.network, linkPreview, null
                    )];
                    mediasComponents.value = [...mediasComponents.value, mediaDataDraftMessageComponentWidget(mediasDatas.value.last, null)];
                    textList = text.split(' ');
                    textList[i] = textList[i].replaceFirst(lines[j], '');
                    messageController.value = TextEditingValue(
                      text: textList.join(' '),
                      selection: TextSelection.fromPosition(
                        TextPosition(offset: textList.join(' ').length),
                      ),
                    );
                  }
                }
              }
            }
          }
        }     
        if(mounted){ 
          isListeningLink.value = false;
        }
      }
    }
  }
  
  void displayUsernamesToTag(){
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SearchTagUsersWidget(onUserIsSelected: userIsTagged,);
      },
    );
  }

  void userIsTagged(List<String> usernames, List<String> userIDs){
    for(int i = 0; i < usernames.length; i++){
      String username = usernames[i];
      final int cursorPosition = messageController.selection.start;
      String text = messageController.text;
      String newText = '';
      if(i > 0){
        newText = '${text.substring(0, cursorPosition)}@$username ${text.substring(cursorPosition)}';
      }else{
        newText = '${text.substring(0, cursorPosition)}$username ${text.substring(cursorPosition)}';
      }
      messageController.text = newText;
      messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: cursorPosition + username.length + 1)
      );
    }
  }

  void sendGroupMessage() async{
    if(!isLoading.value){
      isLoading.value = true;
      try {
        String messageID = const Uuid().v4();
        List<MediaDatasClass> updatedMediasDatas = [];
        for(int i = 0; i < mediasDatas.value.length; i++){
          MediaDatasClass mediaData = mediasDatas.value[i];
          String storageUrl = '';
          if(mediasDatas.value[i].mediaType == MediaType.image){
            storageUrl = await uploadImageToAppWrite(storageBucketIDs['image'], i);
          }else if(mediasDatas.value[i].mediaType == MediaType.video){
            mediaData.playerController!.pause();
            storageUrl = await uploadVideoToFirebase(context, i);
          }else if(mediasDatas.value[i].mediaType == MediaType.websiteCard){
            storageUrl = mediaData.url;
          }
          if(storageUrl.isNotEmpty){
            updatedMediasDatas.add(MediaDatasClass(
              mediaData.mediaType, storageUrl, mediaData.playerController, mediaData.storagePath, 
              MediaSourceType.network, mediaData.websiteCardData, mediaData.mediaSize
            ));
          }
        }
        
        List<Map<String, dynamic>> serverMediasDatas = [];
        for(int i = 0; i < updatedMediasDatas.length; i++){
          serverMediasDatas.add(updatedMediasDatas[i].toMap());
        }
        
        socket.emit("send-group-message-to-server", {
          'chatID': chatID.value ?? newChatID.value,
          'messageID': messageID,
          'content': messageController.text,
          'sender': appStateClass.currentID,
          'senderData': appStateClass.usersDataNotifiers.value[appStateClass.currentID]!.notifier.value.toMap(),
          'recipients': groupProfile.value.recipients,
          'mediasDatas': serverMediasDatas,
          'type': 'message'
        });
        
        String stringified = jsonEncode({
          'chatID': chatID.value,
          'newChatID': newChatID.value,
          'messageID': messageID,
          'content': messageController.text,
          'sender': appStateClass.currentID,
          'recipients': groupProfile.value.recipients,
          'mediasDatas': serverMediasDatas,
        });
        if(mounted){
          messageController.text = '';
          mediasDatas.value = [];
          mediasComponents.value = [];
        }
        var res = await dio.post('$serverDomainAddress/users/sendGroupMessage', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully sent message' && mounted){
            if(chatID.value == null){
              chatID.value = newChatID.value;
              newChatID.value = null;
              groupProfile.value = GroupProfileClass(
                'Group ${chatID.value}', groupProfile.value.profilePicLink, '', widget.recipients!
              );
            }
          }
          if(mounted){
            isLoading.value = false;
          }
        }
      } on Exception catch (e) {
        doSomethingWithException(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        titleSpacing: defaultAppBarTitleSpacing,
        title: ValueListenableBuilder(
          valueListenable: groupProfile, 
          builder: ((context, groupProfileData, child) {
            if(groupProfileData.profilePicLink.isNotEmpty){
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: (){
                      if(chatID.value != null){
                        runDelay(() => Navigator.push(
                          context,
                          SliderRightToLeftRoute(
                            page: GroupProfilePageWidget(chatID: chatID.value!, groupProfileData: groupProfile.value,)
                          )
                        ), navigatorDelayTime);
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start, 
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: getScreenWidth() * 0.075,
                                    height: getScreenWidth() * 0.075,
                                    decoration: BoxDecoration(
                                      border: Border.all(width: 2, color: Colors.white),
                                      borderRadius: BorderRadius.circular(100),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          groupProfileData.profilePicLink
                                        ), fit: BoxFit.fill
                                      )
                                    ),
                                  )
                                ]
                              ),
                              SizedBox(width: getScreenWidth() * 0.02),
                              Expanded( 
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(StringEllipsis.convertToEllipsis(groupProfileData.name), maxLines: 1, overflow: TextOverflow.ellipsis)
                                  ],
                                )
                              )
                            ],
                          )
                        ),
                      ],
                    )
                  ),
                ],
              );
            }
            return SizedBox(
              width: getScreenWidth() * 0.075,
              height: getScreenWidth() * 0.075,
            );
          })
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: chatID,
            builder: (context, chatIDValue, child){
              if(chatIDValue != null){
                return PopupMenuButton(
                  onSelected: (result) {
                    if(result == 'Delete Chat'){
                      Navigator.pop(context, GroupMessageActions.deleteChat);
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry>[
                    const PopupMenuItem(
                      value: 'Delete Chat',
                      child: Text('Delete Chat')
                    ),
                  ]
                );
              }
              return Container();
            }
          )
        ]
      ),
      body: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: paginationStatus,
            builder: (context, loadingStatusValue, child){
              return ValueListenableBuilder(
                valueListenable: canPaginate,
                builder: (context, canPaginateValue, child){
                  return ValueListenableBuilder(
                    valueListenable: messages, 
                    builder: ((context, messages, child) {
                      return Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                LoadMoreBottom(
                                  addBottomSpace: canPaginateValue,
                                  loadMore: () async{
                                    if(canPaginateValue){
                                      await loadMoreChats();
                                    }else{
                                    }
                                  },
                                  status: loadingStatusValue,
                                  refresh: null,
                                  child: CustomScrollView(
                                    controller: _scrollController,
                                    shrinkWrap: true,
                                    reverse: true,
                                    slivers: 
                                    <Widget>[
                                      SliverList(delegate: SliverChildBuilderDelegate(
                                        childCount: messages.length,
                                        (context, index) {
                                          return ValueListenableBuilder(
                                            valueListenable: messages[index].notifier, 
                                            builder: ((context, messageData, child) {
                                              return ValueListenableBuilder(
                                                valueListenable: appStateClass.usersDataNotifiers.value[messageData.sender]!.notifier, 
                                                builder: ((context, userData, child) {
                                                  return CustomGroupMessage(
                                                    key: UniqueKey(),
                                                    chatID: chatID.value,
                                                    groupMessageData: messageData,
                                                    senderData: userData,
                                                    recipients: groupProfile.value.recipients,
                                                    previousMessageUploadTime: index + 1 == messages.length ? '' : messages[index + 1].notifier.value.uploadTime,
                                                  );
                                                })
                                              );
                                            })
                                          );
                                          
                                        }
                                      )),
                                      
                                    ]
                                  )
                                )
                              ]
                            )
                          ),
                          Container(
                            width: getScreenWidth(),
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.white, width: 1)),
                            ),
                            child: ValueListenableBuilder<List>(
                              valueListenable: mediasComponents,
                              builder: (context, mediasComponentsList, child) {
                                if(mediasComponentsList.isEmpty){
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                            onTap: (){pickImage(ImageSource.gallery, context: context);},
                                            behavior: HitTestBehavior.opaque,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.015, vertical: getScreenHeight() * 0.01),
                                              alignment: Alignment.centerLeft,
                                              child: Icon(Icons.photo, size: writePostIconSize,
                                                color: mediasComponents.value.length == maxMessageMediaCount ? Colors.grey : Colors.white
                                              ),
                                            )
                                          ),
                                          GestureDetector(
                                            onTap: (){pickImage(ImageSource.camera, context: context);},
                                            behavior: HitTestBehavior.opaque,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.015, vertical: getScreenHeight() * 0.01),
                                              alignment: Alignment.centerLeft,
                                              child: Icon(Icons.camera_alt_sharp, size: writePostIconSize,
                                                color: mediasComponents.value.length == maxMessageMediaCount ? Colors.grey : Colors.white
                                              ),
                                            )
                                          ),
                                          GestureDetector(
                                            onTap: () => _pickVideo(),
                                            behavior: HitTestBehavior.opaque,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.015, vertical: getScreenHeight() * 0.01),
                                              alignment: Alignment.centerLeft,
                                              child: Icon(Icons.video_file_sharp, size: writePostIconSize,
                                                color: mediasComponents.value.length == maxMessageMediaCount ? Colors.grey : Colors.white
                                              ),
                                            )
                                          ),
                                        ],
                                      )
                                    ]
                                  );
                                }else{
                                  return Column(
                                    children: [
                                      for(int i = 0; i < mediasComponentsList.length; i++)
                                      mediaComponentIndex(mediasComponentsList[i], i)
                                    ],
                                  );
                                }
                              }
                            ) 
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: verifyMessageFormat,
                            builder: (context, bool messageVerified, child){
                              return Stack(
                                children: [
                                  TextField(
                                    controller: messageController,
                                    decoration: generateMessageTextFieldDecoration('message'),
                                    minLines: messageDraftTextFieldMinLines,
                                    maxLines: messageDraftTextFieldMaxLines,
                                    maxLength: maxPostWordLimit,
                                    onChanged: (value){
                                      listenTextField(value);
                                      listenTextController(value);
                                    },
                                    onEditingComplete: (){
                                      listenTextController(messageController.text);
                                    },
                                  ),
                                  Positioned(
                                    bottom: 0, right: 0,
                                    child: ValueListenableBuilder<List>(
                                      valueListenable: mediasComponents,
                                      builder: (context, mediasComponentsList, child) {
                                        return ValueListenableBuilder(
                                          valueListenable: isLoading,
                                          builder: ((context, isLoadingValue, child) {
                                            return Container(
                                              width: getScreenWidth() * 0.125,
                                              color: Colors.transparent, 
                                              child: TextButton(
                                                onPressed: (messageVerified || mediasComponentsList.isNotEmpty) && !isLoadingValue ? () => sendGroupMessage() : null,
                                                child: const Icon(Icons.send, size: 25)
                                              ),
                                            );
                                          })
                                        );
                                      }
                                    )
                                  )
                                ],
                              );
                            }
                          ),
                        ]
                      );
                    })
                  );
                }
              );
            }
          ),
          ValueListenableBuilder(
            valueListenable: isLoading,
            builder: ((context, isLoadingValue, child) {
              if(isLoadingValue){
                return loadingPageWidget();
              }
              return Container();
            })
          )
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: displayFloatingBtn,
        builder: (BuildContext context, bool visible, Widget? child) {
          return Visibility(
            visible: visible,
            child: FloatingActionButton( 
              heroTag: UniqueKey(),
              onPressed: () {  
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 10),
                  curve:Curves.fastOutSlowIn
                );
              },
              child: const Icon(Icons.arrow_downward),
            )
          );
        }
      )
    );
  }
  
  bool get wantKeepAlive => true;
}