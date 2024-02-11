import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';

class PrivateChatRoomWidget extends StatelessWidget {
  final String? chatID;
  final String recipient;
  const PrivateChatRoomWidget({super.key, required this.chatID, required this.recipient});

  @override
  Widget build(BuildContext context) {
    return _PrivateChatRoomWidgetStateful(chatID: chatID, recipient: recipient);
  }
}

class _PrivateChatRoomWidgetStateful extends StatefulWidget {
  final String? chatID;
  final String recipient;
  const _PrivateChatRoomWidgetStateful({required this.chatID, required this.recipient});

  @override
  State<_PrivateChatRoomWidgetStateful> createState() => _PrivateChatRoomWidgetStatefulState();
}

class _PrivateChatRoomWidgetStatefulState extends State<_PrivateChatRoomWidgetStateful> with AutomaticKeepAliveClientMixin, LifecycleListenerMixin{
  late PrivateChatController chatController;
  late UploadController uploadController;

  @override
  void initState(){
    super.initState();
    chatController = PrivateChatController(
      context, widget.chatID, widget.recipient
    );
    uploadController = UploadController(context);
    chatController.initializeController();
    uploadController.initializeController();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        titleSpacing: defaultAppBarTitleSpacing,
        title: ValueListenableBuilder(
          valueListenable: chatController.recipient, 
          builder: ((context, String recipientValue, child) {
            if(recipientValue.isNotEmpty){
              return ValueListenableBuilder(
                valueListenable: appStateClass.usersDataNotifiers.value[recipientValue]!.notifier, 
                builder: ((context, UserDataClass userData, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: (){
                          runDelay(() => Navigator.push(
                            context,
                            SliderRightToLeftRoute(
                              page: ProfilePageWidget(userID: userData.userID)
                            )
                          ), navigatorDelayTime);
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
                                              userData.profilePicLink
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
                                          Row(
                                            children: [
                                              Flexible(
                                              child: Text(
                                                  StringEllipsis.convertToEllipsis(userData.name),
                                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.bold)
                                                )
                                              ),
                                              userData.verified && !userData.suspended && !userData.deleted ?
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: iconsBesideNameProfileMargin
                                                    ),
                                                    Icon(Icons.verified_rounded, size: verifiedIconProfileWidgetSize, color: Colors.black),
                                                  ]
                                                )
                                              : Container(),
                                              userData.private && !userData.suspended && !userData.deleted ?
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: iconsBesideNameProfileMargin
                                                    ),
                                                    Icon(FontAwesomeIcons.lock, size: lockIconProfileWidgetSize, color: Colors.black),
                                                  ],
                                                )
                                              : Container(),
                                              userData.mutedByCurrentID && !userData.suspended && !userData.deleted ?
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: iconsBesideNameProfileMargin
                                                  ),
                                                  Icon(FontAwesomeIcons.volumeXmark, size: muteIconProfileWidgetSize, color: Colors.black), 
                                                ],
                                              )
                                            : Container(),
                                            ],
                                          ),
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
                })
              );
            }
            return Container();
          })
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: chatController.chatID,
            builder: (context, chatIDValue, child){
              if(chatIDValue != null){
                return PopupMenuButton(
                  onSelected: (result) {
                    if(result == 'Delete Chat'){
                      Navigator.pop(context, PrivateMessageActions.deleteChat);
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
          ListenableBuilder(
            listenable: Listenable.merge([
              chatController.paginationStatus,
              chatController.canPaginate,
              chatController.messages
            ]),
            builder: (context, child){
              PaginationStatus loadingStatusValue = chatController.paginationStatus.value;
              bool canPaginateValue = chatController.canPaginate.value;
              List<PrivateMessageNotifier> messagesList = chatController.messages.value;
              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        LoadMoreBottom(
                          addBottomSpace: canPaginateValue,
                          loadMore: () async{
                            if(canPaginateValue){
                              await chatController.loadMoreChats();
                            }
                          },
                          status: loadingStatusValue,
                          refresh: null,
                          child: CustomScrollView(
                            controller: chatController.scrollController,
                            shrinkWrap: true,
                            reverse: true,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: <Widget>[
                              SliverList(delegate: SliverChildBuilderDelegate(
                                childCount: messagesList.length,
                                (context, index) {
                                  return ValueListenableBuilder(
                                    valueListenable: messagesList[index].notifier, 
                                    builder: ((context, messageData, child) {
                                      return CustomPrivateMessage(
                                        key: UniqueKey(),
                                        chatID: chatController.chatID.value,
                                        privateMessageData: messageData,
                                        chatRecipient: chatController.recipient.value,
                                        previousMessageUploadTime: index + 1 == messagesList.length ?
                                         '' : messagesList[index + 1].notifier.value.uploadTime,
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
                  ValueListenableBuilder(
                    valueListenable: chatController.recipient, 
                    builder: ((context, recipientValue, child) {
                      if(recipientValue.isNotEmpty){
                        return ValueListenableBuilder(
                          valueListenable: appStateClass.usersDataNotifiers.value[recipientValue]!.notifier, 
                          builder: ((context, UserDataClass userData, child) {
                            if(userData.blockedByCurrentID || userData.blocksCurrentID || userData.suspended || userData.deleted){
                              return Container();
                            }
                            return Column(
                              children: [
                                Container(
                                  width: getScreenWidth(),
                                  decoration: const BoxDecoration(
                                    border: Border(top: BorderSide(color: Colors.white, width: 1)),
                                  ),
                                  child: ValueListenableBuilder<List>(
                                    valueListenable: uploadController.mediasComponents,
                                    builder: (context, mediasComponentsList, child) {
                                      if(mediasComponentsList.isEmpty){
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                GestureDetector(
                                                  onTap: () => uploadController.pickImage(ImageSource.gallery),
                                                  behavior: HitTestBehavior.opaque,
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: getScreenWidth() * 0.015, 
                                                      vertical: getScreenHeight() * 0.01
                                                    ),
                                                    alignment: Alignment.centerLeft,
                                                    child: Icon(Icons.photo, size: writePostIconSize,
                                                      color: uploadController.mediasComponents.value.length == maxMessageMediaCount ?
                                                        Colors.grey : Colors.white
                                                    ),
                                                  )
                                                ),
                                                GestureDetector(
                                                  onTap: () => uploadController.pickImage(ImageSource.camera),
                                                  behavior: HitTestBehavior.opaque,
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: getScreenWidth() * 0.015, 
                                                      vertical: getScreenHeight() * 0.01
                                                    ),
                                                    alignment: Alignment.centerLeft,
                                                    child: Icon(Icons.camera_alt_sharp, size: writePostIconSize,
                                                      color: uploadController.mediasComponents.value.length == maxMessageMediaCount ?
                                                        Colors.grey : Colors.white
                                                    ),
                                                  )
                                                ),
                                                GestureDetector(
                                                  onTap: () => uploadController..pickVideo(),
                                                  behavior: HitTestBehavior.opaque,
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: getScreenWidth() * 0.015, 
                                                      vertical: getScreenHeight() * 0.01
                                                    ),
                                                    alignment: Alignment.centerLeft,
                                                    child: Icon(Icons.video_file_sharp, size: writePostIconSize,
                                                      color: uploadController.mediasComponents.value.length == maxMessageMediaCount ?
                                                        Colors.grey : Colors.white
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
                                            uploadController.mediaComponentIndex(mediasComponentsList[i], i)
                                          ],
                                        );
                                      }
                                    }
                                  ) 
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable: uploadController.verifyTextFormat,
                                  builder: (context, bool messageVerified, child){
                                    return Stack(
                                      children: [
                                        TextField(
                                          controller: uploadController.textController,
                                          decoration: generateMessageTextFieldDecoration('message'),
                                          minLines: messageDraftTextFieldMinLines,
                                          maxLines: messageDraftTextFieldMaxLines,
                                          maxLength: maxPostWordLimit,
                                          onChanged: (value){
                                            uploadController.listenTextField(value);
                                            uploadController.listenTextController(value);
                                          },
                                          onEditingComplete: (){
                                            uploadController.listenTextController(
                                              uploadController.textController.text
                                            );
                                          },
                                        ),
                                        Positioned(
                                          bottom: 0, right: 0,
                                          child: ListenableBuilder(
                                            listenable: Listenable.merge([
                                              uploadController.mediasComponents,
                                              chatController.isLoading
                                            ]),
                                            builder: (context, child){
                                              List<Widget> mediasComponentsList = uploadController.mediasComponents.value;
                                              bool isLoadingValue = chatController.isLoading.value;
                                              return Container(
                                                width: getScreenWidth() * 0.125,
                                                color: Colors.transparent, 
                                                child: TextButton(
                                                  onPressed: (messageVerified || mediasComponentsList.isNotEmpty) && !isLoadingValue ?
                                                    () => uploadController.sendPrivateMessage(
                                                      chatController.chatID.value,
                                                      chatController.recipient.value
                                                    ) : null,
                                                  child: const Icon(Icons.send, size: 25)
                                                ),
                                              );
                                            }
                                          )
                                        )
                                      ],
                                    );
                                  }
                                ),
                              ],
                            );
                          })
                        );
                      }
                      return Container();
                    })
                  )
                ]
              );
            }
          ),
          ListenableBuilder(
            listenable: Listenable.merge([
              chatController.isLoading,
              uploadController.isUploading
            ]),
            builder: (context, child){
              bool isLoadingValue = chatController.isLoading.value;
              bool isUploadingValue = uploadController.isUploading.value;
              if(isLoadingValue || isUploadingValue){
                return loadingPageWidget();
              }
              return Container();
            }
          )
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: chatController.displayFloatingBtn,
        builder: (BuildContext context, bool visible, Widget? child) {
          return Visibility(
            visible: visible,
            child: FloatingActionButton( 
              heroTag: UniqueKey(),
              onPressed: () {  
                chatController.scrollController.animateTo(
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
  
  @override
  bool get wantKeepAlive => true;
}