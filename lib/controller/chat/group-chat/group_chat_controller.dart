import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';
import 'package:uuid/uuid.dart';

/// Controller which is used when the user enters a group chat
class GroupChatController {
   
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// The chatID of the group chat that will be passed to the controller. The group chat may have been
  /// created recently, which makes it possible for the chatID to be null
  String? chatIDValue;

  /// The list of recipients in the group chat
  List<String>? recipientsList;

  /// True if an API/Firebase/AppWrite function is running
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  /// Variable storing a list of the messages' data
  ValueNotifier<List<GroupMessageNotifier>> messages = ValueNotifier([]);

  /// Variable storing the group profile data
  ValueNotifier<GroupProfileClass> groupProfile = ValueNotifier(GroupProfileClass('', '', '', []));

  /// Variable storing the pagination status
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);

  /// True if pagination is still possible
  ValueNotifier<bool> canPaginate = ValueNotifier(false);

  /// Variable storing the chatID of the group chat. The variable is changeable.
  ValueNotifier<String?> chatID = ValueNotifier(null);

  /// Variable storing the new chatID. Null only if the chatID is not null.
  ValueNotifier<String?> newChatID = ValueNotifier(null);
  
  /// True if the floating button should appear
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);

  /// Scroll controller in which the value of displayFloatingBtn depends on
  final ScrollController scrollController = ScrollController();


  GroupChatController(
    this.context,
    this.chatIDValue,
    this.recipientsList
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    if(mounted){
      chatID.value = chatIDValue;
      newChatID.value = chatID.value == null ? const Uuid().v4() : null;
    }
    runDelay(() async => fetchGroupChatData(messages.value.length, false, false), actionDelayTime);
    initializeSocketListeners();
    scrollController.addListener(() {
      if(mounted){
        if(scrollController.position.pixels > animateToTopMinHeight){
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

  /// Initialize the socket listeners
  void initializeSocketListeners(){
    /// Listen to sockets to handle messages data
    String socketChatID = mounted ? chatID.value == null ? newChatID.value! : chatID.value! : '';
    socket.on("send-group-message-$socketChatID", ( data ) async{
      if(mounted && data != null){
        messages.value = [GroupMessageNotifier(data['messageID'], ValueNotifier(
          GroupMessageClass(
            data['messageID'], 'message', data['content'], data['sender'], DateTime.now().toIso8601String(), 
            await loadMediasDatas(context, data['mediasDatas']), []
          )
        )), ...messages.value];
      }
    });
    socket.on("delete-group-message-${appStateRepo.currentID}-$socketChatID", ( data ) async{
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
            await loadMediasDatas(context, data['mediasDatas']), []
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
            await loadMediasDatas(context, data['mediasDatas']), []
          )
        )), ...messages.value];
        groupProfile.value = GroupProfileClass(
          groupProfile.value.name, groupProfile.value.profilePicLink, 
          groupProfile.value.description, List<String>.from(data['recipients'])
        );
      }
    });
    socket.on("leave-group-sender-${appStateRepo.currentID}", ( data ) async{
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
            updateUserData(UserDataClass.fromMap(data['addedUsersData'][i]));
          }
        }
        for(int i = 0; i < data['contentsList'].length; i++){
          messages.value = [GroupMessageNotifier(data['messagesID'][i
          ], ValueNotifier(
            GroupMessageClass(
              data['messagesID'][i], data['type'], data['contentsList'][i], data['sender'], DateTime.now().toIso8601String(), 
              await loadMediasDatas(context, data['mediasDatas']), []
            )
          )), ...messages.value];
        }
        groupProfile.value = GroupProfileClass(
          groupProfile.value.name, groupProfile.value.profilePicLink, 
          groupProfile.value.description, List<String>.from([...data['recipients'], ...data['addedUsersID']])
        );
      }
    });
  }
  
  /// Dispose everything. Called at every page's dispose function
  void dispose(){
    isLoading.dispose();
    messages.dispose();
    groupProfile.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    chatID.dispose();
    newChatID.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchGroupChatData(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    if(mounted){
      try{
        if(recipientsList == null){
          isLoading.value = true;
          RequestGet call = isPaginating ? RequestGet.fetchGroupChatPagination : RequestGet.fetchGroupChat;
          dynamic res = await fetchDataRepo.fetchData(
            context, 
            call, 
            {
              'chatID': chatID.value,
              'currentID': appStateRepo.currentID,
              'currentLength': currentPostsLength,
              'paginationLimit': messagesPaginationLimit,
              'maxFetchLimit': messagesServerFetchLimit
            }
          );
          if(mounted){
            isLoading.value = false;
            if(res != null){
              if(res['message'] != 'blacklisted'){
                chatID.value = res['chatID'];
                List messagesData = res['messagesData'];
                List usersProfileDatasList = res['membersProfileData'];
                List usersSocialsDatasList = res['membersSocialsData'];
                if(!isPaginating){
                  List<String> groupMembersID = List<String>.from(res['groupMembersID']);
                  Map groupProfileData = res['groupProfileData'];
                  groupProfile.value = GroupProfileClass(
                    groupProfileData['name'], groupProfileData['profile_pic_link'], 
                    groupProfileData['description'], groupMembersID
                  );
                }
                if(isRefreshing){
                  messages.value = [];
                }
                canPaginate.value = res['canPaginate'];
                for(int i = 0; i < usersProfileDatasList.length; i++){
                  Map userProfileData = usersProfileDatasList[i];
                  UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
                  UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
                  updateUserData(userDataClass);
                  updateUserSocials(userDataClass, userSocialClass);
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
                  List<MediaDatasClass> newMediasDatas = await loadMediasDatas(context, jsonDecode(messageData['medias_datas']));
                  if(mounted){
                    messages.value = [...messages.value, GroupMessageNotifier(
                      messageData['message_id'], ValueNotifier(
                        GroupMessageClass.fromMap(messageData, newMediasDatas)
                      )
                    )];
                  }
                }
              }
            }
          }
        }else{
          if(mounted){
            groupProfile.value = GroupProfileClass(
              'You and ${recipientsList!.length - 1} others', 
              defaultGroupChatProfilePicLink, 
              '', 
              recipientsList!
            );
          }
        }
      } catch (_) {
        if(mounted){
          isLoading.value = false;
          handler.displaySnackbar(
            context, 
            SnackbarType.error,
            tErr.api
          );
        }
      }
    }
  }

  Future<void> loadMoreChats() async{
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
  }
}