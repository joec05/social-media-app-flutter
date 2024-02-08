import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/attachment/media_data_class.dart';
import 'package:social_media_app/class/chat/private-chat/private_message_class.dart';
import 'package:social_media_app/constants/global_functions.dart';
import 'package:social_media_app/constants/global_variables.dart';
import 'package:social_media_app/custom/basic-widget/custom_button.dart';
import 'package:social_media_app/custom/tagging/custom_text_span.dart';
import 'package:social_media_app/socket/main.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/app_styles.dart';

class CustomPrivateMessage extends StatefulWidget {
  final String? chatID;
  final String chatRecipient;
  final PrivateMessageClass privateMessageData;
  final String previousMessageUploadTime;

  const CustomPrivateMessage({
    super.key,
    required this.chatID,
    required this.chatRecipient,
    required this.privateMessageData,
    required this.previousMessageUploadTime
  });

  @override
  CustomPrivateMessageState createState() => CustomPrivateMessageState();
  
}

var dio = Dio();

class CustomPrivateMessageState extends State<CustomPrivateMessage> {
  late PrivateMessageClass privateMessageData;

  @override
  void initState(){
    super.initState();
    privateMessageData = widget.privateMessageData;
  }

  @override void dispose(){
    super.dispose();
  }

  void deletePrivateMessage() async{
    try {
      socket.emit("delete-private-message-to-server", {
        'chatID': widget.chatID,
        'messageID': privateMessageData.messageID,
        'currentID': appStateClass.currentID,
        'recipient': widget.chatRecipient
      });
      String stringified = jsonEncode({
        'chatID': widget.chatID,
        'messageID': privateMessageData.messageID,
        'currentID': appStateClass.currentID,
      });
      var res = await dio.patch('$serverDomainAddress/users/deletePrivateMessage', data: stringified);
      if(res.data.isNotEmpty){
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  void deletePrivateMessageForAll() async{
    try {
      socket.emit("delete-private-message-for-all-to-server", {
        'chatID': widget.chatID,
        'messageID': privateMessageData.messageID,
        'currentID': appStateClass.currentID,
        'recipient': widget.chatRecipient,
        'content': ''
      });
      String stringified = jsonEncode({
        'chatID': widget.chatID,
        'messageID': privateMessageData.messageID,
        'currentID': appStateClass.currentID,
        'recipient': widget.chatRecipient
      });
      var res = await dio.patch('$serverDomainAddress/users/deletePrivateMessageForAll', data: stringified);
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
                    runDelay(() => deletePrivateMessage(), actionDelayTime);
                  },
                  buttonText: 'Delete message',
                  width: double.infinity,
                  height: getScreenHeight() * 0.08,
                  buttonColor: Colors.transparent,
                  setBorderRadius: false,
                ),
                privateMessageData.sender == appStateClass.currentID ?
                  InkWell(
                    onTap: (){},
                    splashFactory: InkRipple.splashFactory,
                    child: CustomButton(
                      onTapped: (){
                        Navigator.pop(bottomSheetContext);
                        runDelay(() => deletePrivateMessageForAll(), actionDelayTime);
                      },
                      buttonText: 'Delete message for everyone',
                      width: double.infinity,
                      height: getScreenHeight() * 0.08,
                      buttonColor: Colors.transparent,
                      setBorderRadius: false,
                    )
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
    if(privateMessageData.deletedList.contains(appStateClass.currentID)){
      return Container();
    }

    List<MediaDatasClass> mediasDatas = privateMessageData.mediasDatas;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 1.5, vertical: defaultVerticalPadding / 2),
      color: Colors.transparent,
      child: Column(
        children: [
          widget.previousMessageUploadTime.isEmpty || (widget.previousMessageUploadTime.isNotEmpty && getDateFormat(widget.previousMessageUploadTime).compareTo(getDateFormat(privateMessageData.uploadTime)) != 0) ?
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.01, horizontal: getScreenWidth() * 0.04),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7.5),
                    color: Colors.grey
                  ),
                  child: Text(convertDateTimeDisplay(privateMessageData.uploadTime)) 
                ),
                SizedBox(height: getScreenHeight() * 0.02)
              ],
            ) 
          : Container(),
          Column(
            crossAxisAlignment: privateMessageData.sender == appStateClass.currentID ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for(int i = 0; i < mediasDatas.length; i++)
                  mediaDataMessageComponentWidget(mediasDatas[i], context)
                ],
              ),
              privateMessageData.content.isNotEmpty ? 
                Align(
                  alignment: privateMessageData.sender == appStateClass.currentID ? Alignment.topRight : Alignment.topLeft,
                  child: InkWell(
                    onLongPress: () {
                      displayMessageBottomSheet();
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 0.01 * getScreenHeight()),
                      padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.015, vertical: getScreenHeight() * 0.008),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7.5),
                        border: Border.all(width: 2, color: Colors.white),
                        color: privateMessageData.sender == appStateClass.currentID ? Colors.blue : Colors.grey.withOpacity(0.5)
                      ),
                      constraints: BoxConstraints(
                        maxWidth: getScreenWidth() * 0.7,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DisplayTextComponent(
                            text: privateMessageData.content, tagsPressable: true, overflow: TextOverflow.ellipsis, 
                            maxLines: 100, style: TextStyle(fontSize: defaultTextFontSize * 0.95), alignment: TextAlign.left, 
                            context: context
                          )
                        ],
                      )
                    ),
                  )
                )
              : Container(),
              Column(                
                children: [
                  Text(getCleanTimeFormat(privateMessageData.uploadTime), style: TextStyle(fontSize: defaultTextFontSize * 0.675, color: Colors.grey)),
                ],
              )
            ],
          ),
        ],
      )
    );
  }

}