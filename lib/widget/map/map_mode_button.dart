import 'package:flutter/material.dart';

class MapModeButton extends StatelessWidget {
  final Icon icon;
  final VoidCallback onPressed;

  MapModeButton({this.icon, this.onPressed, Key key}) : super(key: key);

  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: icon,
      onPressed: onPressed,
      backgroundColor: Theme.of(context).accentColor,
    );
  }
}
