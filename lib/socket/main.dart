import 'package:social_media_app/appdata/global_library.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

io.Socket socket = io.io(serverDomainAddress, <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': false
});

