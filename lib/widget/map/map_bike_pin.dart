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

  double _innerSize;

  _MapBikePinState({
    this.color,
    this.icon,
    this.number,
    this.size,
  }) {
    _innerSize = size / 1.1;
  }

  bool showNumber = false;

  Widget _wrapInCircle(Widget child) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      height: size,
      width: size,
      child: child,
    );
  }

  Widget _icon() {
    final child = Icon(
      icon,
      color: Colors.white,
      size: _innerSize,
    );
    return _wrapInCircle(child);
  }

  Widget _numberIcon() {
    final child = Center(
      child: Text(
        '$number',
        style: TextStyle(
          color: Colors.white,
          fontSize: _innerSize,
        ),
      ),
    );
    return _wrapInCircle(child);
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
    return InkWell(
      onTap: _onTap,
      child: child,
    );
  }
}
