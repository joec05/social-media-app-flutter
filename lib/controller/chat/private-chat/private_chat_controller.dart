import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class PrivateChatController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// The chatID of the group chat that will be passed to the controller. The group chat may have been
  /// created recently, which makes it possible for the chatID to be null
  String? chatIDValue;

  /// The recipient in the private chat passed to the controller. This variable is set to be read-only,
  /// it is not changeable
  final String recipientValue;
  
  /// True if an API/Firebase/AppWrite function is running
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  /// Variable storing a list of the messages' data
  ValueNotifier<List<PrivateMessageNotifier>> messages = ValueNotifier([]);

  /// Variable storing the pagination status
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);

  /// True if pagination is still possible
  ValueNotifier<bool> canPaginate = ValueNotifier(false);

  /// Variable storing the chatID of the group chat. The variable is changeable.
  ValueNotifier<String?> chatID = ValueNotifier(null);

  /// The recipient in the private chat passed to the controller. This variable is changeable
  ValueNotifier<String> recipient = ValueNotifier('');

  /// True if the floating button should appear
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);

  /// Scroll controller in which the value of displayFloatingBtn depends on
  final ScrollController scrollController = ScrollController();

  PrivateChatController(
    this.context,
    this.chatIDValue,
    this.recipientValue
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    if(mounted){
      chatID.value = chatIDValue;
      recipient.value = recipientValue;
    }
    runDelay(() async => fetchPrivateChatData(messages.value.length, false), actionDelayTime);
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
  void initializeSocketListeners() {
    socket.on("send-private-message-${appStateRepo.currentID}-${recipient.value}", ( data ) async{
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

  /// Dispose everything. Called at every page's dispose function
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

  /// Called when controller is initialized or when the page is paginating
  Future<void> fetchPrivateChatData(int currentPostsLength, bool isPaginating) async{
    if(mounted){
      try {
        isLoading.value = true;

        /// Determine the endpoint based on whether the page is paginating or not
        RequestGet call = isPaginating ? RequestGet.fetchPrivateChatPagination : RequestGet.fetchPrivateChat;
        
        /// Call the API to fetch the private chat data. This includes messages and recipient profile
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

          /// API call is successful
          if(res != null){

            if(res['message'] != 'blacklisted'){

              /// Update the chatID value based on the data fetched from the API
              chatID.value = res['chatID'];

              List messagesData = res['messagesData'];
              List usersProfileDatasList = res['membersProfileData'];
              List usersSocialsDatasList = res['membersSocialsData'];
              
              /// The API will also determine whether further pagination is still possible or not
              canPaginate.value = res['canPaginate'];

              /// Update the user data of the private chat members to the application state repository
              for(int i = 0; i < usersProfileDatasList.length; i++){
                Map userProfileData = usersProfileDatasList[i];
                UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
                UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
              }

              /// Handle the messages data fetched by the API
              for(int i = 0; i < messagesData.length; i++){
                Map messageData = messagesData[i];

                /// Load the media attached to the message
                List<MediaDatasClass> newMediasDatas = await loadMediasDatas(context, jsonDecode(messageData['medias_datas']));

                /// Convert the message data to a model class and add it to the messages list variable
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

  /// Called when the user scrolled to the top and the page is still able to paginate
  Future<void> loadMoreChats() async{
    if(mounted){

      /// Set the paginationStatus to loading and run a timer delay before calling the function
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchPrivateChatData(messages.value.length, true);
        if(mounted){

          /// Set the paginationStatus to loaded
          paginationStatus.value = PaginationStatus.loaded;
          
        }
      });

    }
  }
}