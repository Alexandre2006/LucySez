import 'package:flutter/material.dart';

class Color extends StatefulWidget {
  const Color({super.key});

  @override
  State<Color> createState() => _ColorState();
}

class _ColorState extends State<Color> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 32,
      child: Card.outlined(
        color: Colors.black,
      ),
    );
  }
}
