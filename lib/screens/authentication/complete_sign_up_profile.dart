import 'dart:io';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class CompleteSignUpProfileStateless extends StatelessWidget {
  const CompleteSignUpProfileStateless({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompleteSignUpProfileStateful();
  }
}

class CompleteSignUpProfileStateful extends StatefulWidget {
  const CompleteSignUpProfileStateful({super.key});

  @override
  State<CompleteSignUpProfileStateful> createState() => _CompleteSignUpProfileStatefulState();
}

class _CompleteSignUpProfileStatefulState extends State<CompleteSignUpProfileStateful>{
  late CompleteSignUpController controller;

  @override
  void initState(){
    super.initState();
    controller = CompleteSignUpController(context);
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
        title: const Text('Complete Sign Up'), 
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
                  Center(
                    child: containerMargin(
                      Text('Select your profile picture', style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.w500)),
                      EdgeInsets.only(top: defaultPickedImageVerticalMargin, bottom: getScreenHeight() * 0.0075)
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: controller.imageFilePath,
                    builder: (context, filePath, child){
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
                          EdgeInsets.only(top: getScreenHeight() * 0.0075, bottom: defaultPickedImageVerticalMargin)
                        );
                      }
                    }
                  ),
                  SizedBox(
                    height: getScreenHeight() * 0.025
                  ),
                  Center(
                    child: containerMargin(
                      Text('Complete your bio (optional)', style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.w500)),
                      EdgeInsets.only(top: defaultPickedImageVerticalMargin, bottom: getScreenHeight() * 0.0075)
                    ),
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
                    EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
                  ),
                  SizedBox(
                    height: textFieldToButtonMargin
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ListenableBuilder(
                        listenable: Listenable.merge([
                          controller.imageFilePath,
                          controller.isLoading
                        ]),
                        builder: (context, child){
                          String filePath = controller.imageFilePath.value;
                          bool isLoadingValue = controller.isLoading.value;
                          return CustomButton(
                            width: defaultTextFieldButtonSize.width, 
                            height: defaultTextFieldButtonSize.height,
                            color: Colors.red, 
                            text: 'Continue', 
                            onTapped: filePath.isNotEmpty && !isLoadingValue ?
                              () => controller.completeSignUpProfile() : null,
                            setBorderRadius: true,
                            prefix: null,
                            loading: isLoadingValue
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
