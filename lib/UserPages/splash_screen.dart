import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;

  @override
  void initState() {

    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    controller.forward();

    Timer(
      const Duration(seconds: 3),
          () {

        Navigator.pushReplacementNamed(
          context,
          '/login',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.orange,

      body: Center(

        child: ScaleTransition(

          scale: Tween<double>(
            begin: 0.5,
            end: 1.2,
          ).animate(controller),

          child: const Text(

            "ROOMMATE",

            style: TextStyle(
              fontSize: 40,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}