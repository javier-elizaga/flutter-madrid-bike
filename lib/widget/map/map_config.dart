import 'package:latlong/latlong.dart';

class MapConfig {
  // flutter map
  static const urlTemplate =
      'https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}';
  static const token =
      'pk.eyJ1IjoiamF2aWVyLWVsaXphZ2EiLCJhIjoiY2puYncwam9qMXRkYzN4cmZub3I3NW5mbCJ9.bnp4_s-Tyf2g6NgOw6w3yw';
  static const double def_zoom = 15.0;

  static const double max_zoom = 18.5;
  static const double min_zoom = 11.5;

  static LatLng defaultCenter = LatLng(40.4277841, -3.6981178);

  static Duration get fetchStationsEvery => Duration(seconds: 30);

  static const double min_five_min_zoom = 12.0;
}
