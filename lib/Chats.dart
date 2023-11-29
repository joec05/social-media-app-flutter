import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/SearchChatUsers.dart';
import 'package:social_media_app/class/ChatDataClass.dart';
import 'package:social_media_app/class/ChatDataLatestMessageClass.dart';
import 'package:social_media_app/class/GroupProfileClass.dart';
import 'package:social_media_app/class/ChatDataNotifier.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/custom/CustomChatWidget.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/redux/reduxLibrary.dart';
import 'package:social_media_app/socket/main.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import 'class/UserDataNotifier.dart';
import 'class/UserSocialNotifier.dart';
import 'custom/CustomPagination.dart';

var dio = Dio();

class ChatsWidget extends StatelessWidget {
  const ChatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ChatsWidgetStateful();
  }
}

class _ChatsWidgetStateful extends StatefulWidget {
  const _ChatsWidgetStateful();

  @override
  State<_ChatsWidgetStateful> createState() => _ChatsWidgetStatefulState();
}

class _ChatsWidgetStatefulState extends State<_ChatsWidgetStateful> with AutomaticKeepAliveClientMixin, LifecycleListenerMixin{
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<ChatDataNotifier>> chats = ValueNotifier([]);
  ValueNotifier<LoadingStatus> loadingChatsStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    runDelay(() async => fetchChatsData(chats.value.length, false, false), actionDelayTime);
    socket.on("update-latest-private-message-${fetchReduxDatabase().currentID}", ( data ) async{
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
    socket.on("remove-latest-private-message-${fetchReduxDatabase().currentID}", ( data ) async{
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
    socket.on("update-latest-group-message-${fetchReduxDatabase().currentID}", ( data ) async{
      if(mounted && data != null){
        if(fetchReduxDatabase().usersDatasNotifiers.value[data['senderData']['user_id']] != null){
          UserDataClass userData = fetchReduxDatabase().usersDatasNotifiers.value[data['senderData']['user_id']]!.notifier.value;
          UserDataClass senderData = UserDataClass.fromMap(data['senderData']);
          if(userData.name != senderData.name){
            UserDataClass updatedUserData = UserDataClass(
              userData.userID, senderData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
              userData.birthDate, userData.bio, userData.mutedByCurrentID, userData.blockedByCurrentID, 
              userData.blocksCurrentID, userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
              userData.verified, userData.suspended, userData.deleted
            );
            updateUserData(updatedUserData, context);
          }
        }else{
          UserDataClass senderData = UserDataClass.fromMap(data['senderData']);
          UserDataClass updatedUserData = UserDataClass(
            senderData.userID, senderData.name, senderData.username, senderData.profilePicLink, senderData.dateJoined, 
            senderData.birthDate, senderData.bio, false, false, false, false, false, false, false, false, false
          );
          updateUserData(updatedUserData, context);
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
    socket.on("remove-latest-group-message-${fetchReduxDatabase().currentID}", ( data ) async{
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
    socket.on("update-latest-edit-group-profile-announcement-${fetchReduxDatabase().currentID}", ( data ) async{
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
    socket.on("update-latest-leave-group-announcement-${fetchReduxDatabase().currentID}", ( data ) async{
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
    socket.on("leave-group-sender-${fetchReduxDatabase().currentID}", ( data ) async{
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
    socket.on("update-latest-add-users-to-group-announcement-${fetchReduxDatabase().currentID}", ( data ) async{
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
    socket.on("add-new-chat-to-added-users-${fetchReduxDatabase().currentID}", ( data ) async{
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
    socket.on("update-is-blocked-by-sender-id-user-data-${fetchReduxDatabase().currentID}", ( data ) async{
      if(mounted && data != null){
        UserDataClass userData = fetchReduxDatabase().usersDatasNotifiers.value[data['blockedUserID']]!.notifier.value;
        UserDataClass updatedUserData = UserDataClass(
          userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
          userData.birthDate, userData.bio, userData.mutedByCurrentID, true, userData.blocksCurrentID, 
          userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
          userData.verified, userData.suspended, userData.deleted
        );
        updateUserData(updatedUserData, context);
      }
    });
    socket.on("update-block-sender-id-user-data-${fetchReduxDatabase().currentID}", ( data ) async{
      if(mounted && data != null){
        UserDataClass userData = fetchReduxDatabase().usersDatasNotifiers.value[data['senderID']]!.notifier.value;
        UserDataClass updatedUserData = UserDataClass(
          userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
          userData.birthDate, userData.bio, userData.mutedByCurrentID, userData.blockedByCurrentID, true, 
          userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
          userData.verified, userData.suspended, userData.deleted
        );
        updateUserData(updatedUserData, context);
      }
    });
    socket.on("update-is-unblocked-by-sender-id-user-data-${fetchReduxDatabase().currentID}", ( data ) async{
      if(mounted && data != null){
        UserDataClass userData = fetchReduxDatabase().usersDatasNotifiers.value[data['unblockedUserID']]!.notifier.value;
        UserDataClass updatedUserData = UserDataClass(
          userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
          userData.birthDate, userData.bio, userData.mutedByCurrentID, false, userData.blocksCurrentID, 
          userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
          userData.verified, userData.suspended, userData.deleted
        );
        updateUserData(updatedUserData, context);
      }
    });
    socket.on("update-unblock-sender-id-user-data-${fetchReduxDatabase().currentID}", ( data ) async{
      if(mounted && data != null){
        UserDataClass userData = fetchReduxDatabase().usersDatasNotifiers.value[data['senderID']]!.notifier.value;
        UserDataClass updatedUserData = UserDataClass(
          userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
          userData.birthDate, userData.bio, userData.mutedByCurrentID, userData.blockedByCurrentID, false, 
          userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
          userData.verified, userData.suspended, userData.deleted
        );
        updateUserData(updatedUserData, context);
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
    chats.dispose();
    loadingChatsStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchChatsData(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = jsonEncode({
          'userID': fetchReduxDatabase().currentID,
          'currentLength': currentPostsLength,
          'paginationLimit': postsPaginationLimit,
          'maxFetchLimit': chatsServerFetchLimit
        }); 
        var res = await dio.get('$serverDomainAddress/users/fetchUserChats', data: stringified);
        if(res.data.isNotEmpty && mounted){
          if(res.data['message'] == 'Successfully fetched data'){
            List userChatsData = res.data['userChatsData'];
            List usersProfileDatasList = res.data['recipientsProfileData'];
            List usersSocialsDatasList = res.data['recipientsSocialsData'];
            
            if(isRefreshing && mounted){
              chats.value = [];
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
              if(mounted){
                chats.value = [...chats.value, ChatDataNotifier(
                  chatData['chat_id'], ValueNotifier(
                    ChatDataClass.fromMap(chatData)
                  )
                )];
              }
            }
          }
          if(mounted){
            isLoading.value = false;
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
        loadingChatsStatus.value = LoadingStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchChatsData(chats.value.length, false, true);
          if(mounted){
            loadingChatsStatus.value = LoadingStatus.loaded;
          }
        });
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<void> refresh() async{
    fetchChatsData(0, true, false);
  }

  void deletePrivateChat(String chatID) async{
    try {
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
      String stringified = jsonEncode({
        'chatID': chatID,
        'currentID': fetchReduxDatabase().currentID,
      });
      var res = await dio.patch('$serverDomainAddress/users/deletePrivateChat', data: stringified);
      if(res.data.isNotEmpty){
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  void deleteGroupChat(String chatID) async{
    try {
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
      String stringified = jsonEncode({
        'chatID': chatID,
        'currentID': fetchReduxDatabase().currentID,
      });
      var res = await dio.patch('$serverDomainAddress/users/deleteGroupChat', data: stringified);
      if(res.data.isNotEmpty){
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: displayFloatingBtn,
            builder: (BuildContext context, bool visible, Widget? child) {
              return Column(
                children: [
                  Visibility(
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
                      child: const Icon(Icons.arrow_upward),
                    )
                  ),
                  SizedBox(height: getScreenHeight() * 0.02),
                ],
              );
            }
          ),
          FloatingActionButton( 
            heroTag: 'search users',
            onPressed: () {
              runDelay(() => Navigator.push(
                context,
                SliderRightToLeftRoute(
                  page: const SearchChatUsersWidget()
                )
              ), navigatorDelayTime);
            },
            backgroundColor: Colors.lightBlue,
            child: const Icon(Icons.mail),
          ),
        ],
      ),
      body: Stack(
        children: [
          StoreConnector<AppState, ValueNotifier<Map<String, UserDataNotifier>>>(
            converter: (store) => store.state.usersDatasNotifiers,
            builder: (context, ValueNotifier<Map<String, UserDataNotifier>> usersDatasNotifiers){
              return StoreConnector<AppState, ValueNotifier<Map<String, UserSocialNotifier>>>(
                converter: (store) => store.state.usersSocialsNotifiers,
                builder: (context, ValueNotifier<Map<String, UserSocialNotifier>> usersSocialsNotifiers){
                  return ValueListenableBuilder(
                    valueListenable: loadingChatsStatus,
                    builder: (context, loadingStatusValue, child){
                      return ValueListenableBuilder(
                        valueListenable: canPaginate,
                        builder: (context, canPaginateValue, child){
                          return ValueListenableBuilder(
                            valueListenable: chats, 
                            builder: ((context, chats, child) {
                              return LoadMoreBottom(
                                addBottomSpace: canPaginateValue,
                                loadMore: () async{
                                  if(canPaginateValue){
                                    await loadMoreChats();
                                  }
                                },
                                status: loadingStatusValue,
                                refresh: refresh,
                                child: CustomScrollView(
                                  controller: _scrollController,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  slivers: <Widget>[
                                    SliverList(delegate: SliverChildBuilderDelegate(
                                      childCount: chats.length, 
                                      (context, index) {
                                        return ValueListenableBuilder(
                                          valueListenable: chats[index].notifier, 
                                          builder: ((context, chatData, child) {
                                            if(chatData.type == 'private'){
                                              return ValueListenableBuilder(
                                                valueListenable: usersDatasNotifiers.value[chatData.recipient]!.notifier, 
                                                builder: ((context, userData, child) {
                                                  return ValueListenableBuilder(
                                                    valueListenable: usersSocialsNotifiers.value[chatData.recipient]!.notifier, 
                                                    builder: ((context, userSocials, child) {
                                                      return CustomChatWidget(
                                                        chatData: chatData, recipientData: userData, 
                                                        recipientSocials: userSocials, key: UniqueKey(),
                                                        deleteChat: deletePrivateChat
                                                      );
                                                    })
                                                  );
                                                })
                                              );
                                            }else{
                                              if(chatData.groupProfileData!.recipients.contains(fetchReduxDatabase().currentID)){
                                                if(chatData.latestMessageData.messageID.isEmpty){
                                                  return CustomChatWidget(
                                                    chatData: chatData, recipientData: null, 
                                                    recipientSocials: null, key: UniqueKey(),
                                                    deleteChat: deleteGroupChat
                                                  );
                                                }
                                                
                                                return ValueListenableBuilder(
                                                  valueListenable: usersDatasNotifiers.value[chatData.latestMessageData.sender]!.notifier, 
                                                  builder: ((context, userData, child) {
                                                    return ValueListenableBuilder(
                                                      valueListenable: usersSocialsNotifiers.value[chatData.latestMessageData.sender]!.notifier, 
                                                      builder: ((context, userSocials, child) {
                                                        return CustomChatWidget(
                                                          chatData: chatData, recipientData: null, 
                                                          recipientSocials: null, key: UniqueKey(),
                                                          deleteChat: deleteGroupChat
                                                        );
                                                      })
                                                    );
                                                  })
                                                );
                                              }
                                            }
                                            return Container();
                                          })
                                        );
                                        
                                      }
                                    ))
                                  ]
                                )
                              );
                            })
                          );
                        }
                      );
                    }
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
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}