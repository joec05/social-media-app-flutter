// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/appdata/GlobalFunctions.dart';
import 'package:social_media_app/custom/CustomButton.dart';
import 'package:social_media_app/firebase/firebase_constants.dart';
import 'package:social_media_app/styles/AppStyles.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({Key? key}) : super(key: key);

  @override
  State<EmailVerificationPage> createState() =>  _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool verified = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    auth.currentUser?.sendEmailVerification();
    timer = Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
  }

  void checkEmailVerified() async {
    await auth.currentUser?.reload().then((value){
      if(mounted){
        setState(() {
          verified = auth.currentUser!.emailVerified;
        });
        if(verified) {
          timer?.cancel();
          Navigator.pop(context, verified);
        }
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                child: !verified ? const CircularProgressIndicator() : const Icon(FontAwesomeIcons.check)
              ),
              SizedBox(height: getScreenHeight() * 0.04),
              CustomButton(
                width: getScreenWidth() * 0.65, height: getScreenHeight() * 0.07,
                buttonColor: Colors.red, buttonText: 'Resend email', 
                onTapped: (){
                  try{
                    auth.currentUser!.sendEmailVerification();
                  } catch(e) {
                    debugPrint(e.toString());
                  }
                },
                setBorderRadius: true,
              )
            ],
          ),
        ),
      ),
    );
  }
}