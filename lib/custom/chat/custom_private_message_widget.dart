import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

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
        'currentID': appStateRepo.currentID,
        'recipient': widget.chatRecipient
      });
      await fetchDataRepo.fetchData(
        context, 
        RequestPatch.deletePrivateMessage, 
        {
          'chatID': widget.chatID,
          'messageID': privateMessageData.messageID,
          'currentID': appStateRepo.currentID,
        }
      );
    } catch (_) {
      if(mounted) {
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          tErr.unknown
        );
      }
    }
  }

  void deletePrivateMessageForAll() async{
    try {
      socket.emit("delete-private-message-for-all-to-server", {
        'chatID': widget.chatID,
        'messageID': privateMessageData.messageID,
        'currentID': appStateRepo.currentID,
        'recipient': widget.chatRecipient,
        'content': ''
      });
      await fetchDataRepo.fetchData(
        context, 
        RequestPatch.deletePrivateMessageForAll, 
        {
          'chatID': widget.chatID,
          'messageID': privateMessageData.messageID,
          'currentID': appStateRepo.currentID,
          'recipient': widget.chatRecipient
        }
      );
    } catch (e) {
      if(mounted) {
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          tErr.unknown
        );
      } 
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
                  text: 'Delete message',
                  width: double.infinity,
                  height: getScreenHeight() * 0.08,
                  color: Colors.transparent,
                  setBorderRadius: false,
                  prefix: null,
                  loading: false
                ),
                privateMessageData.sender == appStateRepo.currentID ?
                  InkWell(
                    onTap: (){},
                    splashFactory: InkRipple.splashFactory,
                    child: CustomButton(
                      onTapped: (){
                        Navigator.pop(bottomSheetContext);
                        runDelay(() => deletePrivateMessageForAll(), actionDelayTime);
                      },
                      text: 'Delete message for everyone',
                      width: double.infinity,
                      height: getScreenHeight() * 0.08,
                      color: Colors.transparent,
                      setBorderRadius: false,
                      prefix: null,
                      loading: false
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
    if(privateMessageData.deletedList.contains(appStateRepo.currentID)){
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
            crossAxisAlignment: privateMessageData.sender == appStateRepo.currentID ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                  alignment: privateMessageData.sender == appStateRepo.currentID ? Alignment.topRight : Alignment.topLeft,
                  child: InkWell(
                    onLongPress: () {
                      displayMessageBottomSheet();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.015, vertical: getScreenHeight() * 0.008),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7.5),
                        color: privateMessageData.sender == appStateRepo.currentID ? Colors.blue : Colors.grey.withOpacity(0.5)
                      ),
                      constraints: BoxConstraints(
                        maxWidth: getScreenWidth() * 0.7,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DisplayTextComponent(
                            text: privateMessageData.content, 
                            tagsPressable: true, 
                            overflow: TextOverflow.ellipsis, 
                            maxLines: 100, 
                            style: TextStyle(fontSize: defaultTextFontSize * 0.95, color: Theme.of(context).textTheme.labelMedium!.color), 
                            alignment: TextAlign.left, 
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
                  Text(getCleanTimeFormat(privateMessageData.uploadTime), style: TextStyle(fontSize: defaultTextFontSize * 0.675)),
                ],
              )
            ],
          ),
        ],
      )
    );
  }

}