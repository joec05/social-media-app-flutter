import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';
import 'package:uuid/uuid.dart';

class CloudController {
  Future<String> uploadImageToAppWrite(
    BuildContext context,
    String uri
  ) async{
    String loadedUri = '';
    String uniqueID = appStateClass.currentID;
    String bucketID = storageBucketIDs['image'];
    final appWriteStorage = Storage(updateAppWriteClient());
    await appWriteStorage.createFile(
      bucketId: bucketID,
      fileId: uniqueID,
      file: fileToInputFile(uri, uniqueID)
    ).then((response){
      loadedUri = 'https://cloud.appwrite.io/v1/storage/buckets/$bucketID/files/$uniqueID/view?project=$appWriteUserID&mode=admin';
    })
    .catchError((_) {
      if(context.mounted) {
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          tErr.appwrite
        );
      }
    });
    return loadedUri;
  }

  Future<String> uploadVideoToFirebase(
    BuildContext context,
    String url
  ) async {
    String storageUrl = '';
    try {
      File mediaFilePath = File(url);
      FirebaseStorage storage = FirebaseStorage.instance;
      String childDirectory = '/${appStateClass.currentID}/${const Uuid().v4()}';
      Reference ref = storage.ref('/videos').child(childDirectory);
      UploadTask uploadTask = ref.putFile(mediaFilePath, SettableMetadata(contentType: 'video/mp4'));
      var mediaUrl = await (await uploadTask).ref.getDownloadURL();
      storageUrl = mediaUrl.toString();
    } catch (e) {
      if(context.mounted) {
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          tErr.appwrite
        );
      }
    }
    return storageUrl;
  }
}

final cloudController = CloudController();