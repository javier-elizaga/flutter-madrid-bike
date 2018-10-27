import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../model/station.dart';
import '../../model/mode.dart';

/*
 * MapBikePin is an icon that switch from icon to number on tab 
 */
class MapBikePin extends StatefulWidget {
  final IconData icon;
  final int number;
  final double size;

  final Color green;
  final Color amber;
  final Color red;
  final Color grey;

  final int greenLimit;
  final int amberLimit;
  final int redLimit;
  final int greyLimit;

  MapBikePin({
    this.icon,
    this.number,
    this.size = 20.0,
    this.green = Colors.green,
    this.amber = Colors.amber,
    this.red = Colors.red,
    this.grey = Colors.grey,
    this.greenLimit = 4,
    this.amberLimit = 3,
    this.redLimit = 1,
    this.greyLimit = 0,
    Key key,
  }) : super(key: key);

  static IconData directionsBike = Icons.directions_bike;
  static IconData localParking = Icons.local_parking;

  factory MapBikePin.fromStationAndMode({
    Station station,
    Mode mode,
    double size,
  }) {
    Key key = Key('station_${mode.index}_${station.id}_$size');
    return MapBikePin(
      icon: mode == Mode.FOOD ? directionsBike : localParking,
      number: mode == Mode.FOOD ? station.dockBikes : station.freeBases,
      size: size,
      key: key,
    );
  }
  _MapBikePinState createState() {
    Color color = _color();
    return _MapBikePinState(
      color: color,
      icon: icon,
      number: number,
      size: size,
    );
  }

  Color _color() {
    Color color;
    if (number >= greenLimit) {
      color = green;
    } else if (number >= amberLimit) {
      color = Colors.amber;
    } else if (number >= redLimit) {
      color = Colors.red;
    } else if (number >= greyLimit) {
      color = Colors.grey;
    } else {
      color = Colors.white;
    }
    return color;
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

  // state
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
    if (showNumber) {
      return;
    }
    setState(() {
      showNumber = true;
    });
    Future.delayed(Duration(seconds: 2)).then((val) {
      // after 2 seconds it is posible the widget is no longer mounted
      if (this.mounted) {
        setState(() {
          showNumber = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: showNumber ? _numberIcon() : _icon(),
      ),
    );
  }
}
