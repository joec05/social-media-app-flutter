import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';
import 'package:uuid/uuid.dart';

/// Controller used for uploading images and videos to cloud services such as Firebase and AppWrite
class CloudController {

  /// Upload image to AppWrite
  Future<String?> uploadImageToAppWrite(
    BuildContext context,
    String uri
  ) async{
    try {
      String uniqueID = appStateRepo.currentID;
      String bucketID = storageBucketIDs['image'];
      final appWriteStorage = Storage(updateAppWriteClient());
      await appWriteStorage.createFile(
        bucketId: bucketID,
        fileId: uniqueID,
        file: fileToInputFile(uri, uniqueID)
      ).then((response){
        return 'https://cloud.appwrite.io/v1/storage/buckets/$bucketID/files/$uniqueID/view?project=$appWriteUserID&mode=admin';
      });
    } catch (e) {
      if(context.mounted) {
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          tErr.appwrite
        );
      }
      return null;
    }
    return null;
  }

  /// Upload video to Firebase
  Future<String?> uploadVideoToFirebase(
    BuildContext context,
    String url
  ) async {
    try {
      File mediaFilePath = File(url);
      FirebaseStorage storage = FirebaseStorage.instance;
      String childDirectory = '/${appStateRepo.currentID}/${const Uuid().v4()}';
      Reference ref = storage.ref('/videos').child(childDirectory);
      UploadTask uploadTask = ref.putFile(mediaFilePath, SettableMetadata(contentType: 'video/mp4'));
      var mediaUrl = await (await uploadTask).ref.getDownloadURL();      
      return mediaUrl.toString();
    } catch (e) {
      if(context.mounted) {
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          tErr.appwrite
        );
      }
      return null;
    }
  }
}

final cloudController = CloudController();