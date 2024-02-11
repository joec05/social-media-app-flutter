import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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