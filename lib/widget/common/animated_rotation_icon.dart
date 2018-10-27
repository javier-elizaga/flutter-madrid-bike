import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedRotationIcon extends StatefulWidget {
  final Icon icon;
  final double duration;
  final bool doAnimate;
  final bool clockwise;

  AnimatedRotationIcon({
    this.icon,
    this.doAnimate,
    this.duration = 600.0,
    this.clockwise = true,
    Key key,
  }) : super(key: key);

  _AnimatedRotationIconState createState() {
    return _AnimatedRotationIconState(
      icon: icon,
      doAnimate: doAnimate,
      duration: duration,
      clockwise: clockwise,
    );
  }
}

class _AnimatedRotationIconState extends State<AnimatedRotationIcon>
    with TickerProviderStateMixin {
  final Icon icon;

  bool doAnimate;
  double duration;
  bool clockwise;

  double _rotation = 0.0;

  Animation<double> _animation;
  AnimationController _controller;

  _AnimatedRotationIconState({
    this.icon,
    this.doAnimate,
    this.duration,
    this.clockwise,
  });

  @override
  void didUpdateWidget(AnimatedRotationIcon oldWidget) {
    setState(() {
      doAnimate = widget.doAnimate;
      duration = widget.duration;
      clockwise = widget.clockwise;
    });
    _controller.duration = Duration(milliseconds: duration.toInt());
    if (doAnimate) {
      _controller.forward(from: 0.0);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: duration.toInt()),
      vsync: this,
    );
    _initAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initAnimation() {
    _animation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller)
      ..addListener(() {
        setState(() {
          _rotation = _animation.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (doAnimate) {
            _controller.forward(from: 0.0);
          }
        }
      });
    if (doAnimate) {
      _controller.forward(from: 0.0);
    }
  }

  Widget build(BuildContext context) {
    double rotation = (clockwise ? 1.0 : -1.0) * _rotation;
    return Container(
      child: RotatedIcon(icon: icon, rotation: rotation),
    );
  }
}

class RotatedIcon extends StatelessWidget {
  final Icon icon;
  final double rotation;

  RotatedIcon({this.icon, this.rotation, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * 2 * pi,
      child: icon,
    );
  }
}
