import 'package:intl/intl.dart';

String getTimeDifference(String day) {
  DateTime? dateTime = DateTime.parse(day).toLocal();
  Duration difference = DateTime.now().difference(dateTime);
  if (difference.inSeconds < 60) {
    return '${difference.inSeconds} seconds ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else if(difference.inDays < 31){
    return '${difference.inDays} days ago';
  } else if(difference.inDays < 365){
    return '${(difference.inDays / 30).floor()} months ago';
  } else {
    return '${(difference.inDays / 365).floor()} years ago';
  }
}

String convertDateTimeDisplay(String dateTime){
  List<String> separatedDateTime = DateTime.parse(dateTime).toLocal().toIso8601String().substring(0, 10).split('-').reversed.toList();
  List<String> months = [
    '',
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  separatedDateTime[1] = months[int.parse(separatedDateTime[1])];
  return separatedDateTime.join(' ');
}

String getCleanTimeFormat(String day) {
  return DateFormat('HH:mm').format(DateTime.parse(day).toLocal());
}

String getDateFormat(String day) {
  return DateFormat('yyyy-MM-dd').format(DateTime.parse(day).toLocal());
}