import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class APICallRepository {
  var dio = Dio();
  Future<dynamic> runAPICall(
    BuildContext context,
    dynamic call,
    Map data 
  ) async{
    try {
      late Response res;
      if (call is RequestPost) {
        res = await _runAPIPost(call, data);
      }else if (call is RequestPatch){
        res = await _runAPIPatch(call, data);
      }else if (call is RequestGet){
        res = await _runAPIGet(call, data);
      }else if(call is RequestDelete){
        res = await _runAPIDelete(call, data);
      }
      if(res.data != null){
        return res.data;
      }else{
        if(context.mounted){
          handler.displaySnackbar(
            context,
            SnackbarType.error, 
            tErr.api
          );
        }
        return null;
      }
    } catch (_) {
      if(context.mounted){
        handler.displaySnackbar(
          context,
          SnackbarType.error, 
          tErr.api
        );
      }
      return null;
    }
  }

  Future<Response> _runAPIGet(
    RequestGet call,
    Map data
  ) async{
    var request = await dio.get(
      '$serverDomainAddress/users/${call.name}',
      data: jsonEncode(data)
    );
    return request;
  }

  Future<Response> _runAPIPatch(
    RequestPatch call,
    Map data
  ) async{
    var request = await dio.patch(
      '$serverDomainAddress/users/${call.name}',
      data: jsonEncode(data)
    );
    return request;
  }

  Future<Response> _runAPIPost(
    RequestPost call,
    Map data
  ) async{
    var request = await dio.post(
      '$serverDomainAddress/users/${call.name}',
      data: jsonEncode(data)
    );
    return request;
  }

  Future<Response> _runAPIDelete(
    RequestDelete call,
    Map data
  ) async{
    var request = await dio.delete(
      '$serverDomainAddress/users/${call.name}',
      data: jsonEncode(data)
    );
    return request;
  }
}

final apiCallRepo = APICallRepository();