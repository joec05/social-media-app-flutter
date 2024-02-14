import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ChatsController {
  BuildContext context;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<ChatDataNotifier>> chats = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  ChatsController(
    this.context
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchChatsData(chats.value.length, false, false), actionDelayTime);
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

  void initializeSocketListeners() {
    socket.on("update-latest-private-message-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        bool chatDataFound = false;
        for(int i = 0; i < chats.value.length; i++){
          ChatDataClass chatData = chats.value[i].notifier.value;
          if(chatData.chatID == data['chatID']){
            chatDataFound = true;
            chats.value[i].notifier.value = ChatDataClass(
              chatData.chatID, chatData.type, chatData.recipient, ChatDataLatestMessageClass(
                data['messageID'], data['type'], data['sender'], data['content'], DateTime.now().toIso8601String()
              ), null, false
            );
          }
        }
        if(!chatDataFound){
          chats.value = [ChatDataNotifier(data['chatID'], ValueNotifier(
            ChatDataClass(data['chatID'], 'private', data['recipient'], ChatDataLatestMessageClass(
              data['messageID'], data['type'], data['sender'], data['content'], DateTime.now().toIso8601String()
            ), null, false))
          ), ...chats.value];
        }
      }
    });
    socket.on("remove-latest-private-message-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        for(int i = 0; i < chats.value.length; i++){
          ChatDataClass chatData = chats.value[i].notifier.value;
          if(chatData.chatID == data['chatID'] && chatData.latestMessageData.messageID == data['messageID']){
            chats.value[i].notifier.value = ChatDataClass(
              chatData.chatID, chatData.type, chatData.recipient, ChatDataLatestMessageClass(
                '', '', '', '', ''
              ), null, false
            );
          }
        }
      }
    });
    socket.on("update-latest-group-message-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        if(appStateRepo.usersDataNotifiers.value[data['senderData']['user_id']] != null){
          UserDataClass userData = appStateRepo.usersDataNotifiers.value[data['senderData']['user_id']]!.notifier.value;
          UserDataClass senderData = UserDataClass.fromMap(data['senderData']);
          if(userData.name != senderData.name){
            UserDataClass updatedUserData = UserDataClass(
              userData.userID, senderData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
              userData.birthDate, userData.bio, userData.mutedByCurrentID, userData.blockedByCurrentID, 
              userData.blocksCurrentID, userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
              userData.verified, userData.suspended, userData.deleted
            );
            updateUserData(updatedUserData);
          }
        }else{
          UserDataClass senderData = UserDataClass.fromMap(data['senderData']);
          UserDataClass updatedUserData = UserDataClass(
            senderData.userID, senderData.name, senderData.username, senderData.profilePicLink, senderData.dateJoined, 
            senderData.birthDate, senderData.bio, false, false, false, false, false, false, false, false, false
          );
          updateUserData(updatedUserData);
        }
        bool chatDataFound = false;
        for(int i = 0; i < chats.value.length; i++){
          ChatDataClass chatData = chats.value[i].notifier.value;
          if(chatData.chatID == data['chatID']){
            chatDataFound = true;
            chats.value[i].notifier.value = ChatDataClass(
              chatData.chatID, chatData.type, chatData.recipient, ChatDataLatestMessageClass(
                data['messageID'], data['type'], data['sender'], data['content'], DateTime.now().toIso8601String()
              ), chatData.groupProfileData, false
            );
          }
        }
        if(!chatDataFound){
          chats.value = [ChatDataNotifier(data['chatID'], ValueNotifier(
            ChatDataClass(data['chatID'], 'group', '', ChatDataLatestMessageClass(
              data['messageID'], data['type'], data['sender'], data['content'], DateTime.now().toIso8601String()
            ), GroupProfileClass(
              'Group ${data['chatID']}', defaultGroupChatProfilePicLink, '', List<String>.from(data['recipients'])
            ), false))
          ), ...chats.value];
        }
      }
    });
    socket.on("remove-latest-group-message-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        for(int i = 0; i < chats.value.length; i++){
          ChatDataClass chatData = chats.value[i].notifier.value;
          if(chatData.chatID == data['chatID'] && chatData.latestMessageData.messageID == data['messageID']){
            chats.value[i].notifier.value = ChatDataClass(
              chatData.chatID, chatData.type, chatData.recipient, ChatDataLatestMessageClass(
                '', '', '', '', ''
              ), chatData.groupProfileData, false
            );
          }
        }
      }
    });
    socket.on("update-latest-edit-group-profile-announcement-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        for(int i = 0; i < chats.value.length; i++){
          ChatDataClass chatData = chats.value[i].notifier.value;
          if(chatData.chatID == data['chatID']){
            chats.value[i].notifier.value = ChatDataClass(
              chatData.chatID, chatData.type, chatData.recipient, ChatDataLatestMessageClass(
                data['messageID'], data['type'], data['sender'], data['content'], DateTime.now().toIso8601String()
              ), 
              GroupProfileClass(
                data['newData']['name'], data['newData']['profilePicLink'], data['newData']['description'], chatData.groupProfileData!.recipients
              ), false
            );
          }
        }
      }
    });
    socket.on("update-latest-leave-group-announcement-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        for(int i = 0; i < chats.value.length; i++){
          ChatDataClass chatData = chats.value[i].notifier.value;
          if(chatData.chatID == data['chatID']){
            chats.value[i].notifier.value = ChatDataClass(
              chatData.chatID, chatData.type, chatData.recipient, ChatDataLatestMessageClass(
                data['messageID'], data['type'], data['sender'], data['content'], DateTime.now().toIso8601String()
              ),
              GroupProfileClass(
                chatData.groupProfileData!.name, chatData.groupProfileData!.profilePicLink, 
                chatData.groupProfileData!.description, List<String>.from(data['recipients'])
              ), false
            );
          }
        }
      }
    });
    socket.on("leave-group-sender-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        for(int i = 0; i < chats.value.length; i++){
          ChatDataClass chatData = chats.value[i].notifier.value;
          if(chatData.chatID == data['chatID']){
            chats.value[i].notifier.value = ChatDataClass(
              chatData.chatID, chatData.type, chatData.recipient, ChatDataLatestMessageClass(
                chatData.latestMessageData.messageID, chatData.latestMessageData.type,
                chatData.latestMessageData.sender, chatData.latestMessageData.content, 
                chatData.latestMessageData.uploadTime
              ),
              GroupProfileClass(
                chatData.groupProfileData!.name, chatData.groupProfileData!.profilePicLink, 
                chatData.groupProfileData!.description, List<String>.from(data['recipients'])
              ), chatData.deleted
            );
          }
        }
      }
    });
    socket.on("update-latest-add-users-to-group-announcement-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        for(int i = 0; i < chats.value.length; i++){
          ChatDataClass chatData = chats.value[i].notifier.value;
          if(chatData.chatID == data['chatID']){
            chats.value[i].notifier.value = ChatDataClass(
              chatData.chatID, chatData.type, chatData.recipient, ChatDataLatestMessageClass(
                data['messagesID'][data['messagesID'].length - 1], data['type'], data['sender'], 
                data['contentsList'][data['contentsList'].length - 1], DateTime.now().toIso8601String()
              ),
              GroupProfileClass(
                chatData.groupProfileData!.name, chatData.groupProfileData!.profilePicLink, 
                chatData.groupProfileData!.description, 
                List<String>.from([...data['recipients'], ...data['addedUsersID']])
              ), false
            );
          }
        }
      }
    });
    socket.on("add-new-chat-to-added-users-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        bool chatDataFound = false;
        for(int i = 0; i < chats.value.length; i++){
          ChatDataClass chatData = chats.value[i].notifier.value;
          if(chatData.chatID == data['chatID']){
            chatDataFound = true;
            chats.value[i].notifier.value = ChatDataClass(
              chatData.chatID, chatData.type, chatData.recipient, ChatDataLatestMessageClass(
                data['messagesID'][data['messagesID'].length - 1], data['type'], data['sender'], 
                data['contentsList'][data['contentsList'].length - 1], DateTime.now().toIso8601String()
              ),
              GroupProfileClass(
                data['groupProfileData']['name'], data['groupProfileData']['profilePicLink'], data['groupProfileData']['description'], 
                List<String>.from([...data['recipients'], ...data['addedUsersID']])
              ), false
            );
          }
        }
        if(!chatDataFound){
          chats.value = [...chats.value, ChatDataNotifier(data['chatID'], ValueNotifier(
            ChatDataClass(
              data['chatID'], 'group', '', ChatDataLatestMessageClass(
                data['messagesID'][data['messagesID'].length - 1], data['type'], data['sender'],
                data['contentsList'][data['contentsList'].length - 1], DateTime.now().toIso8601String()
              ),
              GroupProfileClass(
                data['groupProfileData']['name'], data['groupProfileData']['profilePicLink'], data['groupProfileData']['description'], 
                List<String>.from([...data['recipients'], ...data['addedUsersID']])
              ), false
            ))
          )];
        }
      }
    });
    socket.on("update-is-blocked-by-sender-id-user-data-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        UserDataClass userData = appStateRepo.usersDataNotifiers.value[data['blockedUserID']]!.notifier.value;
        UserDataClass updatedUserData = UserDataClass(
          userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
          userData.birthDate, userData.bio, userData.mutedByCurrentID, true, userData.blocksCurrentID, 
          userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
          userData.verified, userData.suspended, userData.deleted
        );
        updateUserData(updatedUserData);
      }
    });
    socket.on("update-block-sender-id-user-data-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        UserDataClass userData = appStateRepo.usersDataNotifiers.value[data['senderID']]!.notifier.value;
        UserDataClass updatedUserData = UserDataClass(
          userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
          userData.birthDate, userData.bio, userData.mutedByCurrentID, userData.blockedByCurrentID, true, 
          userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
          userData.verified, userData.suspended, userData.deleted
        );
        updateUserData(updatedUserData);
      }
    });
    socket.on("update-is-unblocked-by-sender-id-user-data-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        UserDataClass userData = appStateRepo.usersDataNotifiers.value[data['unblockedUserID']]!.notifier.value;
        UserDataClass updatedUserData = UserDataClass(
          userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
          userData.birthDate, userData.bio, userData.mutedByCurrentID, false, userData.blocksCurrentID, 
          userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
          userData.verified, userData.suspended, userData.deleted
        );
        updateUserData(updatedUserData);
      }
    });
    socket.on("update-unblock-sender-id-user-data-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        UserDataClass userData = appStateRepo.usersDataNotifiers.value[data['senderID']]!.notifier.value;
        UserDataClass updatedUserData = UserDataClass(
          userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
          userData.birthDate, userData.bio, userData.mutedByCurrentID, userData.blockedByCurrentID, false, 
          userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
          userData.verified, userData.suspended, userData.deleted
        );
        updateUserData(updatedUserData);
      }
    });
  }

  void dispose(){
    loadingState.dispose();
    chats.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchChatsData(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    if(mounted){
      dynamic res = await fetchDataRepo.fetchData(
        context, 
        RequestGet.fetchUserChats, 
        {
          'userID': appStateRepo.currentID,
          'currentLength': currentPostsLength,
          'paginationLimit': postsPaginationLimit,
          'maxFetchLimit': chatsServerFetchLimit
        }
      );
      if(mounted) {
        loadingState.value = LoadingState.loaded;
        if(res != null) {
          List userChatsData = res['userChatsData'];
          List usersProfileDatasList = res['recipientsProfileData'];
          List usersSocialsDatasList = res['recipientsSocialsData'];
          if(isRefreshing){
            chats.value = [];
          }
          canPaginate.value = res['canPaginate'];
          for(int i = 0; i < usersProfileDatasList.length; i++){
            Map userProfileData = usersProfileDatasList[i];
            UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
            UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
            updateUserData(userDataClass);
            updateUserSocials(userDataClass, userSocialClass);
          }
          for(int i = 0; i < userChatsData.length; i++){
            Map chatData = userChatsData[i];
            if(chatData['type'] == 'group' && chatData['latest_message_type'] != 'message'){
              String senderName = usersProfileDatasList.where((e) => e['user_id'] == chatData['latest_message_sender']).toList()[0]['name'];
              if(chatData['latest_message_type'] == 'edit_group_profile'){
                chatData['latest_message_content'] = '$senderName has edited the group profile';
              }else if(chatData['latest_message_type'] == 'leave_group'){
                chatData['latest_message_content'] = '$senderName has left the group';
              }else if(chatData['latest_message_type'].contains('add_users_to_group')){
                String addedUserID = chatData['latest_message_type'].replaceAll('add_users_to_group_', '');
                String addedUserName = usersProfileDatasList.where((e) => e['user_id'] == addedUserID).toList()[0]['name'];
                chatData['latest_message_content'] = '$senderName has added $addedUserName to the group';
              }
            } 
            chats.value = [...chats.value, ChatDataNotifier(
              chatData['chat_id'], ValueNotifier(
                ChatDataClass.fromMap(chatData)
              )
            )];
          }          
        }
      }
    }
  }

  Future<void> loadMoreChats() async{
    if(mounted){
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchChatsData(chats.value.length, false, true);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }

  Future<void> refresh() async{
    loadingState.value = LoadingState.refreshing;
    fetchChatsData(0, true, false);
  }

  void deletePrivateChat(String chatID) async{
    for(int i = 0; i < chats.value.length; i++){
      ChatDataClass chatData = chats.value[i].notifier.value;
      if(chatData.chatID == chatID && mounted){
        chats.value[i].notifier.value = ChatDataClass(
          chatData.chatID, chatData.type, chatData.recipient, ChatDataLatestMessageClass(
            '', '', '', '', ''
          ), null, true
        );
      }
    }
    await fetchDataRepo.fetchData(
      context, 
      RequestPatch.deletePrivateChat, 
      {
        'chatID': chatID,
        'currentID': appStateRepo.currentID,
      }
    );
  }

  void deleteGroupChat(String chatID) async{
    for(int i = 0; i < chats.value.length; i++){
      ChatDataClass chatData = chats.value[i].notifier.value;
      if(chatData.chatID == chatID && mounted){
        chats.value[i].notifier.value = ChatDataClass(
          chatData.chatID, chatData.type, chatData.recipient, ChatDataLatestMessageClass(
            '', '', '', '', ''
          ), chatData.groupProfileData, true
        );
      }
    }
    await fetchDataRepo.fetchData(
      context, 
      RequestPatch.deleteGroupChat, 
      {
        'chatID': chatID,
        'currentID': appStateRepo.currentID,
      }
    );
  }
}