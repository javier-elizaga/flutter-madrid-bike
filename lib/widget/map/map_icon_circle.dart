import 'package:flutter/material.dart';

class MapIconCircle extends StatelessWidget {
  final double size;
  final Color color;

  const MapIconCircle(
      {Key key,
      this.size = 50.0,
      this.color = const Color.fromRGBO(67, 133, 245, .9)})
      : super(key: key);

  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
