import 'package:flutter/material.dart';

class MapFiveMinIcon extends StatelessWidget {
  final double size;
  final Color _labelColor = Colors.white54;

  MapFiveMinIcon({Key key, this.size}) : super(key: key);

  double get iconSize => size / 2;
  double get fontSize => iconSize / 2.5;
  bool get showText => iconSize > 15;

  Widget _buildPin(BuildContext context) {
    return Icon(
      Icons.directions_walk,
      size: iconSize,
    );
  }

  Widget _buildTextLabel(BuildContext context, String textValue) {
    final style = TextStyle(fontSize: fontSize);
    final text = Text(
      textValue,
      style: style,
    );
    final label = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(200.0)),
        color: _labelColor,
      ),
      padding: EdgeInsets.only(
        left: 5.0,
        right: 5.0,
      ),
      child: text,
    );
    return label;
  }

  Widget _buildIconWithText(BuildContext context) {
    final widgets = [_buildPin(context), Container(height: 3.0)];
    if (showText) {
      widgets..add(_buildTextLabel(context, '5 min'));
    } else {
      widgets..add(Container(height: fontSize));
    }

    Widget child = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: widgets,
    );

    return child;
  }

  Widget build(BuildContext context) {
    return _buildIconWithText(context);
  }
}
