import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class FetchDataRepository {
  FetchDataSource source = FetchDataSource.api;

  Future<dynamic> fetchData(
    BuildContext context,
    dynamic call,
    Map data 
  ) async{
    if(source == FetchDataSource.api) {
      return await apiCallRepo.runAPICall(
        context, 
        call, 
        data
      );
    }else if(source == FetchDataSource.dummy) {
      return dummyCallRepo.runDummyCall(
        call,
        data
      );
    }
  }
}

final fetchDataRepo = FetchDataRepository();