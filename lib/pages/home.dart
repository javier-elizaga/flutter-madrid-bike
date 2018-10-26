import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../services/station_service.dart';
import '../model/station.dart';
import '../model/mode.dart';
import '../widget/map/map_bike_pin.dart';
import '../widget/map/map_icon_circle.dart';
import '../widget/common/loading.dart';
import '../widget/common/animated_rotation_icon.dart';

import 'package:flutter_location/flutter_location.dart';
import 'package:flutter_location/permission.dart';

class MapConfig {
  // flutter map
  static final urlTemplate =
      'https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}';
  static final token =
      'pk.eyJ1IjoiamF2aWVyLWVsaXphZ2EiLCJhIjoiY2puYncwam9qMXRkYzN4cmZub3I3NW5mbCJ9.bnp4_s-Tyf2g6NgOw6w3yw';
}

class BiciMadConfig {
  // bicimad
  static final _server = 'https://rbdata.emtmadrid.es:8443/BiciMad';
  static final _userId = '<add user id>';
  static final _userPassword = '<add user password>';
  static get stationsUrl => '$_server/getstations/$_userId/$_userPassword';
}

const double max_zoom = 17.0;
const double def_zoom = 15.0;

class HomePage extends StatefulWidget {
  static const route = '/';
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // BiciMad stations
  List<Station> _stations = List();

  // Center of the map on load
  LatLng _center;

  // Location of user in map
  LatLng _myLocation;

  // Location permission user in map
  Permission _locationPermission = Permission.NOT_DETERMINED;

  // ViewMode: food, bike, defaul food
  Mode _viewMode = Mode.FOOD;

  bool _loadingStations = true;

  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initStations();
    _initLocation();
  }

  void _initStations() async {
    try {
      setState(() => _loadingStations = true);
      List<Station> stations = await StationService.getStations();
      if (mounted) {
        setState(() {
          _stations = stations;
          _loadingStations = false;
        });
      }
    } catch (e) {
      print("initStations.error: $e");
    }
  }

  void _initLocation() async {
    Permission locationPermission;
    locationPermission = await FlutterLocation.permissionLevel;
    if (locationPermission == Permission.NOT_DETERMINED) {
      // Waiting for the user to authorized or denied permission
      return await Future.delayed(Duration(seconds: 1), _initLocation);
    }
    LatLng myLocation;
    if (locationPermission == Permission.AUTHORIZED) {
      // we have location permissions
      // initialize myLocation, center of the map to my location
      try {
        myLocation = await FlutterLocation.location.then(toLatLng);
      } catch (e) {
        print('Fail to locate user: $e');
      }
      _initializeOnLocationChange();
    }
    if (mounted) {
      setState(() {
        _center = myLocation;
        _locationPermission = locationPermission;
      });
    }
  }

  void _initializeOnLocationChange() {
    FlutterLocation.onLocationChange.map((l) {
      return toLatLng(l);
    }).listen((myLocation) {
      if (mounted) {
        setState(() => _myLocation = myLocation);
      }
    });
  }

  void _moveToMyLocation() {
    if (_myLocation != null) {
      _mapController.move(_myLocation, def_zoom);
    }
  }

  void _toogleViewMode() {
    setState(() {
      this._viewMode = this._viewMode == Mode.BIKE ? Mode.FOOD : Mode.BIKE;
    });
  }

  Widget _buildFlutterMap() {
    List<Marker> markers =
        createMarkers(_stations ?? List(), _viewMode, _myLocation);
    LatLng mapCenter;
    if (_locationPermission == Permission.AUTHORIZED) {
      mapCenter = _center;
    } else {
      mapCenter = getStationsCenter(_stations ?? List());
    }
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: mapCenter,
        zoom: def_zoom,
        maxZoom: max_zoom,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: MapConfig.urlTemplate,
          additionalOptions: {
            'accessToken': MapConfig.token,
            'id': 'mapbox.streets',
          },
        ),
        MarkerLayerOptions(markers: markers)
      ],
    );
  }

  Widget _buildMapScaffold(BuildContext context) {
    if (_locationPermission == Permission.NOT_DETERMINED) {
      return Loading();
    }

    final map = Stack(
      children: <Widget>[
        _buildFlutterMap(),
        _buildToolButtons(context),
      ],
    );

    IconData directionsBike = Icons.directions_bike;
    IconData localParking = Icons.local_parking;

    final floatingAction = FloatingActionButton(
      child: Icon(_viewMode == Mode.BIKE ? directionsBike : localParking),
      onPressed: _toogleViewMode,
      backgroundColor: Theme.of(context).accentColor,
    );

    return Scaffold(
      body: map,
      floatingActionButton: floatingAction,
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

  Widget _buildToolButtons(BuildContext context) {
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
    final buttonTool = Row(
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
                  icon: _iosRefreshIcon(iconColor),
                  doAnimate: _loadingStations,
                ),
                onPressed: _initStations,
              ),
              _buildToolButton(
                child: _locationPermission == Permission.AUTHORIZED
                    ? _iosLocationIcon(iconColor)
                    : _iosLocationIcon(disableIconColor),
                onPressed: _moveToMyLocation,
              ),
            ],
          ),
        ),
      ],
    );

    return SafeArea(child: buttonTool);
  }

  Icon _iosRefreshIcon(Color color) {
    return Icon(
      const IconData(
        0xf49a,
        fontFamily: CupertinoIcons.iconFont,
        fontPackage: CupertinoIcons.iconFontPackage,
      ),
      color: color,
    );
  }

  RotatedIcon _iosLocationIcon(Color color) {
    return RotatedIcon(
      icon: Icon(
        IconData(
          0xf398,
          fontFamily: CupertinoIcons.iconFont,
          fontPackage: CupertinoIcons.iconFontPackage,
        ),
        color: color,
      ),
      rotation: 0.1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMapScaffold(context);
  }
}

const double bikePinSize = 30.0;
const double circlePinSize = 20.0;

List<Marker> createMarkers(
  List<Station> stations,
  Mode mode,
  LatLng myLocation,
) {
  List<Marker> markers = List();

  markers.addAll(stations.map((s) {
    return Marker(
      width: bikePinSize,
      height: bikePinSize,
      point: s.latLng,
      builder: (context) => MapBikePin.fromStationAndMode(s, mode),
    );
  }).toList());

  if (myLocation != null) {
    markers.add(Marker(
      width: circlePinSize,
      height: circlePinSize,
      point: myLocation,
      builder: (context) => MapIconCircle(size: circlePinSize),
    ));
  }
  return markers;
}

LatLng toLatLng(Map location) {
  return LatLng(
    location['latitude'],
    location['longitude'],
  );
}

LatLng getStationsCenter(List<Station> stations) {
  if (stations.isEmpty) {
    return LatLng(40.4277841, -3.6981178);
  }

  double mean(double a, double b) => (a + b) / 2;
  double minLat, maxLat;
  double minLng, maxLng;
  stations.forEach((s) {
    minLat = min(minLat ?? s.latitude, s.latitude);
    maxLat = max(maxLat ?? s.latitude, s.latitude);
    minLng = min(minLng ?? s.longitude, s.longitude);
    maxLng = max(maxLng ?? s.longitude, s.longitude);
  });
  return LatLng(mean(maxLat, minLat), mean(maxLng, minLng));
}
