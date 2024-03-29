import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/global_files.dart';

class WritePostWidget extends StatelessWidget {
  const WritePostWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _WritePostWidgetStateful();
  }
}

class _WritePostWidgetStateful extends StatefulWidget {
  const _WritePostWidgetStateful();

  @override
  State<_WritePostWidgetStateful> createState() => __WritePostWidgetStatefulState();
}

class __WritePostWidgetStatefulState extends State<_WritePostWidgetStateful> with LifecycleListenerMixin{
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
        title: const Text('Upload Post'), 
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
              bool postVerified = controller.verifyTextFormat.value;
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
                  onTapped: !isUploadingValue && (mediasDatasValue.isNotEmpty || postVerified) ? 
                    () => controller.uploadPost() : null,
                  setBorderRadius: true,
                  prefix: null,
                  loading: isUploadingValue,
                )
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
                      decoration: generatePostTextFieldDecoration('your post', FontAwesomeIcons.pencil),
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2),
                      child: ValueListenableBuilder<List>(
                        valueListenable: controller.mediasComponents,
                        builder: ((context, mediasComponentsList, child) {
                          return Column(
                            children: [
                              for(int i = 0; i < mediasComponentsList.length; i++)
                              controller.mediaComponentIndex(mediasComponentsList[i], i)
                            ],
                          );
                        }),
                      )
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: getScreenWidth() * 0.015, 
                                  vertical: getScreenHeight() * 0.01
                                ),
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: getScreenWidth() * 0.015,
                                  vertical: getScreenHeight() * 0.01
                                ),
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: getScreenWidth() * 0.015, 
                                  vertical: getScreenHeight() * 0.01
                                ),
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
                loadingSignWidget() : Container();
            } 
          )
        ]
      )
    );
  }
}
