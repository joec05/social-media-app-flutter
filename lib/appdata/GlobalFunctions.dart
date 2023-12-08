// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_media_app/appdata/GlobalEnums.dart';
import 'package:social_media_app/appdata/GlobalVariables.dart';
import 'package:video_player/video_player.dart';
import '../class/MediaDataClass.dart';
import '../class/WebsiteCardClass.dart';
import '../custom/CustomTextEditingController.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as html;

double getScreenHeight(){
  return PlatformDispatcher.instance.views.first.physicalSize.height / PlatformDispatcher.instance.views.first.devicePixelRatio;
}

double getScreenWidth(){
  return PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio;
}

bool checkEmailValid(email){
  return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
  .hasMatch(email);
}

bool checkUsernameValid(username){
  var usernamePattern = RegExp(r"^(?=.*[a-zA-Z])[\w\d_]+$");
  return usernamePattern.hasMatch(username);
}

Client updateAppWriteClient(){
  final appWriteClient = Client().setEndpoint('https://cloud.appwrite.io/v1').setProject(appWriteUserID).setSelfSigned();
  return appWriteClient;
}

Map<RegExp, TextStyle> textDisplayRegexStyle = {
  textDisplayUserTagRegex: const TextStyle(color: Color.fromARGB(255, 16, 61, 100), fontWeight: FontWeight.w600),
  textDisplayHashtagRegex: const TextStyle(color: Color.fromARGB(255, 40, 81, 117), fontWeight: FontWeight.w600),
  isLinkRegexTyped: const TextStyle(color: Color.fromARGB(255, 40, 81, 117), fontWeight: FontWeight.w600)
};

Size getSizeScale(width, height){
  double targetWidth = getScreenWidth();
  double targetHeight = getScreenHeight();
  
  double scaleWidth = targetWidth / width;
  double scaleHeight = targetHeight / height;

  double scale = scaleWidth < scaleHeight ? scaleWidth : scaleHeight;

  double resizedWidth = width * scale;
  double resizedHeight = height * scale;

  return Size(resizedWidth, resizedHeight);
}

InputFile fileToInputFile(String uri, String path) {
  final inputFile = InputFile.fromPath(path: uri, filename: path);
  return inputFile;
}

String getTimeDifference(String day) {
  DateTime? dateTime = DateTime.parse(day).toLocal();
  Duration difference = DateTime.now().difference(dateTime);
  if (difference.inSeconds < 60) {
    return '${difference.inSeconds} seconds ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else if(difference.inDays < 31){
    return '${difference.inDays} days ago';
  } else if(difference.inDays < 365){
    return '${(difference.inDays / 30).floor()} months ago';
  } else {
    return '${(difference.inDays / 365).floor()} years ago';
  }
}

String convertDateTimeDisplay(String dateTime){
  List<String> separatedDateTime = DateTime.parse(dateTime).toLocal().toIso8601String().substring(0, 10).split('-').reversed.toList();
  List<String> months = [
    '',
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  separatedDateTime[1] = months[int.parse(separatedDateTime[1])];
  return separatedDateTime.join(' ');
}

String getCleanTimeFormat(String day) {
  return DateFormat('HH:mm').format(DateTime.parse(day).toLocal());
}

String getDateFormat(String day) {
  return DateFormat('yyyy-MM-dd').format(DateTime.parse(day).toLocal());
}

Future<List<MediaDatasClass>> loadMediasDatas(List<dynamic> mediasDatasFromServer) async{
  List<MediaDatasClass> newMediasDatas = [];
  for(int i = 0; i < mediasDatasFromServer.length; i++){
    String mediaUrl = mediasDatasFromServer[i]['url'];
    if(mediasDatasFromServer[i]['mediaType'] == 'video'){
      VideoPlayerController playerController = VideoPlayerController.networkUrl(Uri.parse(mediasDatasFromServer[i]['url']));
      await playerController.initialize();
      Size scaledDimension = getSizeScale(playerController.value.size.width, playerController.value.size.height);
      newMediasDatas.add(MediaDatasClass(
        MediaType.video, mediaUrl, playerController, mediasDatasFromServer[i]['storagePath'],
        MediaSourceType.network, null, scaledDimension
      ));
    }else if(mediasDatasFromServer[i]['mediaType'] == 'image'){
      ui.Image imageDimension = await calculateImageNetworkDimension(mediaUrl);
      Size scaledDimension = getSizeScale(imageDimension.width.toDouble(), imageDimension.height.toDouble());
      newMediasDatas.add(MediaDatasClass(
        MediaType.image, mediaUrl, null, mediasDatasFromServer[i]['storagePath'], 
        MediaSourceType.network, null, scaledDimension
      ));
    }else if(mediasDatasFromServer[i]['mediaType'] == 'websiteCard'){
      WebsiteCardClass linkPreview = await fetchLinkPreview(mediaUrl);
      newMediasDatas.add(MediaDatasClass(
        MediaType.websiteCard, mediaUrl, null, mediasDatasFromServer[i]['storagePath'], 
        MediaSourceType.network, linkPreview, null
      ));
    }
  }
  return newMediasDatas;
}

Future<ui.Image> calculateImageFileDimension(url) async{
  final File imageFile = File(url);
  final Uint8List bytes = await imageFile.readAsBytes();
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(bytes, completer.complete);
  final ui.Image image = await completer.future;
  return image;
}

Future<ui.Image> calculateImageNetworkDimension(url) async{
  Image image = Image.network(url);
  final Completer<ui.Image> completer = Completer<ui.Image>();
  image.image
  .resolve(const ImageConfiguration())
  .addListener(
    ImageStreamListener(
      (ImageInfo info, bool _) => completer.complete(info.image)
    )
  );
  final ui.Image finalImage = await completer.future;
  return finalImage;
}

void doSomethingWithException(Exception exception){
  debugPrint(exception.toString());
}

bool isUserTagged(CustomTextFieldEditingController textController){
  final int cursorPosition = textController.selection.start;
  return cursorPosition > 0 ? textController.text.split('')[cursorPosition - 1] == '@' : false;
}

bool isTextHashtagged(CustomTextFieldEditingController textController){
  final int cursorPosition = textController.selection.start;
  return cursorPosition > 0 ? textController.text.split('')[cursorPosition - 1] == '#' : false;
}

Future<WebsiteCardClass> fetchLinkPreview(String url) async {
  String title = '';
  String imageUrl = defaultWebsiteCardImageLink;
  String domain = '';

  Uri uri = Uri.parse(url);
  domain = uri.host.replaceFirst('www.', '');

  try {
    final response = await http.get(Uri.parse(url));
    final htmlContent = response.body;
    
    html.Document document = parser.parse(htmlContent);
    
    html.Element? titleMetaTag = document.querySelector('meta[property="og:title"]');
    html.Element? imageMetaTag = document.querySelector('meta[property="og:image"]');
    
    title = titleMetaTag?.attributes['content'] ?? '';
    imageUrl = imageMetaTag?.attributes['content'] ?? '';


  } on Exception catch (e) {
    doSomethingWithException(e);
  }
  return WebsiteCardClass(url, title, imageUrl, domain);
}

String displayShortenedCount(int value){
  double dividedValue = 0;
  String lastLetter = '';
  if(value >= 1000000){
    dividedValue = value / 1000000;
    lastLetter = 'M';
  }else if(value >= 10000){
    dividedValue = value / 1000;
    lastLetter = 'K';
  }else{
    return value.toString();
  }
  String valueStr = dividedValue.toString();
  List<String> splitStr = valueStr.split('.');
  if(splitStr.length > 1){
    if(int.parse(splitStr[1][0]) > 0){
      splitStr[1] = splitStr[1][0];
      return '${splitStr.join('.')}$lastLetter';
    }else{
      return '${splitStr[0]}$lastLetter';
    }
  }else{
    return '${splitStr[0]}$lastLetter';
  }
}

void runDelay(Function func, int duration) async{
  Future.delayed(Duration(milliseconds: duration), (){ }).then((value){
    func();
  });
}

PageRouteBuilder generatePageRouteBuilder(RouteSettings? settings, Widget child){
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child
    ) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0), end: Offset.zero
      ).animate(animation), child: child
    )
  );
}

Future<String> downloadAndSaveImage(String imageUrl, String fileName) async{
  http.Response response = await http.get(Uri.parse(imageUrl));
  http.get(Uri.parse(imageUrl));
  Uint8List imageData = response.bodyBytes;

  Directory directory = await getTemporaryDirectory();
  String path = directory.path;

  File file = File('$path/$fileName.png');
  await file.writeAsBytes(imageData);
  return file.path;
}

Future<String> downloadAndSaveVideo(String videoLink, String fileName) async {
  http.Response response = await http.get(Uri.parse(videoLink));
  http.get(Uri.parse(videoLink));
  Uint8List imageData = response.bodyBytes;
  
  Directory directory = await getTemporaryDirectory();
  String path = directory.path;

  File file = File('$path/$fileName.mp4');
  await file.writeAsBytes(imageData);
  return file.path;
}

bool shouldCallSkeleton(LoadingState loadingState){
  return loadingState == LoadingState.loading || loadingState == LoadingState.refreshing;
}