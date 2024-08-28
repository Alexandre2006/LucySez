import 'package:flutter/material.dart';
import 'package:lucy_sez/widgets/whiteboard/whiteboard.dart';
import 'package:lucy_sez/widgets/whiteboard/whiteboard_controller.dart';

class WhiteboardScreen extends StatefulWidget {
  const WhiteboardScreen({super.key});

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  // Whiteboard Controller
  WhiteboardController _whiteboardController = WhiteboardController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth Session"),
      ),
      body: Column(
        children: [
          // Whiteboard
          Whiteboard(
            controller: _whiteboardController,
          ),
          
        ],
      ),
    );
  }
}
