import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class PrivateChatController {
  BuildContext context;
  String? chatIDValue;
  String recipientValue;
  ValueNotifier<List<PrivateMessageNotifier>> messages = ValueNotifier([]);
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late ValueNotifier<String?> chatID = ValueNotifier(null);
  late ValueNotifier<String> recipient = ValueNotifier('');
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  PrivateChatController(
    this.context,
    this.chatIDValue,
    this.recipientValue
  );

  bool get mounted => context.mounted;

  void initializeController(){
    if(mounted){
      chatID.value = chatIDValue;
      recipient.value = recipientValue;
    }
    runDelay(() async => fetchPrivateChatData(messages.value.length, false, false), actionDelayTime);
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
    socket.on("send-private-message-${appStateRepo.currentID}-$recipientValue", ( data ) async{
      if(mounted && data != null){
        messages.value = [PrivateMessageNotifier(data['messageID'], ValueNotifier(
          PrivateMessageClass(
            data['messageID'], 'message', data['content'], data['sender'], DateTime.now().toIso8601String(), 
            await loadMediasDatas(context, data['mediasDatas']), []
          )
        )), ...messages.value];
      }
    });
    socket.on("send-private-message-$recipientValue-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        messages.value = [PrivateMessageNotifier(data['messageID'], ValueNotifier(
          PrivateMessageClass(
            data['messageID'], 'message', data['content'], data['sender'], DateTime.now().toIso8601String(), 
            await loadMediasDatas(context, data['mediasDatas']), []
          )
        )), ...messages.value];
      }
    });
    socket.on("delete-private-message-${appStateRepo.currentID}-${recipient.value}", ( data ) async{
      if(mounted && data != null){
        for(int i = 0; i < messages.value.length; i++){
          PrivateMessageClass privateMessageData = messages.value[i].notifier.value;
          if(privateMessageData.messageID == data['messageID']){
            var messagesList = [...messages.value];
            messagesList.removeAt(i);
            messages.value = [...messagesList];
            break;
          }
        }
      }
    });
    socket.on("delete-private-message-for-all-${appStateRepo.currentID}-${recipient.value}", ( data ) async{
      if(mounted && data != null){
        for(int i = 0; i < messages.value.length; i++){
          PrivateMessageClass privateMessageData = messages.value[i].notifier.value;
          if(privateMessageData.messageID == data['messageID']){
            var messagesList = [...messages.value];
            messagesList.removeAt(i);
            messages.value = [...messagesList];
            break;
          }
        }
      }
    });
    socket.on("delete-private-message-for-all-${recipient.value}-${appStateRepo.currentID}", ( data ) async{
      if(mounted && data != null){
        for(int i = 0; i < messages.value.length; i++){
          PrivateMessageClass privateMessageData = messages.value[i].notifier.value;
          if(privateMessageData.messageID == data['messageID']){
            var messagesList = [...messages.value];
            messagesList.removeAt(i);
            messages.value = [...messagesList];
            break;
          }
        }
      }
    });
  }

  void dispose(){
    isLoading.dispose();
    messages.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    chatID.dispose();
    recipient.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchPrivateChatData(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    if(mounted){
      try {
        isLoading.value = true;
        RequestGet call = isPaginating ? RequestGet.fetchPrivateChatPagination : RequestGet.fetchPrivateChat;
        dynamic res = await fetchDataRepo.fetchData(
          context, 
          call, 
          {
            'chatID': chatID.value,
            'currentID': appStateRepo.currentID,
            'recipient': recipient.value,
            'currentLength': currentPostsLength,
            'paginationLimit': messagesPaginationLimit,
            'maxFetchLimit': messagesServerFetchLimit
          }
        );
        if(mounted){
          isLoading.value = false;
          if(res != null){
            print(res);
            if(res['message'] != 'blacklisted'){
              chatID.value = res['chatID'];
              List messagesData = res['messagesData'];
              List usersProfileDatasList = res['membersProfileData'];
              List usersSocialsDatasList = res['membersSocialsData'];
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
                List<MediaDatasClass> newMediasDatas = await loadMediasDatas(context, jsonDecode(messageData['medias_datas']));
                messages.value = [...messages.value, PrivateMessageNotifier(
                  messageData['message_id'], ValueNotifier(
                    PrivateMessageClass.fromMap(messageData, newMediasDatas)
                  )
                )];
              }
            }
          }
        }
      } catch (_) {
        if(mounted){
          isLoading.value = false;
          handler.displaySnackbar(
            context, 
            SnackbarType.error,
            tErr.unknown
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
        await fetchPrivateChatData(messages.value.length, false, true);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }
}