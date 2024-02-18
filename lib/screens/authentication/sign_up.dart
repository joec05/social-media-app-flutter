import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SignUpStateless extends StatelessWidget {
  const SignUpStateless({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignUpStateful();
  }
}

class SignUpStateful extends StatefulWidget {
  const SignUpStateful({super.key});

  @override
  State<SignUpStateful> createState() => _SignUpStatefulState();
}

class _SignUpStatefulState extends State<SignUpStateful> {
  late SignUpController controller;

  @override
  void initState(){
    super.initState();
    controller = SignUpController(context);
    controller.initializeController();
  }

  @override
  void dispose(){
    super.dispose();
    controller.dispose();
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Sign Up'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: defaultFrontPageDecoration,
          child: Stack(
            children: [
              Positioned(
                left: -getScreenWidth() * 0.45,
                top: -getScreenWidth() * 0.25,
                child: Container(
                  width: getScreenWidth(),
                  height: getScreenWidth(),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
                    color: Colors.amber.withOpacity(0.65)
                  ),
                ),
              ),
              Positioned(
                right: -getScreenWidth() * 0.55,
                top: getScreenWidth() * 0.85,
                child: Container(
                  width: getScreenWidth(),
                  height: getScreenWidth(),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
                    color: Colors.blue.withOpacity(0.8)
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding),
                child: ListView(
                  children: <Widget>[
                    SizedBox(
                      height: titleToContentMargin,
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin),
                      child: textFieldWithDescription(
                        TextField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: generateProfileTextFieldDecoration('your email', Icons.mail),
                        ),
                        'Email',
                        ''
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin),
                      child: textFieldWithDescription(
                        TextField(
                          controller: controller.passwordController,
                          decoration: generateProfileTextFieldDecoration('password', Icons.lock),
                          keyboardType: TextInputType.visiblePassword,
                          maxLength: controller.passwordCharacterMaxLimit
                        ),
                        'Password',
                        "Your password should be between ${controller.passwordCharacterMinLimit} and ${controller.passwordCharacterMaxLimit} characters",
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin),
                      child: textFieldWithDescription(
                        TextField(
                          controller: controller.nameController,
                          decoration: generateProfileTextFieldDecoration('your name', Icons.person),
                          maxLength: controller.nameCharacterMaxLimit,
                        ),
                        'Name',
                        "Your name should be between 1 and ${controller.nameCharacterMaxLimit} characters",
                      )
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin),
                      child: textFieldWithDescription(
                          TextField(
                          controller: controller.usernameController,
                          decoration: generateProfileTextFieldDecoration('username', Icons.person),
                          maxLength: controller.usernameCharacterMaxLimit
                        ),
                        'Username',
                        "Your username should be between ${controller.usernameCharacterMinLimit} and ${controller.usernameCharacterMaxLimit} characters",
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin),
                      child: textFieldWithDescription(
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
                            controller.verifyEmailFormat,
                            controller.verifyPasswordFormat,
                            controller.verifyBirthDateFormat,
                            controller.isLoading
                          ]),
                          builder: (context, child){
                            bool nameVerified = controller.verifyNameFormat.value;
                            bool usernameVerified = controller.verifyUsernameFormat.value;
                            bool birthDateVerified = controller.verifyBirthDateFormat.value;
                            bool emailVerified = controller.verifyEmailFormat.value;
                            bool passwordVerified = controller.verifyPasswordFormat.value;
                            bool isLoadingValue = controller.isLoading.value;
                            return CustomButton(
                              width: defaultTextFieldButtonSize.width, 
                              height: defaultTextFieldButtonSize.height,
                              color: nameVerified && usernameVerified && emailVerified 
                              && passwordVerified && birthDateVerified && !isLoadingValue ? Colors.red : Colors.grey, 
                              text: 'Sign Up', 
                              onTapped: nameVerified && usernameVerified && emailVerified 
                              && passwordVerified && birthDateVerified && !isLoadingValue ?
                                controller.signUp : () {},
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
                    loadingPageWidget()
                  : Container();
                } 
              ),
            ]
          ),
        )
      ),
    );
  }
}
