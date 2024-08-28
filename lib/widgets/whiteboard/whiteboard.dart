import 'package:flutter/material.dart';
import 'package:lucy_sez/widgets/whiteboard/redo_undo.dart';
import 'package:lucy_sez/widgets/whiteboard/scale.dart';
import 'package:lucy_sez/widgets/whiteboard/stroke.dart';
import 'package:lucy_sez/widgets/whiteboard/whiteboard_controller.dart';
import 'package:lucy_sez/widgets/whiteboard/whiteboard_painter.dart';

class Whiteboard extends StatefulWidget {
  // Controller
  final WhiteboardController? controller;

  // Callbacks
  final ValueChanged<Map<String, List<Stroke>>>? onWhiteboardUpdated;

  // Constructor
  const Whiteboard({
    super.key,
    this.controller,
    this.onWhiteboardUpdated,
  });

  @override
  State<Whiteboard> createState() => _WhiteboardState();
}

class _WhiteboardState extends State<Whiteboard> {
  // Redo / Undo History
  final _undoHistory = <RedoUndo>[];
  final _redoHistory = <RedoUndo>[];

  // Strokes
  final _strokes = <Stroke>[];

  // Cached Canvas Size
  late Size _canvasSize;

  // Color
  Color color = Colors.black;

  // Export / Import (for JSON)
  List<Stroke> export() {
    return [..._strokes];
  }

  void import(List<Stroke> strokes) {
    // Set State
    setState(() {
      // Save removed strokes
      final removedStrokes = <Stroke>[..._strokes];

      // Clear strokes
      _strokes.clear();

      // Add strokes
      _strokes.addAll(strokes);

      // Add to undo history (undo: remove new strokes and add old ones, redo: remove old strokes and add new ones)
      _undoHistory.add(RedoUndo(
          undo: () => setState(() => _strokes
            ..clear()
            ..addAll(removedStrokes)),
          redo: () => setState(() => _strokes
            ..clear()
            ..addAll(strokes))));

      // Wipe redo history
      _redoHistory.clear();
    });
  }

  void importChanges(Map<String, List<Stroke>> changes) {
    // Set State
    setState(() {
      // Save removed strokes
      final removedStrokes = <Stroke>[..._strokes];

      // Remove strokes
      _strokes.removeWhere((stroke) => changes["removed"]!.contains(stroke));

      // Add strokes
      _strokes.addAll(changes["added"]!);

      // Add to undo history (undo: remove new strokes and add old ones, redo: remove old strokes and add new ones)
      _undoHistory.add(RedoUndo(
          undo: () => setState(() => _strokes
            ..clear()
            ..addAll(removedStrokes)),
          redo: () => setState(() => _strokes
            ..clear()
            ..addAll(changes["added"]!))));

      // Wipe redo history
      _redoHistory.clear();
    });
  }

  @override
  void initState() {
    // Configure Delegate
    widget.controller?.delegate = WhiteboardControllerDelegate()
      ..onRedo = () {
        // Save previous strokes
        final strokeBackup = <Stroke>[..._strokes];

        // Make sure there is something to redo
        if (_redoHistory.isEmpty) return;

        // Add to undo history
        _undoHistory.add(_redoHistory.removeLast()..redo());

        // Find differences
        final addedStrokes = <Stroke>[];
        final removedStrokes = <Stroke>[];

        for (final stroke in _strokes) {
          if (!strokeBackup.contains(stroke)) {
            addedStrokes.add(stroke);
          }
        }

        for (final stroke in strokeBackup) {
          if (!_strokes.contains(stroke)) {
            removedStrokes.add(stroke);
          }
        }

        // Notify parent with changes
        Map<String, List<Stroke>> changes = {
          "removed": removedStrokes,
          "added": addedStrokes
        };

        widget.onWhiteboardUpdated?.call(changes);
      }
      ..onUndo = () {
        // Save previous strokes
        final strokeBackup = <Stroke>[..._strokes];

        // Make sure there is something to undo
        if (_undoHistory.isEmpty) return;

        // Add to redo history
        _redoHistory.add(_undoHistory.removeLast()..undo());

        // Find differences
        final addedStrokes = <Stroke>[];
        final removedStrokes = <Stroke>[];

        for (final stroke in _strokes) {
          if (!strokeBackup.contains(stroke)) {
            addedStrokes.add(stroke);
          }
        }

        for (final stroke in strokeBackup) {
          if (!_strokes.contains(stroke)) {
            removedStrokes.add(stroke);
          }
        }

        // Notify parent with changes
        Map<String, List<Stroke>> changes = {
          "removed": removedStrokes,
          "added": addedStrokes
        };

        widget.onWhiteboardUpdated?.call(changes);
      }
      ..onClear = () {
        // Verify there are strokes to clear
        if (_strokes.isEmpty) return;

        // Set State
        setState(() {
          // Save removed strokes
          final removedStrokes = <Stroke>[..._strokes];

          // Add to undo history
          _undoHistory.add(RedoUndo(
              undo: () => setState(() => _strokes.addAll(removedStrokes)),
              redo: () => setState(() => _strokes.clear())));

          // Clear strokes
          _strokes.clear();

          // Wipe redo history
          _redoHistory.clear();

          // Notify parent with changes
          Map<String, List<Stroke>> changes = {
            "removed": removedStrokes,
            "added": []
          };

          widget.onWhiteboardUpdated?.call(changes);
        });
      }
      ..onExport = export
      ..onImport = import
      ..onImportChanges = importChanges
      ..onGetColor = () {
        return color;
      }
      ..onSetColor = (Color newColor) {
        color = newColor;
      };

    super.initState();
  }

  void _startStroke(double x, double y) {
    final stroke = Stroke(color);

    // Get current scale
    final scale = calculateScale(_strokes, _canvasSize);

    // Adjust point
    Point scaledPoint = unscalePoint(Point(x, y), scale);

    // Move to starting point
    stroke.points.add(scaledPoint);

    // Add to strokes
    _strokes.add(stroke);

    // Add to undo history
    _undoHistory.add(RedoUndo(
        undo: () => setState(() => _strokes.remove(stroke)),
        redo: () => setState(() => _strokes.add(stroke))));

    // Clear redo history
    _redoHistory.clear();
  }

  void _updateStroke(double x, double y) {
    // Verify point is in bounds
    if (x < 0 || y < 0 || x > _canvasSize.width || y > _canvasSize.height) {
      return;
    }

    // Get current scale
    final scale = calculateScale(_strokes, _canvasSize);

    // Adjust point
    Point scaledPoint = unscalePoint(Point(x, y), scale);

    setState(() {
      _strokes.last.points.add(Point(scaledPoint.x, scaledPoint.y));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get Size
    final size = MediaQuery.of(context).size;

    // Build container w/ whiteboard
    return SizedBox(
      height: size.height,
      width: size.width,
      // Add Gesture Detector (to detect drawing)
      child: GestureDetector(onPanStart: (details) {
        _startStroke(details.localPosition.dx, details.localPosition.dy);
      }, onPanUpdate: (details) {
        _updateStroke(details.localPosition.dx, details.localPosition.dy);
      }, onPanEnd: (details) {
        // Notify parent with changes
        widget.onWhiteboardUpdated?.call({
          "removed": [],
          "added": [_strokes.last]
        });
      },
          // Add Custom Painter
          child: LayoutBuilder(builder: (context, constraints) {
        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        return CustomPaint(
          size: _canvasSize,
          painter: WhiteboardPainter(_strokes),
        );
      })),
    );
  }
}
