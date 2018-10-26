import 'package:latlong/latlong.dart';

class Station {
  int id;
  double latitude;
  double longitude;
  String name;
  int light;
  String number;
  String address;
  int activate;
  int noAvailable;
  int totalBases;
  int dockBikes;
  int freeBases;
  int reservationsCount;

  Station({
    this.id,
    this.latitude,
    this.longitude,
    this.name,
    this.light,
    this.number,
    this.address,
    this.activate,
    this.noAvailable,
    this.totalBases,
    this.dockBikes,
    this.freeBases,
    this.reservationsCount,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
        id: json['id'],
        latitude: double.parse(json['latitude']),
        longitude: double.parse(json['longitude']),
        name: json['name'],
        light: json['light'],
        number: json['number'],
        address: json['address'],
        activate: json['activate'],
        noAvailable: json['no_available'],
        totalBases: json['total_bases'],
        dockBikes: json['dock_bikes'],
        freeBases: json['free_bases'],
        reservationsCount: json['reservations_count']);
  }

  LatLng get latLng => LatLng(latitude, longitude);

  @override
  String toString() {
    return "{id: $id}";
  }
}
