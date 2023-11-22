import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

IO.Socket socket = IO.io(serverDomainAddress, <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': false
});

