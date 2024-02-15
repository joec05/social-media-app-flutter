import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/global_files.dart';

class CustomChatWidget extends StatefulWidget {
  final ChatDataClass chatData;
  final UserDataClass? recipientData;
  final UserSocialClass? recipientSocials;
  final Function deleteChat;
  final bool skeletonMode;

  const CustomChatWidget({
    super.key, required this.chatData, required this.recipientData, required this.recipientSocials,
    required this.deleteChat, required this.skeletonMode
  });

  @override
  CustomChatWidgetState createState() => CustomChatWidgetState();
}

class CustomChatWidgetState extends State<CustomChatWidget> {
  late ChatDataClass chatData;
  late UserDataClass? recipientData;
  late UserSocialClass? recipientSocials;

  @override
  void initState(){
    super.initState();
    chatData = widget.chatData;
    recipientData = widget.recipientData;
    recipientSocials = widget.recipientSocials;
  }

  @override void dispose(){
    super.dispose();
  }

  void navigateToGroupChat() async{
    runDelay(()async {
      var action = await Navigator.push(
        context,
        SliderRightToLeftRoute(
          page: GroupChatRoomWidget(chatID: chatData.chatID, recipients: null)
        )
      );
      if(action != null && action == GroupMessageActions.deleteChat){
        widget.deleteChat(chatData.chatID);
      }
    }, navigatorDelayTime);
  }

  void navigateToPrivateChat() async{
    runDelay(()async {
      var action = await Navigator.push(
        context,
        SliderRightToLeftRoute(
          page: PrivateChatRoomWidget(chatID: chatData.chatID, recipient: chatData.recipient)
        )
      );
      if(action != null && action == PrivateMessageActions.deleteChat){
        widget.deleteChat(chatData.chatID);
      }
    }, navigatorDelayTime);
  }

  @override
  Widget build(BuildContext context) {
    if(!widget.skeletonMode){
      String latestMessageSender = chatData.latestMessageData.sender;
      bool senderIsCurrentID = false;
      String subject = '';
      if(chatData.latestMessageData.type == 'message'){
        senderIsCurrentID = latestMessageSender == appStateRepo.currentID;
        subject = senderIsCurrentID ? 'You' : appStateRepo.usersDataNotifiers.value[latestMessageSender]!.notifier.value.name;
      }
      if(chatData.deleted){
        return Container();
      }
      if(chatData.type == 'private'){
        if(recipientData!.blockedByCurrentID || recipientData!.blocksCurrentID || recipientData!.suspended || recipientData!.deleted){
          return Container();
        }
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
          color: Theme.of(context).cardColor,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                navigateToPrivateChat();
              },
              splashFactory: InkRipple.splashFactory,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: (){
                                  runDelay(()async => await Navigator.push(
                                    context,
                                    SliderRightToLeftRoute(
                                      page: ProfilePageWidget(userID: recipientData!.userID)
                                    )
                                  ), navigatorDelayTime);
                                },
                                child: Container(
                                  width: getScreenWidth() * 0.1, height: getScreenWidth() * 0.1,
                                  decoration: BoxDecoration(
                                    border: Border.all(width: 2),
                                    borderRadius: BorderRadius.circular(100),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        recipientData!.profilePicLink
                                      ), fit: BoxFit.fill
                                    )
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: getScreenWidth() * 0.02
                              ),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Flexible(child: Text(StringEllipsis.convertToEllipsis(recipientData!.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: defaultTextFontSize * 0.9, fontWeight: FontWeight.bold))),
                                        recipientData!.verified && !recipientData!.suspended && !recipientData!.deleted ?
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: iconsBesideNameProfileMargin
                                              ),
                                              Icon(Icons.verified_rounded, size: verifiedIconProfileWidgetSize),
                                            ]
                                          )
                                        : Container(),
                                        recipientData!.private && !recipientData!.suspended && !recipientData!.deleted ?
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: iconsBesideNameProfileMargin
                                              ),
                                              Icon(FontAwesomeIcons.lock, size: lockIconProfileWidgetSize),
                                            ],
                                          )
                                        : Container(),
                                        recipientData!.mutedByCurrentID && !recipientData!.suspended && !recipientData!.deleted ?
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: iconsBesideNameProfileMargin
                                              ),
                                              Icon(FontAwesomeIcons.volumeXmark, size: muteIconProfileWidgetSize),
                                            ],
                                          )
                                        : Container()
                                      ],
                                    ),
                                    Text(chatData.latestMessageData.content.isEmpty ? '' : '$subject: ${chatData.latestMessageData.content}', maxLines: 3, style: TextStyle(fontSize: defaultTextFontSize * 0.8, color: Colors.teal)),
                                    Text(chatData.latestMessageData.uploadTime.isNotEmpty ? getTimeDifference(chatData.latestMessageData.uploadTime) : '', style: TextStyle(fontSize: defaultTextFontSize * 0.675)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]
                )
              )
            )
          )
        );
      }else{
        UserDataClass? senderProfileData = chatData.latestMessageData.messageID.isNotEmpty ? appStateRepo.usersDataNotifiers.value[chatData.latestMessageData.sender]!.notifier.value : null;
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
          color: Theme.of(context).cardColor,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (){
                navigateToGroupChat();
              },
              splashFactory: InkRipple.splashFactory,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  runDelay(() => Navigator.push(
                                    context,
                                    SliderRightToLeftRoute(
                                      page: GroupProfilePageWidget(chatID: chatData.chatID, groupProfileData: chatData.groupProfileData!)
                                    ),
                                  ), navigatorDelayTime);
                                },
                                child: Container(
                                  width: getScreenWidth() * 0.1, height: getScreenWidth() * 0.1,
                                  decoration: BoxDecoration(
                                    border: Border.all(width: 2),
                                    borderRadius: BorderRadius.circular(100),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        chatData.groupProfileData!.profilePicLink
                                      ), fit: BoxFit.fill
                                    )
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: getScreenWidth() * 0.02
                              ),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            StringEllipsis.convertToEllipsis(chatData.groupProfileData!.name),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: defaultTextFontSize * 0.9, fontWeight: FontWeight.bold),
                                            softWrap: true,
                                          )
                                        )
                                      ],
                                    ),
                                    Text(
                                      senderProfileData == null ? '' : 
                                      senderProfileData.blockedByCurrentID || senderProfileData.blocksCurrentID ?
                                        'This message is unavailable'
                                      :
                                        chatData.latestMessageData.type == 'message' ? '$subject: ${chatData.latestMessageData.content}' : chatData.latestMessageData.content,
                                      maxLines: 3, style: TextStyle(fontSize: defaultTextFontSize * 0.8, color: Colors.teal)
                                    ),
                                    Text(chatData.latestMessageData.uploadTime.isNotEmpty ? getTimeDifference(chatData.latestMessageData.uploadTime) : '', style: TextStyle(fontSize: defaultTextFontSize * 0.675)),
                                  ],
                                
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ),
                  ]
                )
              )
            )
          )
        );
      }
    }else{
      return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
        color: Theme.of(context).cardColor,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashFactory: InkRipple.splashFactory,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: getScreenWidth() * 0.05,
                              backgroundImage: NetworkImage(defaultUserProfilePicLink),
                            ),
                            SizedBox(
                              width: getScreenWidth() * 0.02
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Card(
                                          margin: EdgeInsets.zero,
                                          child: SizedBox(
                                            height: getScreenHeight() * 0.0275,
                                            width: double.infinity,
                                          )
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: getScreenHeight() * 0.005),
                                  Card(
                                    margin: EdgeInsets.zero,
                                    child: SizedBox(
                                      height: getScreenHeight() * 0.0225,
                                      width: double.infinity,
                                    )
                                  ),
                                  SizedBox(height: getScreenHeight() * 0.005),
                                  Card(
                                    margin: EdgeInsets.zero,
                                    child: SizedBox(
                                      height: getScreenHeight() * 0.02,
                                      width: double.infinity,
                                    )
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]
              )
            )
          )
        )
      );
    }
  }

}