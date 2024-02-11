import 'package:social_media_app/global_files.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

io.Socket socket = io.io(serverDomainAddress, <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': false
});

