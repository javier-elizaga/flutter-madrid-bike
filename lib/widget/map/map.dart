import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_location/flutter_location.dart';
import 'package:flutter_location/location.dart';
import 'package:flutter_location/permission.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../../services/station_service.dart';
import '../../model/mode.dart';
import '../../model/station.dart';
import '../common/loading.dart';
import 'map_button_toolbar.dart';
import 'map_mode_button.dart';
import 'map_config.dart';
import 'map_utils.dart';

class Map extends StatefulWidget {
  Map({Key key}) : super(key: key);
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> with TickerProviderStateMixin {
  MapController _mapController = MapController();
  Mode _viewMode = Mode.FOOD;
  Permission _locationPermission = Permission.NOT_DETERMINED;
  LatLng _myLocation;
  Stream<Location> _locationStream;
  List<Station> _stations = List();
  double _zoom = MapConfig.init_map_zoom;

  Timer _getStationTimer;
  bool _isLoadingStations = false;

  @override
  void initState() {
    super.initState();
    initStations();
    initLocation();
    initTimer();
  }

  @override
  void dispose() {
    super.dispose();
    _getStationTimer.cancel();
  }

  initTimer() {
    _getStationTimer = Timer.periodic(MapConfig.get_stations_interval, (timer) {
      initStations();
    });
  }

  Future<void> initStations() async {
    try {
      await _initStations();
    } catch (e) {
      print("initStations error: $e");
    }
  }

  Future<void> initLocation() async {
    try {
      await _initLocation();
    } catch (e) {
      print("initLocation error: $e");
    }
  }

  Future<Permission> initPermission() async {
    try {
      return await _initPermission();
    } catch (e) {
      print("initPermission error: $e");
    }
    return Permission.NOT_DETERMINED;
  }

  Future<void> _initStations() async {
    setState(() => this._isLoadingStations = true);
    List<Station> stations = await StationService.getStations();
    setState(() {
      this._stations = stations;
      this._isLoadingStations = false;
    });
  }

  LatLng _toLatLng(Location location) {
    return LatLng(
      location.latitude,
      location.longitude,
    );
  }

  Future<Permission> _initPermission() async {
    Permission permission;
    final _waitForUser = Duration(seconds: 1);
    bool isDetermined = false;
    await FlutterLocation.requestPermission;
    while (!isDetermined) {
      permission = await FlutterLocation.permission;
      if (permission == Permission.NOT_DETERMINED) {
        await Future.delayed(_waitForUser);
      } else {
        isDetermined = true;
      }
    }
    return permission;
  }

  Future<void> _initLocation() async {
    Permission permission = await initPermission();
    LatLng center;
    if (permission == Permission.AUTHORIZED) {
      // we have location permissions
      // initialize center, center of the map to my location
      center = await FlutterLocation.location.then(_toLatLng);
      _initOnLocationChange();
    }
    setState(() {
      this._locationPermission = permission;
      this._myLocation = center;
    });
  }

  void _initOnLocationChange() {
    if (_locationStream == null) {
      _locationStream = FlutterLocation.onLocationChanged;
    }
    _locationStream.listen((location) {
      if (mounted) {
        setState(() => this._myLocation = _toLatLng(location));
      }
    });
  }

  void _moveToMyLocation() async {
    if (_myLocation == null) {
      if (_locationPermission == Permission.AUTHORIZED) {
        LatLng location = await FlutterLocation.location.then(_toLatLng);
        setState(() => this._myLocation = location);
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
      end: MapConfig.init_map_zoom,
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
    final newViewMode = _viewMode == Mode.BIKE ? Mode.FOOD : Mode.BIKE;
    setState(() => this._viewMode = newViewMode);
  }

  List<Marker> _createMapMarkers() {
    List<Marker> markers = List();
    if (_stations != null) {
      markers.addAll(MapUtils.createStationMarkers(
        stations: _stations,
        mode: _viewMode,
        zoom: _zoom,
      ));
    }

    if (_myLocation != null) {
      markers.add(MapUtils.createMyLocationMarker(_myLocation));
      if (_zoom > MapConfig.min_full_icon_zoom) {
        markers.add(MapUtils.createFiveMinMarker(_myLocation, _zoom));
      }
    }
    return markers;
  }

  List<Polyline> _createMapPolyline() {
    List<Polyline> fiveMinWalk = List();
    if (_myLocation != null && _zoom > MapConfig.min_full_icon_zoom) {
      fiveMinWalk = MapUtils.fiveMinWalkPolyline(_myLocation);
    }
    return fiveMinWalk;
  }

  LatLng get mapCenter {
    LatLng mapCenter;
    if (_locationPermission == Permission.AUTHORIZED) {
      mapCenter = _myLocation;
    } else {
      mapCenter = MapUtils.getCenterOf(
        stations: _stations,
        defaultCenter: MapConfig.defaultCenter,
      );
    }
    return mapCenter;
  }

  Widget _buildFlutterMap(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
          center: mapCenter,
          maxZoom: MapConfig.max_map_zoom,
          minZoom: MapConfig.min_map_zoom,
          zoom: MapConfig.init_map_zoom,
          onPositionChanged: (pos) {
            if (mounted &&
                _mapController != null &&
                _zoom != _mapController.zoom) {
              setState(() => this._zoom = _mapController.zoom);
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
        PolylineLayerOptions(polylines: _createMapPolyline()),
        MarkerLayerOptions(markers: _createMapMarkers()),
      ],
    );
  }

  Widget _buildToolButtons(BuildContext context) {
    return SafeArea(
      child: MapButtonToolbar(
        loadStations: initStations,
        moveToMyLocation: _moveToMyLocation,
        locationPermission: _locationPermission,
        isLoadingStations: _isLoadingStations,
      ),
    );
  }

  Widget build(BuildContext context) {
    if (_locationPermission == Permission.NOT_DETERMINED) {
      return Loading();
    }
    if (_locationPermission == Permission.AUTHORIZED && _myLocation == null) {
      return Loading();
    }

    IconData foodModeIcon = Icons.directions_walk;
    IconData bikeModeIcon = Icons.directions_bike;
    Widget floatingAction = MapModeButton(
      icon: Icon(_viewMode == Mode.FOOD ? foodModeIcon : bikeModeIcon),
      onPressed: _toogleViewMode,
    );

    return Scaffold(
      body: Stack(
        children: [
          _buildFlutterMap(context),
          _buildToolButtons(context),
        ],
      ),
      floatingActionButton: floatingAction,
    );
  }
}
