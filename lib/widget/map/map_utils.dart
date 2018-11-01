import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:madrid_bike/widget/map/map_config.dart';

import '../../model/mode.dart';
import '../../model/station.dart';
import 'map_bike_pin.dart';
import 'map_icon_circle.dart';
import 'map_five_min_icon.dart';

class MapUtils {
  static final fiveMinDistance = LatLng(0.0035, 0.0044);

  static Color _colorBy({int number}) {
    final green = Colors.green;
    final amber = Colors.amber;
    final red = Colors.red;
    final grey = Colors.grey;
    final greenLimit = 4;
    final amberLimit = 3;
    final redLimit = 1;
    final greyLimit = 0;

    Color color;
    if (number >= greenLimit) {
      color = green;
    } else if (number >= amberLimit) {
      color = amber;
    } else if (number >= redLimit) {
      color = red;
    } else if (number >= greyLimit) {
      color = grey;
    } else {
      color = Colors.white;
    }
    return color;
  }

  static Widget _stationPin(Station station, Mode mode, double size) {
    IconData foodModeIcon = Icons.directions_bike;
    IconData bikeModeIcon = Icons.local_parking;
    Key key = Key('station_${mode.index}_${station.id}_$size');
    int number;
    IconData icon;
    Color color;

    if (mode == Mode.FOOD) {
      icon = foodModeIcon;
      number = station.dockBikes;
    } else {
      icon = bikeModeIcon;
      number = station.freeBases;
    }
    color = _colorBy(number: number);
    return MapBikePin(
      icon: icon,
      number: number,
      color: color,
      size: size,
      key: key,
    );
  }

  static Widget _stationPinLittle(Station station, Mode mode, double size) {
    int number = mode == Mode.FOOD ? station.dockBikes : station.freeBases;
    Color color = _colorBy(number: number);
    Key key = Key('station_${station.id}_$size');
    return MapIconCircle(
      size: size,
      color: color,
      key: key,
    );
  }

  static Marker _stationMarker(Station station, Mode mode, double zoom) {
    double pinSize = MapConfig.getPinSizeBy(zoom: zoom);
    double iconSize = pinSize / 1.5;
    bool showIcon = zoom > MapConfig.min_full_icon_zoom;
    return Marker(
      width: pinSize, // touchable area is bigger than actual icon
      height: pinSize, // touchable area is bigger than actual icon
      point: station.latLng,
      builder: (context) {
        if (showIcon) {
          return _stationPin(station, mode, iconSize);
        }
        return _stationPinLittle(station, mode, iconSize);
      },
    );
  }

  static Marker createMyLocationMarker(LatLng location) {
    const double size = 10.0;
    return Marker(
      width: size,
      height: size,
      point: location,
      builder: (context) {
        return MapIconCircle(size: size);
      },
    );
  }

  static List<Marker> createStationMarkers({
    List<Station> stations,
    Mode mode,
    double zoom,
  }) {
    return stations.map((station) {
      return _stationMarker(
        station,
        mode,
        zoom,
      );
    }).toList();
  }

  static LatLng getCenterOf({List<Station> stations, LatLng defaultCenter}) {
    if (stations == null || stations.isEmpty) {
      return defaultCenter;
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

  static Marker createFiveMinMarker(LatLng location, double zoom) {
    double pinSize = MapConfig.getFiveMinSizeBy(zoom: zoom);
    final position = LatLng(
      fiveMinDistance.latitude * sin(pi / 2) + location.latitude,
      fiveMinDistance.longitude * cos(pi / 2) + location.longitude,
    );
    return Marker(
      width: pinSize,
      height: pinSize,
      point: position,
      builder: (context) {
        return MapFiveMinIcon(size: pinSize);
      },
    );
  }

  static List<Polyline> fiveMinWalkPolyline(LatLng location) {
    const Color strokeColor = const Color.fromRGBO(100, 133, 245, .9);
    const double strokeWidth = 2.0;

    List<Polyline> polylines = List();
    List<LatLng> points = List();
    int numOfPoints = 256;
    double increment = 2 * pi / numOfPoints;
    for (double x = 0.0; x < (2 * pi); x += increment) {
      points.add(LatLng(
        fiveMinDistance.latitude * sin(x) + location.latitude,
        fiveMinDistance.longitude * cos(x) + location.longitude,
      ));
    }
    polylines.add(Polyline(
      points: points,
      isDotted: false,
      color: strokeColor,
      strokeWidth: strokeWidth,
    ));
    return polylines;
  }

  static List<Polyline> fiveMinWalkPolylineDashed(LatLng location) {
    const Color strokeColor = const Color.fromRGBO(100, 133, 245, .9);
    const double strokeWidth = 2.0;

    List<Polyline> polylines = List();
    List<LatLng> points = List();
    int numOfPoints = 256;
    double increment = 2 * pi / numOfPoints;

    int dashedLen = 4;
    int dashed = 0;
    for (double x = 0.0; x < (2 * pi); x += increment) {
      if (dashed < dashedLen) {
        points.add(LatLng(
          fiveMinDistance.latitude * sin(x) + location.latitude,
          fiveMinDistance.longitude * cos(x) + location.longitude,
        ));
      } else if (dashed == dashedLen) {
        polylines.add(Polyline(
          points: points,
          isDotted: false,
          color: strokeColor,
          strokeWidth: strokeWidth,
        ));
        points = List();
      }
      dashed++;
      dashed %= (dashedLen * 2);
    }
    return polylines;
  }
}
