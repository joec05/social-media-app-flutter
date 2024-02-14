import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/global_files.dart';

void main() async{
  try {
    WidgetsFlutterBinding.ensureInitialized();
    ByteData data = await PlatformAssetBundle().load('assets/certificate/ca.pem');
    SecurityContext.defaultContext.setTrustedCertificatesBytes(data.buffer.asUint8List());
    await DatabaseHelper().initDatabase();
    GlobalObserver globalObserver = GlobalObserver();
    WidgetsBinding.instance.addObserver(globalObserver);
    await firebaseInitialization;
    await firebaseAppCheckInitialization;
    authRepo.initializeAuthListener();
    sharedPreferencesController.initializeController();
    runApp(const SocialMediaApp());
  } catch (_) {
    debugPrint("An error occured when starting the app");
  }
}

class SocialMediaApp extends StatefulWidget {
  const SocialMediaApp({super.key});

  @override
  State<SocialMediaApp> createState() => _SocialMediaAppState();
}

class _SocialMediaAppState extends State<SocialMediaApp> {
  bool onboardingDisplayed = sharedPreferencesController.getOnboardingDisplayed() == true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Media App',
      theme: globalTheme.darkTheme,
      onGenerateRoute: (settings) {
        if (settings.name == "/chats-list") {
          return generatePageRouteBuilder(settings, const ChatsWidget());
        }
        return null;
      },
      home: authRepo.currentUser.value != null ? const MainPageWidget() : onboardingDisplayed ? const HomePage() : const OnboardingPage()
    );
  }
}