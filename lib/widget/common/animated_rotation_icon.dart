import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedRotationIcon extends StatefulWidget {
  final Icon icon;
  final bool doAnimate;

  AnimatedRotationIcon({this.icon, this.doAnimate, Key key}) : super(key: key);

  _AnimatedRotationIconState createState() {
    return _AnimatedRotationIconState(icon: icon, doAnimate: doAnimate);
  }
}

class _AnimatedRotationIconState extends State<AnimatedRotationIcon>
    with TickerProviderStateMixin {
  final Icon icon;
  bool doAnimate;
  double _rotation = 0.0;

  Animation<double> _animation;
  AnimationController _controller;

  _AnimatedRotationIconState({
    this.icon,
    this.doAnimate,
  });

  @override
  void didUpdateWidget(AnimatedRotationIcon oldWidget) {
    setState(() {
      doAnimate = widget.doAnimate;
    });
    if (doAnimate) {
      _controller.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
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
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    )
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
    return Container(
      child: RotatedIcon(icon: icon, rotation: _rotation),
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
