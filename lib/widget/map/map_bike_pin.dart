import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const toogle_number_icon_duration = Duration(seconds: 2);

/*
 * MapBikePin is an icon that switch from icon to number on tab 
 */
class MapBikePin extends StatefulWidget {
  final IconData icon;
  final int number;
  final double size;
  final Color color;

  MapBikePin({
    this.icon,
    this.number,
    this.size,
    this.color,
    Key key,
  }) : super(key: key);

  _MapBikePinState createState() {
    return _MapBikePinState(
      color: color,
      icon: icon,
      number: number,
      size: size,
    );
  }
}

class _MapBikePinState extends State<MapBikePin> {
  final Color color;
  final IconData icon;
  final int number;
  final double size;

  _MapBikePinState({
    this.color,
    this.icon,
    this.number,
    this.size,
  });

  bool showNumber = false;

  Widget _icon() {
    return Icon(
      icon,
      color: Colors.white,
      size: size,
    );
  }

  Widget _numberIcon() {
    return Center(
      child: Text(
        number.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size,
        ),
      ),
    );
  }

  void _onTap() async {
    setState(() => showNumber = true);
    await Future.delayed(toogle_number_icon_duration);
    // after 2 seconds it is posible the widget is no longer mounted
    if (this.mounted) {
      setState(() => showNumber = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (showNumber) {
      child = _numberIcon();
    } else {
      child = _icon();
    }
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: child,
      ),
    );
  }
}
