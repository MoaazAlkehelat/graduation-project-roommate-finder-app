import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class FadeAnimation extends StatelessWidget {
  final double delay;
  final Widget child;

  const FadeAnimation(this.delay, this.child, {super.key});

  @override
  Widget build(BuildContext context) {

    final movie = MovieTween()
      ..scene(
        begin: const Duration(milliseconds: 0),
        duration: const Duration(milliseconds: 500),
      ).tween('opacity', Tween(begin: 0.0, end: 1.0))
      ..scene(
        begin: const Duration(milliseconds: 0),
        duration: const Duration(milliseconds: 500),
      ).tween('translate', Tween(begin: -30.0, end: 0.0), curve: Curves.easeOut);

    return CustomAnimationBuilder<Movie>(
      control: Control.play,
      delay: Duration(milliseconds: (500 * delay).round()),
      duration: movie.duration,
      tween: movie,
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.get('opacity'), // الحصول على قيمة الشفافية
          child: Transform.translate(
            offset: Offset(0, value.get('translate')), // الحصول على قيمة الإزاحة
            child: child,
          ),
        );
      },
    );
  }
}