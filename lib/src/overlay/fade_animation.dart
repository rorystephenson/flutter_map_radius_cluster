import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster/src/options/fade_animation_options.dart';

class FadeAnimation extends StatefulWidget {
  final FadeAnimationOptions options;
  final Widget child;

  const FadeAnimation({
    super.key,
    required this.options,
    required this.child,
  });

  @override
  State<FadeAnimation> createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.options.duration,
      value: widget.options.initialOpacity,
      lowerBound: widget.options.minimumOpacity,
      upperBound: widget.options.maximumOpacity,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });
    _controller.forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.options.curve,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}
