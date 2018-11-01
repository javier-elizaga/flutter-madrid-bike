import 'package:latlong/latlong.dart';

class Station {
  // Station's id
  final int id;

  // latitude in WGS84 format
  final double latitude;

  // longitude in WGS84 format
  final double longitude;

  // Station's name
  // final String name;

  // How busy the station is (0=low, 1=medium, 3=high)
  // int light;

  // Logic identifier
  // String number;

  // Address
  // String address;

  // Station's Status (0=disable, 1=enable)
  int activate;

  // Station's capacity
  // int totalBases;

  // Station's disponibility  (0=available, 1=not available)
  int noAvailable;

  // Number of bikes anchored: Número de bicicletas ancladas
  int dockBikes;

  // Free anchors.
  int freeBases;

  // Number of anchors booked
  // int reservationsCount;

  Station({
    this.id,
    this.latitude,
    this.longitude,
    // this.name,
    // this.light,
    // this.number,
    // this.address,
    this.activate,
    this.noAvailable,
    // this.totalBases,
    this.dockBikes,
    this.freeBases,
    // this.reservationsCount,
  });

  bool isActive() => activate == 1;

  bool isAvailable() => noAvailable == 0;

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      latitude: double.parse(json['latitude']),
      longitude: double.parse(json['longitude']),
      // name: json['name'],
      // light: json['light'],
      // number: json['number'],
      // address: json['address'],
      activate: json['activate'],
      noAvailable: json['no_available'],
      // totalBases: json['total_bases'],
      dockBikes: json['dock_bikes'],
      freeBases: json['free_bases'],
      // reservationsCount: json['reservations_count'],
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);

  @override
  String toString() {
    return "{id: $id}";
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! Station) {
      return false;
    }
    final Station typedOther = other;
    return typedOther.id == other.id &&
        typedOther.latitude == other.latitude &&
        typedOther.longitude == other.longitude &&
        typedOther.activate == other.activate &&
        typedOther.noAvailable == other.noAvailable &&
        typedOther.dockBikes == other.dockBikes &&
        typedOther.freeBases == other.freeBases;
  }

  @override
  int get hashCode {
    int prime = 31;
    int result = 1;
    result = prime * result + (id?.hashCode ?? 0);
    result = prime * result + (latitude?.hashCode ?? 0);
    result = prime * result + (longitude?.hashCode ?? 0);
    result = prime * result + (activate?.hashCode ?? 0);
    result = prime * result + (noAvailable?.hashCode ?? 0);
    result = prime * result + (dockBikes?.hashCode ?? 0);
    result = prime * result + (freeBases?.hashCode ?? 0);
    return result;
  }
}
