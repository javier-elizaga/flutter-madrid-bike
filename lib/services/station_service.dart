import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/station.dart';

class BiciMadConfig {
  // bicimad
  static final _server = 'https://rbdata.emtmadrid.es:8443/BiciMad';
  static final _userId = 'WEB.SERV.javier.elizaga@gmail.com';
  static final _userPassword = 'F3D2D9FB-0109-490E-89EB-1042C20116F1';
  static get stationsUrl => '$_server/get_stations/$_userId/$_userPassword';
}

class StationService {
  static Future<List<Station>> getStations() async {
    try {
      Map<String, String> headers = Map();
      headers['Accept'] = 'application/json';
      final res = await http.get(BiciMadConfig.stationsUrl, headers: headers);
      // jsonBody should be Map<String, String> unless when api return error
      Map<String, dynamic> jsonBody = jsonDecode(res.body);
      int code = int.tryParse(jsonBody["code"]);
      if (code == null || code != 0) {
        // error
        print('Error fetching stations');
        return Future.value(List());
      } else {
        String data = jsonBody['data'];
        Map jsonData = jsonDecode(data);
        List stationList = jsonData["stations"];
        return stationList.map((s) => Station.fromJson(s)).toList();
      }
    } catch (ex) {
      print('ex: $ex');
      throw ex;
    }
  }
}
