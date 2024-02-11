import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';

class EditCommentWidget extends StatelessWidget {
  final CommentClass commentData;
  const EditCommentWidget({super.key, required this.commentData});

  @override
  Widget build(BuildContext context) {
    return _EditCommentWidgetStateful(commentData: commentData);
  }
}

class _EditCommentWidgetStateful extends StatefulWidget {
  final CommentClass commentData;
  const _EditCommentWidgetStateful({required this.commentData});

  @override
  State<_EditCommentWidgetStateful> createState() => __EditCommentWidgetStatefulState();
}

class __EditCommentWidgetStatefulState extends State<_EditCommentWidgetStateful> with LifecycleListenerMixin{
  late UploadController controller;

  @override
  void initState(){
    super.initState();
    controller = UploadController(context);
    controller.initializeController();
    controller.initializeEditedPost(
      widget.commentData.content,
      widget.commentData.mediasDatas
    );
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
        title: const Text('Edit Comment'), 
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
                  width: getScreenWidth() * 0.25, height: kToolbarHeight, 
                  buttonColor: Colors.red, buttonText: 'Edit',
                  onTapped: !isUploadingValue && (mediasDatasValue.isNotEmpty || commentVerified) ?
                    () => controller.editComment(
                      widget.commentData
                    ) : null,
                  setBorderRadius: true
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
                  border: Border(top: BorderSide(color: Colors.white, width: 1)),
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: getScreenWidth() * 0.015, 
                                  vertical: getScreenHeight() * 0.01
                                ),
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.photo, size: writePostIconSize,
                                  color: controller.mediasComponents.value.length == maxMediaCount ?
                                   Colors.grey : Colors.white
                                ),
                              )
                            ),
                            GestureDetector(
                              onTap: () => controller.pickImage(ImageSource.camera),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: getScreenWidth() * 0.015, 
                                  vertical: getScreenHeight() * 0.01
                                ),
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.camera_alt_sharp, size: writePostIconSize,
                                  color: controller.mediasComponents.value.length == maxMediaCount ?
                                   Colors.grey : Colors.white
                                ),
                              )
                            ),
                            GestureDetector(
                              onTap: () => controller.pickVideo(),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: getScreenWidth() * 0.015, 
                                  vertical: getScreenHeight() * 0.01
                                ),
                                alignment: Alignment.centerLeft,
                                child: Icon(Icons.video_file_sharp, size: writePostIconSize,
                                  color: controller.mediasComponents.value.length == maxMediaCount ?
                                   Colors.grey : Colors.white
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
