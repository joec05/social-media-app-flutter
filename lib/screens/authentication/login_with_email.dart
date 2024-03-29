import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class LoginWithEmailStateless extends StatelessWidget {
  const LoginWithEmailStateless({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginWithEmailStateful();
  }
}

class LoginWithEmailStateful extends StatefulWidget {
  const LoginWithEmailStateful({super.key});

  @override
  State<LoginWithEmailStateful> createState() => _LoginWithEmailStatefulState();
}

class _LoginWithEmailStatefulState extends State<LoginWithEmailStateful> {
  late LoginController controller;

  @override
  void initState(){
    super.initState();
    controller = LoginController(context);
    controller.initializeController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Login With Email'), 
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
                      height: defaultVerticalPadding
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
                      child: Column(
                        children: [
                          textFieldWithDescription(
                            TextField(
                              controller: controller.passwordController,
                              decoration: generateProfileTextFieldDecoration('your password', Icons.lock),
                              keyboardType: TextInputType.visiblePassword,
                              maxLength: controller.passwordCharacterMaxLimit
                            ),
                            'Password',
                            "Your password should be between ${controller.passwordCharacterMinLimit} and ${controller.passwordCharacterMaxLimit} characters",
                          ),
                          SizedBox(
                            height: getScreenHeight() * 0.001,
                          ),
                        ]
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
                            controller.verifyEmailFormat,
                            controller.verifyPasswordFormat,
                            controller.isLoading
                          ]),
                          builder: (context, child){
                            bool emailVerified = controller.verifyEmailFormat.value;
                            bool passwordVerified = controller.verifyPasswordFormat.value;
                            bool isLoadingValue = controller.isLoading.value;
                            return CustomButton(
                              width: defaultTextFieldButtonSize.width, 
                              height: defaultTextFieldButtonSize.height,
                              color: emailVerified && passwordVerified && !isLoadingValue ? 
                                Colors.red : Colors.grey, 
                              text: 'Login', 
                              onTapped: emailVerified && passwordVerified && !isLoadingValue ?
                                controller.loginWithEmail : (){},
                              setBorderRadius: true,
                              prefix: null,
                              loading: isLoadingValue
                            );
                          }
                        )
                      ]
                    ),
                    SizedBox(
                      height: defaultVerticalPadding
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => controller.resetPassword(context),
                          child: const Text('Forgot your password?', 
                            style: TextStyle(fontSize: 14, color: Colors.amberAccent,)
                          )
                        )
                      ]
                    ),
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
              )
            ]
          )
        )
      ),
    );
  }
}
