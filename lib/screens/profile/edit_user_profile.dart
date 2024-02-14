import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class EditProfileStateless extends StatelessWidget {
  const EditProfileStateless({super.key});

  @override
  Widget build(BuildContext context) {
    return const EditProfileStateful();
  }
}

class EditProfileStateful extends StatefulWidget {
  const EditProfileStateful({super.key});

  @override
  State<EditProfileStateful> createState() => _EditProfileStatefulState();
}

class _EditProfileStatefulState extends State<EditProfileStateful> with LifecycleListenerMixin{
  late EditUserProfileController controller;

  @override
  void initState(){
    super.initState();
    controller = EditUserProfileController(context);
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
        title: const Text('Edit Profile'), 
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
                                  border: Border.all(width: 2, color: Colors.white),
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
                              EdgeInsets.only(
                                top: getScreenHeight() * 0.0075, 
                                bottom: defaultPickedImageVerticalMargin
                              )
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
                                  border: Border.all(width: 2, color: Colors.white),
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
                              EdgeInsets.only(
                                top: getScreenHeight() * 0.0075, 
                                bottom: defaultPickedImageVerticalMargin
                              )
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
                                  border: Border.all(width: 2, color: Colors.white),
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
                          EdgeInsets.only(
                            top: getScreenHeight() * 0.0075, 
                            bottom: defaultPickedImageVerticalMargin
                          )
                        );
                      }
                    }
                  ),
                  containerMargin(
                    textFieldWithDescription(
                      TextField(
                        controller: controller.nameController,
                        decoration: generateProfileTextFieldDecoration('your name', Icons.person),
                        maxLength: controller.nameCharacterMaxLimit,
                      ),
                      'Name',
                      "Your name should be between 1 and ${controller.nameCharacterMaxLimit} characters",
                    ), EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)),
                  containerMargin(
                    textFieldWithDescription(
                        TextField(
                        controller: controller.usernameController,
                        decoration: generateProfileTextFieldDecoration('username', Icons.person),
                        maxLength: controller.usernameCharacterMaxLimit
                      ),
                      'Username',
                      "Your username should be between ${controller.usernameCharacterMinLimit} and ${controller.usernameCharacterMaxLimit} characters",
                    ),
                    EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                  ),
                  containerMargin(
                    textFieldWithDescription(
                      GestureDetector(
                        onTap: () => controller.selectBirthDate(context),
                        child: TextField(
                          controller: controller.birthDateController,
                          decoration: generateProfileTextFieldDecoration('birth date', Icons.cake),
                          enabled: false,
                        ),
                      ),
                      'Birth Date',
                      ''
                    ),
                    EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                  ),
                  containerMargin(
                    textFieldWithDescription(
                      TextField(
                        controller: controller.bioController,
                        decoration: generateBioTextFieldDecoration('bio', Icons.person),
                        maxLength: controller.bioCharacterMaxLimit,
                        maxLines: 5,
                        minLines: 1,
                      ),
                      'Bio',
                      "Your bio is optional and should not exceed ${controller.bioCharacterMaxLimit} characters",
                    ),
                    EdgeInsets.only(top: getScreenHeight() * 0.0075, bottom: defaultTextFieldVerticalMargin)
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
                          controller.verifyUsernameFormat,
                          controller.verifyBirthDateFormat,
                          controller.isLoading,
                          controller.imageFilePath,
                          controller.imageNetworkPath
                        ]),
                        builder: (context, child){
                          bool nameVerified = controller.verifyNameFormat.value;
                          bool usernameVerified = controller.verifyUsernameFormat.value;
                          bool birthDateVerified = controller.verifyBirthDateFormat.value;
                          bool isLoadingValue = controller.isLoading.value;
                          String filePath = controller.imageFilePath.value;
                          String networkPath = controller.imageNetworkPath.value;
                          return CustomButton(
                            width: defaultTextFieldButtonSize.width, 
                            height: defaultTextFieldButtonSize.height,
                            color: Colors.red, 
                            text: 'Continue', 
                            onTapped: nameVerified && usernameVerified && birthDateVerified && (filePath.isNotEmpty || networkPath.isNotEmpty) && !isLoadingValue ?
                              controller.editProfile : null,
                            setBorderRadius: true,
                            prefix: null,
                            loading: isLoadingValue,
                          );
                        }
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
