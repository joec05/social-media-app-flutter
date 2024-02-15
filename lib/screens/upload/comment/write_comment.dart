import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';

class WriteCommentWidget extends StatelessWidget {
  final String parentPostSender;
  final String parentPostID;
  final String parentPostType;
  const WriteCommentWidget({super.key, required this.parentPostSender, required this.parentPostID, required this.parentPostType});

  @override
  Widget build(BuildContext context) {
    return _WriteCommentWidgetStateful(parentPostSender: parentPostSender, parentPostID: parentPostID, parentPostType: parentPostType);
  }
}

class _WriteCommentWidgetStateful extends StatefulWidget {
  final String parentPostSender;
  final String parentPostID;
  final String parentPostType;
  const _WriteCommentWidgetStateful({required this.parentPostSender, required this.parentPostID, required this.parentPostType});

  @override
  State<_WriteCommentWidgetStateful> createState() => __WriteCommentWidgetStatefulState();
}

class __WriteCommentWidgetStatefulState extends State<_WriteCommentWidgetStateful> with LifecycleListenerMixin{
  late UploadController controller;
  
  @override
  void initState(){
    super.initState();
    controller = UploadController(context);
    controller.initializeController();
  }

  @override void dispose(){
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Upload Comment'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        actions: [
          ListenableBuilder(
            listenable: Listenable.merge([
              controller.isUploading,
              controller.verifyTextFormat,
              controller.mediasDatas
            ]),
            builder: (context, child){
              bool isUploadingValue = controller.isUploading.value;
              bool commentVerified = controller.verifyTextFormat.value;
              List<MediaDatasClass> mediasDatasValue = controller.mediasDatas.value;
              return Padding(
                padding: EdgeInsets.symmetric(
                  vertical: kToolbarHeight * 0.15, 
                  horizontal: getScreenWidth() * 0.025
                ),
                child: CustomButton(
                  width: getScreenWidth() * 0.25, 
                  height: kToolbarHeight, 
                  color: Colors.red, 
                  text: 'Upload',
                  onTapped: !isUploadingValue && (mediasDatasValue.isNotEmpty || commentVerified) ?
                    () => controller.uploadComment(
                      widget.parentPostID, 
                      widget.parentPostSender, 
                      widget.parentPostType
                    ) : null,
                  setBorderRadius: true,
                  prefix: null,
                  loading: isUploadingValue,
                ),
              );
            }
          )
        ]
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: ListView(
                  children: [
                    TextField(
                      controller: controller.textController,
                      decoration: generatePostTextFieldDecoration('your comment', FontAwesomeIcons.pencil),
                      minLines: postDraftTextFieldMinLines,
                      maxLines: postDraftTextFieldMaxLines,
                      maxLength: maxPostWordLimit,
                      onChanged: (value){
                        controller.listenTextField(value);
                        controller.listenTextController(value);
                      },
                      onEditingComplete: (){
                        controller.listenTextController(
                          controller.textController.text
                        );
                      },
                    ),
                    ValueListenableBuilder<List>(
                      valueListenable: controller.mediasComponents,
                      builder: ((context, mediasComponentsList, child) {
                        return Column(
                          children: [
                            for(int i = 0; i < mediasComponentsList.length; i++)
                            controller.mediaComponentIndex(mediasComponentsList[i], i)
                          ],
                        );
                      }),
                    ),
                    
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(width: 1)),
                ),
                child: ValueListenableBuilder<List>(
                  valueListenable: controller.mediasComponents,
                  builder: (context, mediasComponentsList, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => controller.pickImage(ImageSource.gallery),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.015, vertical: getScreenHeight() * 0.01),
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.photo, size: writePostIconSize,
                                  color: controller.mediasComponents.value.length == maxMediaCount ?
                                   Colors.grey : Theme.of(context).iconTheme.color
                                ),
                              )
                            ),
                            GestureDetector(
                              onTap: () => controller.pickImage(ImageSource.camera),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.015, vertical: getScreenHeight() * 0.01),
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.camera_alt_sharp, size: writePostIconSize,
                                  color: controller.mediasComponents.value.length == maxMediaCount ?
                                   Colors.grey : Theme.of(context).iconTheme.color
                                ),
                              )
                            ),
                            GestureDetector(
                              onTap: () => controller.pickVideo(),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.015, vertical: getScreenHeight() * 0.01),
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.video_file_sharp, size: writePostIconSize,
                                  color: controller.mediasComponents.value.length == maxMediaCount ?
                                   Colors.grey : Theme.of(context).iconTheme.color
                                ),
                              )
                            ),
                          ],
                        )
                      ]
                    );
                  }
                ) 
              )
            ]
          ),
          ValueListenableBuilder(
            valueListenable: controller.isUploading,
            builder: (context, isUploadingValue, child) {
              return isUploadingValue ?
                loadingSignWidget()
              : Container();
            } 
          )
        ]
      )
    );
  }
}
