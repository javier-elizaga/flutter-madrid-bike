import 'dart:async';
import 'dart:math';

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
  static final _userId = 'WEB.SERV.javier.elizaga@gmail.com';
  static final _userPassword = 'F3D2D9FB-0109-490E-89EB-1042C20116F1';
  static get stationsUrl => '$_server/get_stations/$_userId/$_userPassword';
}

const double max_zoom = 17.0;
const double def_zoom = 15.0;
const double bikePinSize = 30.0;
const double circlePinSize = 20.0;

class HomePage extends StatefulWidget {
  static const route = '/';
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // BiciMad stations
  Future<List<Station>> _stations;

  // Center of the map on load
  Future<LatLng> _center;

  // Location of user in map
  LatLng _myLocation;

  // ViewMode: food, bike, defaul food
  Mode viewMode = Mode.FOOD;

  bool _loadingStations = false;

  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initStations();
    _initLocation();
  }

  void _initStations() async {
    try {
      setState(() {
        _loadingStations = true;
      });
      List<Station> stations = await StationService.getStations();
      print('initStations.stations: ${stations.length}');
      if (mounted) {
        setState(() {
          _stations = Future.value(stations);
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
    } else if (locationPermission == Permission.DENIED) {
      return null;
    }

    // we have location permissions
    // initialize myLocation, center of the map to my location
    LatLng myLocation;
    try {
      myLocation = _toLatLng(await FlutterLocation.location);
    } catch (e) {
      print('Fail to locate user: $e');
    }
    _initializeOnLocationChange();
    if (mounted) {
      setState(() {
        _center = Future.value(myLocation);
      });
    }
  }

  void _initializeOnLocationChange() {
    FlutterLocation.onLocationChange.map((l) {
      return _toLatLng(l);
    }).listen((myLocation) {
      if (mounted) {
        setState(() {
          _myLocation = myLocation;
        });
      }
    });
  }

  LatLng _toLatLng(Map location) {
    return LatLng(
      location['latitude'],
      location['longitude'],
    );
  }

  LatLng _getStationsCenter(List<Station> stations) {
    double mean(double a, double b) => (a + b) / 2;
    double minLat, maxLat;
    double minLng, maxLng;
    stations.forEach((s) {
      minLat = min(minLat ?? s.latitude, s.latitude);
      maxLat = max(maxLat ?? s.latitude, s.latitude);
      minLng = min(minLng ?? s.longitude, s.longitude);
      maxLng = max(maxLng ?? s.longitude, s.longitude);
    });
    return stations.isNotEmpty
        ? LatLng(mean(maxLat, minLat), mean(maxLng, minLng))
        : LatLng(40.4277841, -3.6981178);
  }

  List<Marker> _markers(List<Station> stations, LatLng location, Mode mode) {
    List<Marker> markers = stations
        .map((s) => Marker(
              width: bikePinSize,
              height: bikePinSize,
              point: LatLng(s.latitude, s.longitude),
              builder: (context) => MapBikePin.fromStationAndMode(s, mode),
            ))
        .toList();

    if (location != null) {
      markers.add(Marker(
        width: circlePinSize,
        height: circlePinSize,
        point: location,
        builder: (context) => MapIconCircle(size: circlePinSize),
      ));
    }
    return markers;
  }

  void _moveToMyLocation() {
    if (_myLocation != null) {
      _mapController.move(_myLocation, def_zoom);
    }
  }

  Widget _buildMapWidget(
      BuildContext context, List<Station> stations, LatLng center, Mode mode) {
    List<Marker> markers = _markers(stations, _myLocation, mode);
    LatLng mapCenter = center ?? _getStationsCenter(stations);
    final map = Stack(
      children: <Widget>[
        FlutterMap(
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
        ),
        _buildToolButtons(context)
      ],
    );
    return Scaffold(
      body: map,
      floatingActionButton: FloatingActionButton(
        tooltip: 'mode',
        child: Icon(
          mode == Mode.BIKE ? Icons.directions_bike : Icons.directions_walk,
        ),
        onPressed: () {
          setState(() {
            this.viewMode = this.viewMode == Mode.BIKE ? Mode.FOOD : Mode.BIKE;
          });
        },
      ),
    );
  }

  Widget _buildToolButton({Color color, Widget child, VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
      ),
      child: IconButton(
        padding: EdgeInsets.all(0.0),
        icon: child,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildToolButtons(BuildContext context) {
    Color buttonColor = Color.fromRGBO(255, 255, 255, .8);
    Icon refresh = Icon(
      Icons.refresh,
      size: 30.0,
      color: Theme.of(context).iconTheme.color,
    );
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin: EdgeInsets.only(
              right: 10.0,
            ),
            child: Column(
              children: [
                _buildToolButton(
                  color: buttonColor,
                  child: AnimatedRotationIcon(
                    icon: refresh,
                    doAnimate: _loadingStations,
                  ),
                  onPressed: _initStations,
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 5.0),
                ),
                _buildToolButton(
                  color: buttonColor,
                  child: Icon(
                    _myLocation != null
                        ? Icons.my_location
                        : Icons.location_disabled,
                    size: 30.0,
                  ),
                  onPressed: _moveToMyLocation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Future<Map<String, dynamic>> _loadPage() {
      return Future.wait([_stations, _center]).then((res) {
        return {
          'stations': res[0],
          'center': res[1],
        };
      });
    }

    Widget _buildPage(BuildContext context, AsyncSnapshot<Map> snapshot) {
      return snapshot.hasData
          ? _buildMapWidget(
              context,
              snapshot.data['stations'],
              snapshot.data['center'],
              viewMode,
            )
          : Loading();
    }

    return FutureBuilder(
        future: _loadPage(),
        builder: (context, AsyncSnapshot<Map> snapshot) {
          return _buildPage(context, snapshot);
        });
  }
}
