import 'package:intl/intl.dart';

/// Returns the time difference between the DateTime now and the given DateTime in text form
/// Examples include '5 minutes ago', '1 day ago', '10 months ago'
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

/// Returns something like '5 Mar 2019' from a given DateTime in text form
String convertDateTimeDisplay(String dateTime){
  List<String> separatedDateTime = DateTime.parse(dateTime).toLocal().toIso8601String().substring(0, 10).split('-').reversed.toList();
  List<String> months = [
    '',
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  separatedDateTime[1] = months[int.parse(separatedDateTime[1])];
  return separatedDateTime.join(' ');
}

/// Returns a date of HH:mm format in text form from a given DateTime in text form
String getCleanTimeFormat(String day) {
  return DateFormat('HH:mm').format(DateTime.parse(day).toLocal());
}

/// Returns a date of yyyy-MM-dd format in text form from a given DateTime in text form
String getDateFormat(String day) {
  return DateFormat('yyyy-MM-dd').format(DateTime.parse(day).toLocal());
}