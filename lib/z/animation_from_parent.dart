import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widget/common/animated_rotation_icon.dart';

class AnimationFromParent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimationFromParent',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: ParentRefreshButton(),
    );
  }
}

class ParentRefreshButton extends StatefulWidget {
  @override
  _ParentRefreshButtonState createState() => _ParentRefreshButtonState();
}

class _ParentRefreshButtonState extends State<ParentRefreshButton> {
  bool _doAnimate = true;

  void _toogleAnimation() {
    setState(() {
      _doAnimate = !_doAnimate;
    });
  }

  _icon(BuildContext context) => Icon(
        const IconData(
          0xf49a,
          fontFamily: CupertinoIcons.iconFont,
          fontPackage: CupertinoIcons.iconFontPackage,
        ),
        size: 100.0,
        color: Theme.of(context).accentColor,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            AnimatedRotationIcon(icon: _icon(context), doAnimate: _doAnimate),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(_doAnimate ? Icons.pause : Icons.play_arrow),
        onPressed: _toogleAnimation,
      ),
    );
  }
}
