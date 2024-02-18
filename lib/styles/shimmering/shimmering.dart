import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';

Widget shimmerSkeletonWidget(Widget child){
  return Shimmer.fromColors(
    baseColor: Colors.grey.withOpacity(0.5),
    highlightColor: const Color.fromARGB(179, 167, 155, 155),
    child: child
  );
}