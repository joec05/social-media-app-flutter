import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/global_files.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() =>  _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  late EmailVerificationController controller;

  @override
  void initState() {
    super.initState();
    controller = EmailVerificationController(context);
    controller.initializeController();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Verify Email'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Check your email and verify your email address: ${auth.currentUser?.email}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)
              ),
              SizedBox(height: getScreenHeight() * 0.04),
              ValueListenableBuilder(
                valueListenable: controller.verified,
                builder: (context, isVerified, child){
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    child: !isVerified ? const CircularProgressIndicator() : const Icon(FontAwesomeIcons.check)
                  );
                },
              ),
              SizedBox(height: getScreenHeight() * 0.04),
              CustomButton(
                width: getScreenWidth() * 0.65, 
                height: getScreenHeight() * 0.07,
                color: Colors.red, text: 'Resend email', 
                onTapped: (){
                  try{
                    auth.currentUser!.sendEmailVerification();
                  } catch(e) {
                    debugPrint(e.toString());
                  }
                },
                setBorderRadius: true,
                prefix: null,
                loading: false
              )
            ],
          ),
        ),
      ),
    );
  }
}