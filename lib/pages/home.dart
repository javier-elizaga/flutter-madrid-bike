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
import 'package:flutter_location/location.dart';

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
  static final _userId = 'WEB.SERV.javier.elizaga@gmail.com';
  static final _userPassword = 'F3D2D9FB-0109-490E-89EB-1042C20116F1';
  static get stationsUrl => '$_server/getstations/$_userId/$_userPassword';
}

class HomePage extends StatefulWidget {
  static const route = '/';
  @override
  _HomePageState createState() => _HomePageState();
}

const double max_zoom = 17.0;
const double def_zoom = 15.0;
const double five_min_zoom = 15.0;
const double bike_pin_size = 30.0;
const double bike_icon_size = 20.0;
const double circle_pin_size = 10.0;

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
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

  double _zoom = def_zoom;

  @override
  void initState() {
    super.initState();
    initStations();
    initLocations();
  }

  void initStations() {
    try {
      _initStations();
    } catch (e) {
      print('IS :: $e');
    }
  }

  void initLocations() {
    try {
      _initLocation();
    } catch (e) {
      print('IL :: $e');
    }
  }

  void _initStations() async {
    print('IS :: Initializing stations');
    print('IS :: $mounted');
    setState(() => _loadingStations = true);
    List<Station> stations = await StationService.getStations();
    print('IS :: ${stations.length} stations found');
    print('IS :: $mounted');
    setState(() {
      _stations = stations;
      _loadingStations = false;
    });
  }

  void _initLocation() async {
    print('IL :: Initializing location');
    Permission locationPermission;
    locationPermission = await FlutterLocation.permissionLevel;
    if (locationPermission == Permission.NOT_DETERMINED) {
      print('IL :: Location not_determined, waiting...');
      // Waiting for the user to authorized or denied permission
      return await Future.delayed(Duration(seconds: 1), _initLocation);
    }
    LatLng center;
    if (locationPermission == Permission.AUTHORIZED) {
      print('IL :: Location authorized');
      // we have location permissions
      // initialize center, center of the map to my location
      Location location = await FlutterLocation.location;
      center = toLatLng(location);
      print('IL :: center: $center');
      _initializeOnLocationChange();
    }
    print('IL :: $mounted');
    setState(() {
      _center = center;
      _locationPermission = locationPermission;
    });
  }

  void _initializeOnLocationChange() {
    print('IOLC :: Initializing on location changed');
    FlutterLocation.onLocationChanged.listen((Location newLocation) {
      if (mounted) {
        print('IOLC :: $mounted');
        setState(() => _myLocation = toLatLng(newLocation));
      }
    });
  }

  void _moveToMyLocation() async {
    if (_myLocation == null) {
      print('MTML :: myLocation is null');
      if (_locationPermission == Permission.AUTHORIZED) {
        print('MTML :: getting my location');
        Location location = await FlutterLocation.location;
        print('MTML :: $mounted');
        setState(() => _myLocation = toLatLng(location));
      }
    }
    if (_myLocation != null) {
      _moveToLocationAnimated(_myLocation);
    }
  }

  void _moveToLocationAnimated(LatLng newLocation) {
    AnimationController _controller;
    Animation<double> _animation;
    LatLng oldLocation;
    Tween<double> latTween, lngTween, zoomTween;

    oldLocation = LatLng(
      _mapController.center.latitude,
      _mapController.center.longitude,
    );
    latTween = Tween<double>(
      begin: oldLocation.latitude,
      end: newLocation.latitude,
    );
    lngTween = Tween<double>(
      begin: oldLocation.longitude,
      end: newLocation.longitude,
    );
    zoomTween = Tween<double>(
      begin: _mapController.zoom,
      end: def_zoom,
    );
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear)
      ..addListener(() {
        _mapController.move(
            LatLng(
              latTween.evaluate(_animation),
              lngTween.evaluate(_animation),
            ),
            zoomTween.evaluate(_animation));
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          _controller.dispose();
        }
      });
    _controller.forward();
  }

  void _toogleViewMode() {
    final newViewMode = this._viewMode == Mode.BIKE ? Mode.FOOD : Mode.BIKE;
    print(' TVM :: $mounted');
    setState(() => this._viewMode = newViewMode);
  }

  Widget _buildFlutterMap() {
    List<Marker> markers;
    markers = createMarkers(
      stations: _stations ?? List(),
      mode: _viewMode,
      circleLoc: _myLocation,
      zoom: _zoom,
    );
    List<CircleMarker> circles;
    circles = createCircles(_myLocation, _zoom);
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
          onPositionChanged: (pos) {
            if (mounted &&
                _mapController != null &&
                _zoom != _mapController.zoom) {
              setState(() {
                _zoom = _mapController.zoom;
              });
            }
          }),
      layers: [
        TileLayerOptions(
          urlTemplate: MapConfig.urlTemplate,
          additionalOptions: {
            'accessToken': MapConfig.token,
            'id': 'mapbox.streets',
          },
        ),
        CircleLayerOptions(circles: circles),
        MarkerLayerOptions(markers: markers),
      ],
    );
  }

  Widget _buildMapScaffold(BuildContext context) {
    print('BMS :: Building scaffold $_locationPermission');
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

// utils
List<Marker> createMarkers({
  List<Station> stations,
  Mode mode,
  LatLng circleLoc,
  double zoom,
}) {
  double normalized = zoom - 11.0;
  if (normalized < 1.0) {
    normalized = 1.0;
  }
  double pinSize = normalized * 6;
  double iconSize = pinSize / 1.5;

  if (iconSize < 8.0) {
    iconSize = 0.0;
  }
  List<Marker> markers = List();
  markers.addAll(stations.map((station) {
    return Marker(
      width: pinSize,
      height: pinSize,
      point: station.latLng,
      builder: (context) {
        return MapBikePin.fromStationAndMode(
          station: station,
          mode: mode,
          size: iconSize,
        );
      },
    );
  }).toList());

  if (circleLoc != null) {
    markers.add(Marker(
      width: circle_pin_size,
      height: circle_pin_size,
      point: circleLoc,
      builder: (context) {
        return MapIconCircle(size: circle_pin_size);
      },
    ));
  }
  return markers;
}

List<CircleMarker> createCircles(LatLng location, double zoom) {
  List<CircleMarker> circles = List();
  if (location == null || zoom < five_min_zoom) {
    print('location $location, zoom: $zoom');
    return circles;
  }
  final fiveMin = LatLng(0.0035, 0.0044);
  double x = 0.0;
  int numOfPoints = 256;
  double increment = 2 * pi / numOfPoints;
  while (x < (2 * pi)) {
    x += increment;
    circles.add(CircleMarker(
      point: LatLng(
        fiveMin.latitude * sin(x) + location.latitude,
        fiveMin.longitude * cos(x) + location.longitude,
      ),
      radius: 1.0,
      color: Colors.indigo,
    ));
  }
  return circles;
}

LatLng toLatLng(Location location) {
  return LatLng(
    location.latitude,
    location.longitude,
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
