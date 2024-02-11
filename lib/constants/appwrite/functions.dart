import 'package:appwrite/appwrite.dart';
import 'package:social_media_app/global_files.dart';

Client updateAppWriteClient(){
  final appWriteClient = Client().setEndpoint('https://cloud.appwrite.io/v1').setProject(appWriteUserID).setSelfSigned();
  return appWriteClient;
}

InputFile fileToInputFile(String uri, String path) {
  final inputFile = InputFile.fromPath(path: uri, filename: path);
  return inputFile;
}