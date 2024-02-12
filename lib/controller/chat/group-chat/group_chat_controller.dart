import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';
import 'package:uuid/uuid.dart';

class GroupChatController {
  BuildContext context;
  String? chatIDValue;
  List<String>? recipientsList;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<GroupMessageNotifier>> messages = ValueNotifier([]);
  ValueNotifier<GroupProfileClass> groupProfile = ValueNotifier(GroupProfileClass('', '', '', []));
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late ValueNotifier<String?> chatID = ValueNotifier(null);
  ValueNotifier<String?> newChatID = ValueNotifier(null);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  GroupChatController(
    this.context,
    this.chatIDValue,
    this.recipientsList
  );

  bool get mounted => context.mounted;

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

  void initializeSocketListeners(){
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
              'currentID': appStateClass.currentID,
              'currentLength': currentPostsLength,
              'paginationLimit': messagesPaginationLimit,
              'maxFetchLimit': messagesServerFetchLimit
            }
          );
          if(mounted){
            isLoading.value = false;
            if(res != null){
              if(res.data['message'] != 'blacklisted'){
                chatID.value = res.data['chatID'];
                List messagesData = res.data['messagesData'];
                List usersProfileDatasList = res.data['membersProfileData'];
                List usersSocialsDatasList = res.data['membersSocialsData'];
                if(!isPaginating){
                  List<String> groupMembersID = List<String>.from(res.data['groupMembersID']);
                  Map groupProfileData = res.data['groupProfileData'];
                  groupProfile.value = GroupProfileClass(
                    groupProfileData['name'], groupProfileData['profile_pic_link'], 
                    groupProfileData['description'], groupMembersID
                  );
                }
                if(isRefreshing){
                  messages.value = [];
                }
                canPaginate.value = res.data['canPaginate'];
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