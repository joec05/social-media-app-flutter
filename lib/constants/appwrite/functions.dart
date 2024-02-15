import 'package:appwrite/appwrite.dart';
import 'package:social_media_app/global_files.dart';

/// Declaring the AppWrite project
Client updateAppWriteClient(){
  final appWriteClient = Client().setEndpoint('https://cloud.appwrite.io/v1').setProject(appWriteUserID).setSelfSigned();
  return appWriteClient;
}

/// Converts image File path to AppWrite's local InputFile file type
InputFile fileToInputFile(String uri, String path) {
  final inputFile = InputFile.fromPath(path: uri, filename: path);
  return inputFile;
}