import 'package:flutter/material.dart';

class MapFiveMinIcon extends StatelessWidget {
  final double size;
  final Color color;

  const MapFiveMinIcon({
    Key key,
    this.size = 50.0,
    this.color = Colors.white,
  }) : super(key: key);

  Widget _buildPin(double size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Icon(
        Icons.directions_walk,
        size: size,
      ),
    );
  }

  Widget build(BuildContext context) {
    return _buildPin(size);
  }
}
