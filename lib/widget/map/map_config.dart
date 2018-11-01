import 'package:latlong/latlong.dart';

class MapConfig {
  // flutter map
  static const urlTemplate =
      'https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}';
  static const token =
      'pk.eyJ1IjoiamF2aWVyLWVsaXphZ2EiLCJhIjoiY2puYncwam9qMXRkYzN4cmZub3I3NW5mbCJ9.bnp4_s-Tyf2g6NgOw6w3yw';

  static const double init_map_zoom = 15.0;
  static const double max_map_zoom = 18.5;
  static const double min_map_zoom = 10.0;

  static LatLng defaultCenter = LatLng(40.4277841, -3.6981178);

  static const Duration get_stations_interval = Duration(seconds: 30);

  static const double min_full_icon_zoom = 13.5;

  static double getPinSizeBy({double zoom}) {
    double normalized = zoom - MapConfig.min_map_zoom;
    if (normalized < 1.0) {
      normalized = 1.0;
    }
    double pinSize = normalized * 5;
    return pinSize;
  }

  static double getFiveMinSizeBy({double zoom}) {
    double normalized = zoom - MapConfig.min_map_zoom;
    if (normalized < 1.0) {
      normalized = 1.0;
    }
    double pinSize = normalized * 7;
    return pinSize;
  }
}
