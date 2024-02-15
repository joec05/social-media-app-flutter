import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class EditGroupProfileWidget extends StatelessWidget {
  final String chatID;
  final GroupProfileClass groupProfileData;
  const EditGroupProfileWidget({super.key, required this.chatID, required this.groupProfileData});

  @override
  Widget build(BuildContext context) {
    return EditGroupProfileStateful(chatID: chatID, groupProfileData: groupProfileData);
  }
}

class EditGroupProfileStateful extends StatefulWidget {
  final String chatID;
  final GroupProfileClass groupProfileData;
  const EditGroupProfileStateful({super.key, required this.chatID, required this.groupProfileData});

  @override
  State<EditGroupProfileStateful> createState() => _EditGroupProfileStatefulState();
}

class _EditGroupProfileStatefulState extends State<EditGroupProfileStateful> with LifecycleListenerMixin{
  late EditGroupProfileController controller;

  @override
  void initState(){
    super.initState();
    controller = EditGroupProfileController(
      context, 
      widget.chatID, 
      ValueNotifier(widget.groupProfileData)
    );
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
        title: const Text('Edit Group Profile'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: Center(
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding),
              child: ListView(
                children: <Widget>[
                  SizedBox(
                    height: defaultVerticalPadding
                  ),
                  SizedBox(
                    height: titleToContentMargin,
                  ),
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      controller.imageFilePath,
                      controller.imageNetworkPath
                    ]),
                    builder: (context, child){
                      String filePath = controller.imageFilePath.value;
                      String networkPath = controller.imageNetworkPath.value;
                      if(filePath.isNotEmpty){
                        return Column(
                          children: [
                            containerMargin(
                              Container(
                                width: getScreenWidth() * 0.35, height: getScreenWidth() * 0.35,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 2),
                                  borderRadius: BorderRadius.circular(100),
                                  image: DecorationImage(
                                    image: FileImage(
                                      File(filePath)
                                    ), fit: BoxFit.fill
                                  )
                                ),
                                child: Center(
                                  child: GestureDetector(
                                    onTap: (){
                                      if(mounted) controller.imageFilePath.value = '';
                                    },
                                    child: const Icon(Icons.delete, size: 30)
                                  ),
                                )
                              ),
                              EdgeInsets.only(top: getScreenHeight() * 0.0075, bottom: defaultPickedImageVerticalMargin)
                            )
                          ]
                        );
                      }else if(networkPath.isNotEmpty){
                        return Column(
                          children: [
                            containerMargin(
                              Container(
                                width: getScreenWidth() * 0.35, height: getScreenWidth() * 0.35,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 2),
                                  borderRadius: BorderRadius.circular(100),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      networkPath
                                    ), fit: BoxFit.fill
                                  )
                                ),
                                child: Center(
                                  child: GestureDetector(
                                    onTap: (){
                                      if(mounted) controller.imageNetworkPath.value = '';
                                    },
                                    child: const Icon(Icons.delete, size: 30)
                                  ),
                                )
                              ),
                              EdgeInsets.only(top: getScreenHeight() * 0.0075, bottom: defaultPickedImageVerticalMargin)
                            )
                          ]
                        );
                      }else{
                        return containerMargin(
                          Column(
                            children: [
                              Container(
                                width: getScreenWidth() * 0.35, height: getScreenWidth() * 0.35,
                                decoration: BoxDecoration(
                                  border: Border.all(width: 2),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () => controller.pickImage(),
                                    child: const Icon(Icons.add, size: 30)
                                  ),
                                )
                              )
                            ]
                          ),
                          EdgeInsets.only(top: getScreenHeight() * 0.0075, bottom: defaultPickedImageVerticalMargin)
                        );
                      }
                    },
                  ),
                  containerMargin(
                    textFieldWithDescription(
                      TextField(
                        controller: controller.nameController,
                        decoration: generateProfileTextFieldDecoration('group name', Icons.person),
                        maxLength: controller.nameCharacterMaxLimit,
                      ),
                      'Name',
                      "Your name should be between 1 and ${controller.nameCharacterMaxLimit} characters",
                    ), EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                  ),
                  containerMargin(
                    textFieldWithDescription(
                      TextField(
                        controller: controller.descriptionController,
                        decoration: generateProfileTextFieldDecoration('group description', Icons.description),
                        maxLength: controller.descriptionCharacterMaxLimit,
                      ),
                      'Description',
                      "Your name should be between 1 and ${controller.nameCharacterMaxLimit} characters",
                    ), EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                  ),
                  SizedBox(
                    height: textFieldToButtonMargin
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ListenableBuilder(
                        listenable: Listenable.merge([
                          controller.verifyNameFormat,
                          controller.isLoading,
                          controller.imageFilePath,
                          controller.imageNetworkPath
                        ]),
                        builder: (context, child){
                          bool nameVerified = controller.verifyNameFormat.value;
                          bool isLoadingValue = controller.isLoading.value;
                          String filePath = controller.imageFilePath.value;
                          String networkPath = controller.imageNetworkPath.value;
                          return CustomButton(
                            width: defaultTextFieldButtonSize.width, 
                            height: defaultTextFieldButtonSize.height,
                            color: Colors.red, 
                            text: 'Continue', 
                            onTapped: nameVerified && (filePath.isNotEmpty || networkPath.isNotEmpty) && !isLoadingValue ?
                              controller.editGroupProfile : null,
                            setBorderRadius: true,
                            prefix: null,
                            loading: isLoadingValue,
                          );
                        },
                      )
                    ]
                  ),
                  SizedBox(
                    height: defaultVerticalPadding
                  )
                ],
              ),
            ),
            ValueListenableBuilder(
              valueListenable: controller.isLoading,
              builder: (context, isLoadingValue, child) {
                return isLoadingValue ?
                  loadingSignWidget()
                : Container();
              } 
            )
          ]
        )
      ),
    );
  }
}
