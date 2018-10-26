import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'pages/home.dart';

// import 'z/animation_from_parent.dart';

//void main() => runApp(AnimationFromParent());

void main() => runApp(MadridBikeApp());

class MadridBikeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _primarySwatch = Colors.blue;
    return MaterialApp(
      title: 'Madrid Bike',
      theme: ThemeData(primarySwatch: _primarySwatch),
      home: HomePage(),
    );
  }
}