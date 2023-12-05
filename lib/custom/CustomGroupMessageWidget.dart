// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import '../ProfilePage.dart';
import '../class/MediaDataClass.dart';
import '../class/GroupMessageClass.dart';
import '../class/UserDataClass.dart';
import '../socket/main.dart';
import 'CustomButton.dart';
import 'CustomTextSpan.dart';

class CustomGroupMessage extends StatefulWidget {
  final String? chatID;
  final GroupMessageClass groupMessageData;
  final UserDataClass senderData;
  final List<String> recipients;
  final String previousMessageUploadTime;

  const CustomGroupMessage({
    super.key,
    required this.chatID,
    required this.groupMessageData,
    required this.senderData,
    required this.recipients,
    required this.previousMessageUploadTime
  });

  @override
  _CustomGroupMessageState createState() => _CustomGroupMessageState();
  
}

var dio = Dio();

class _CustomGroupMessageState extends State<CustomGroupMessage> {
  late GroupMessageClass groupMessageData;
  late UserDataClass senderData;

  @override
  void initState(){
    super.initState();
    groupMessageData = widget.groupMessageData;
    senderData = widget.senderData;
  }

  @override void dispose(){
    super.dispose();
  }

  void deleteGroupMessage() async{
    try {
      socket.emit("delete-group-message-to-server", {
        'chatID': widget.chatID,
        'messageID': groupMessageData.messageID,
        'currentID': appStateClass.currentID,
      });
      String stringified = jsonEncode({
        'chatID': widget.chatID,
        'messageID': groupMessageData.messageID,
        'currentID': appStateClass.currentID,
      });
      var res = await dio.patch('$serverDomainAddress/users/deleteGroupMessage', data: stringified);
      if(res.data.isNotEmpty){
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  void deleteGroupMessageForAll() async{
    try {
      socket.emit("delete-group-message-for-all-to-server", {
        'chatID': widget.chatID,
        'messageID': groupMessageData.messageID,
        'currentID': appStateClass.currentID,
        'content': '',
        'recipients': widget.recipients
      });
      String stringified = jsonEncode({
        'chatID': widget.chatID,
        'messageID': groupMessageData.messageID,
        'currentID': appStateClass.currentID,
        'recipients': widget.recipients
      });
      var res = await dio.patch('$serverDomainAddress/users/deleteGroupMessageForAll', data: stringified);
      if(res.data.isNotEmpty){
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  void displayMessageBottomSheet(){
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 56, 54, 54),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0)
              )
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: getScreenHeight() * 0.015),
                Container(
                  height: getScreenHeight() * 0.01,
                  width: getScreenWidth() * 0.15,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  )
                ),
                SizedBox(height: getScreenHeight() * 0.015),   
                CustomButton(
                  onTapped: (){
                    Navigator.pop(bottomSheetContext);
                    runDelay(() => deleteGroupMessage(), actionDelayTime);
                  },
                  buttonText: 'Delete message',
                  width: double.infinity,
                  height: getScreenHeight() * 0.08,
                  buttonColor: Colors.transparent,
                  setBorderRadius: false,
                ),
                groupMessageData.sender == appStateClass.currentID ?
                  CustomButton(
                    onTapped: (){
                      Navigator.pop(bottomSheetContext);
                      runDelay(() => deleteGroupMessageForAll(), actionDelayTime);
                    },
                    buttonText: 'Delete message for everyone',
                    width: double.infinity,
                    height: getScreenHeight() * 0.08,
                    buttonColor: Colors.transparent,
                    setBorderRadius: false,
                  )
                : Container()
              ]
            )
          )
        );
      }
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if(groupMessageData.deletedList.contains(appStateClass.currentID)){
      return Container(
      );
    }
    UserDataClass senderProfileData = appStateClass.usersDataNotifiers.value[groupMessageData.sender]!.notifier.value;
    if(senderProfileData.blockedByCurrentID || senderProfileData.blocksCurrentID){
      return Container(
      );
    }

    if(groupMessageData.type == 'message'){
      List<MediaDatasClass> mediasDatas = groupMessageData.mediasDatas;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 1.5, vertical: defaultVerticalPadding / 2),
        color: Colors.transparent,
        child: Column(
        children: [
          widget.previousMessageUploadTime.isEmpty || (widget.previousMessageUploadTime.isNotEmpty && getDateFormat(widget.previousMessageUploadTime).compareTo(getDateFormat(groupMessageData.uploadTime)) != 0) ?
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.01, horizontal: getScreenWidth() * 0.04),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7.5),
                    color: Colors.grey
                  ),
                  child: Text(convertDateTimeDisplay(groupMessageData.uploadTime)) 
                ),
                SizedBox(height: getScreenHeight() * 0.02)
              ],
            ) 
          : Container(),
            Column(
              crossAxisAlignment: groupMessageData.sender == appStateClass.currentID ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: groupMessageData.sender == appStateClass.currentID ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    groupMessageData.sender != appStateClass.currentID ?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: (){
                              runDelay(() => Navigator.push(
                                context,
                                SliderRightToLeftRoute(
                                  page: ProfilePageWidget(userID: groupMessageData.sender)
                                )
                              ), 0);
                            },
                            child: Container(
                              width: getScreenWidth() * 0.08,
                              height: getScreenWidth() * 0.08,
                              decoration: BoxDecoration(
                                border: Border.all(width: 2, color: Colors.white),
                                borderRadius: BorderRadius.circular(100),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    senderData.profilePicLink
                                  ), fit: BoxFit.fill
                                )
                              ),
                            ),
                          ),
                          SizedBox(width: getScreenWidth() * 0.015)
                        ],
                      )
                    : Container(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: groupMessageData.sender == appStateClass.currentID ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for(int i = 0; i < mediasDatas.length; i++)
                            mediaDataMessageComponentWidget(mediasDatas[i], context)
                          ],
                        ),
                        groupMessageData.content.isNotEmpty ?
                          Align(
                            alignment: groupMessageData.sender == appStateClass.currentID ? Alignment.topRight : Alignment.topLeft,
                            child: InkWell(
                              onLongPress: () {
                                displayMessageBottomSheet();
                              },
                              child: Container(
                                margin: EdgeInsets.only(top: 0.01 * getScreenHeight()),
                                padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.015, vertical: getScreenHeight() * 0.008),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7.5),
                                  border: Border.all(width: 2, color: Colors.white),
                                  color: groupMessageData.sender == appStateClass.currentID ? Colors.blue : Colors.grey.withOpacity(0.5)
                                ),
                                constraints: BoxConstraints(
                                  maxWidth: getScreenWidth() * 0.7,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DisplayTextComponent(
                                      text: groupMessageData.content, tagsPressable: true, overflow: TextOverflow.ellipsis, 
                                      maxLines: 100, style: TextStyle(fontSize: defaultTextFontSize), alignment: TextAlign.left, 
                                      context: context
                                    )
                                  ],
                                )
                              ),
                            )
                          )
                        : Container(),
                      ],
                    ),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(height: 0.01 * getScreenHeight()),
                    Row(      
                      mainAxisAlignment: groupMessageData.sender == appStateClass.currentID ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: groupMessageData.sender == appStateClass.currentID ? 0 : getScreenWidth() * 0.09,
                        ),
                        Text(getCleanTimeFormat(groupMessageData.uploadTime), style: TextStyle(fontSize: defaultTextFontSize * 0.675, color: Colors.grey)),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ],
        )
      );
    }else{
      return Align(
        alignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 1.5, vertical: defaultVerticalPadding / 2),
          color: Colors.transparent,
          child: Column(
            children: [
              widget.previousMessageUploadTime.isEmpty || (widget.previousMessageUploadTime.isNotEmpty && getDateFormat(widget.previousMessageUploadTime).compareTo(getDateFormat(groupMessageData.uploadTime)) != 0) ?
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.01, horizontal: getScreenWidth() * 0.04),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7.5),
                        color: Colors.grey
                      ),
                      child: Text(convertDateTimeDisplay(groupMessageData.uploadTime)) 
                    ),
                    SizedBox(height: getScreenHeight() * 0.02)
                  ],
                )
              : Container(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(groupMessageData.content, style: TextStyle(fontSize: defaultTextFontSize), textAlign: TextAlign.center),
                ],
              ),
            ],
          )
        )
      );
    }
  }

}