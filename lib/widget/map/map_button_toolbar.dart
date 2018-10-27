import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_location/permission.dart';

import '../common/animated_rotation_icon.dart';

class MapButtonToolbar extends StatefulWidget {
  final Future<void> Function() loadStations;
  final VoidCallback moveToMyLocation;
  final Permission locationPermission;
  final bool isLoadingStations;

  MapButtonToolbar({
    this.loadStations,
    this.moveToMyLocation,
    this.locationPermission,
    this.isLoadingStations,
    Key key,
  }) : super(key: key);

  _MapButtonToolbarState createState() {
    return _MapButtonToolbarState(
      loadStations: loadStations,
      moveToMyLocation: moveToMyLocation,
      locationPermission: locationPermission,
      isLoadingStations: isLoadingStations,
    );
  }
}

class _MapButtonToolbarState extends State<MapButtonToolbar> {
  final Future<void> Function() loadStations;
  final VoidCallback moveToMyLocation;
  final Permission locationPermission;

  bool isLoadingStations;

  _MapButtonToolbarState({
    this.loadStations,
    this.moveToMyLocation,
    this.locationPermission,
    this.isLoadingStations,
  });

  @override
  void didUpdateWidget(MapButtonToolbar oldWidget) {
    setState(() => this.isLoadingStations = widget.isLoadingStations);

    super.didUpdateWidget(oldWidget);
  }

  void _loadStation() async {
    setState(() => this.isLoadingStations = true);
    await widget.loadStations();
    setState(() => this.isLoadingStations = false);
  }

  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).accentColor;
    final disableIconColor = Theme.of(context).disabledColor;
    final buttonColor = Color.fromRGBO(255, 255, 255, .8);
    final borderColor = Theme.of(context).dividerColor;
    final radius = Radius.circular(10.0);
    final decoration = BoxDecoration(
      color: buttonColor,
      borderRadius: BorderRadius.vertical(top: radius, bottom: radius),
      border: Border.all(color: borderColor),
    );

    final fullScreenIcon = locationPermission == Permission.AUTHORIZED
        ? _fullscreenIcon(iconColor)
        : _fullscreenIcon(disableIconColor);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          decoration: decoration,
          margin: EdgeInsets.only(right: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTopToolButton(
                bottomBorderColor: borderColor,
                child: AnimatedRotationIcon(
                  icon: _cachedIcon(iconColor),
                  clockwise: false,
                  doAnimate: isLoadingStations,
                ),
                onPressed: _loadStation,
              ),
              _buildToolButton(
                child: fullScreenIcon,
                onPressed: moveToMyLocation,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Icon _cachedIcon(Color color) {
  return Icon(
    Icons.cached,
    color: color,
  );
}

Icon _fullscreenIcon(Color color) {
  return Icon(
    Icons.center_focus_strong,
    color: color,
  );
}

Widget _buildToolButton({
  Widget child,
  VoidCallback onPressed,
}) {
  return Container(
    child: IconButton(
      icon: child,
      onPressed: onPressed,
    ),
  );
}

Widget _buildTopToolButton({
  Color bottomBorderColor,
  Widget child,
  VoidCallback onPressed,
}) {
  return Container(
    decoration: BoxDecoration(
      border: BorderDirectional(
        bottom: BorderSide(
          color: bottomBorderColor,
        ),
      ),
    ),
    child: IconButton(
      icon: child,
      onPressed: onPressed,
    ),
  );
}
