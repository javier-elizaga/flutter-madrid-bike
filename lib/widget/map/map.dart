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
  double _zoom = MapConfig.def_zoom;

  Timer _autoFetchStations;
  bool _isLoadingStations = false;

  @override
  void initState() {
    super.initState();
    initStations();
    initLocations();
    initTimer();
  }

  @override
  void dispose() {
    super.dispose();
    _autoFetchStations.cancel();
  }

  initTimer() {
    _autoFetchStations = Timer.periodic(MapConfig.fetchStationsEvery, (timer) {
      initStations();
    });
  }

  Future<void> initStations() async {
    try {
      await _initStations();
    } catch (e) {}
  }

  Future<void> _initStations() async {
    setState(() => this._isLoadingStations = true);
    List<Station> stations = await StationService.getStations();
    setState(() {
      this._stations = stations;
      this._isLoadingStations = false;
    });
  }

  Future<void> initLocations() async {
    try {
      await _initLocation();
    } catch (e) {}
    return;
  }

  LatLng _toLatLng(Location location) {
    return LatLng(
      location.latitude,
      location.longitude,
    );
  }

  Future<void> _initLocation() async {
    Permission locationPermission;
    locationPermission = await FlutterLocation.permissionLevel;
    if (locationPermission == Permission.NOT_DETERMINED) {
      // Waiting for the user to authorized or denied permission
      return await Future.delayed(Duration(seconds: 1), _initLocation);
    }
    LatLng center;
    if (locationPermission == Permission.AUTHORIZED) {
      // we have location permissions
      // initialize center, center of the map to my location
      center = await FlutterLocation.location.then(_toLatLng);
      _initOnLocationChange();
    }
    setState(() {
      this._locationPermission = locationPermission;
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
      end: MapConfig.def_zoom,
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

  Widget _buildFlutterMap(BuildContext context) {
    List<Marker> markers = List();
    List<Polyline> fiveMinWalk = List();
    if (_stations != null) {
      markers.addAll(MapUtils.createStationMarkers(
        stations: _stations,
        mode: _viewMode,
        zoom: _zoom,
      ));
    }
    if (_myLocation != null) {
      markers.add(MapUtils.createMyLocationMarker(_myLocation));
      if (_zoom > MapConfig.min_five_min_zoom) {
        markers.add(MapUtils.createFiveMinMarker(_myLocation, _zoom));
        fiveMinWalk = MapUtils.fiveMinWalkPolyline(_myLocation);
      }
    }

    LatLng mapCenter;
    if (_locationPermission == Permission.AUTHORIZED) {
      mapCenter = _myLocation;
    } else {
      mapCenter = MapUtils.getCenterOf(
        stations: _stations,
        defaultCenter: MapConfig.defaultCenter,
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
          center: mapCenter,
          maxZoom: MapConfig.max_zoom,
          minZoom: MapConfig.min_zoom,
          zoom: MapConfig.def_zoom,
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
        PolylineLayerOptions(polylines: fiveMinWalk),
        MarkerLayerOptions(markers: markers),
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

    IconData directionsBike = Icons.directions_bike;
    IconData localParking = Icons.local_parking;
    Widget floatingAction = MapModeButton(
      icon: Icon(_viewMode == Mode.BIKE ? directionsBike : localParking),
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
