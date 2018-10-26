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
  bool _doAnimate = false;
  double duration = 100.0;

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
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedRotationIcon(
                icon: _icon(context),
                doAnimate: _doAnimate,
                duration: duration,
              ),
              Row(children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    setState(() {
                      duration -= 10;
                    });
                  },
                ),
                Slider(
                  min: 100.0,
                  max: 1000.0,
                  value: duration,
                  onChanged: (value) => setState(() {
                        duration = value;
                      }),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    setState(() {
                      duration += 10;
                    });
                  },
                ),
              ]),
              Text('${duration.toInt()}'),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(_doAnimate ? Icons.pause : Icons.play_arrow),
        onPressed: _toogleAnimation,
      ),
    );
  }
}
