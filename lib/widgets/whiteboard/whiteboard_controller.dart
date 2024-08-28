import 'dart:ui';

import 'package:lucy_sez/widgets/whiteboard/stroke.dart';

class WhiteboardController {
  late WhiteboardControllerDelegate delegate;

  // Basic Tools (Controls)
  void undo() => delegate.onUndo();
  void redo() => delegate.onRedo();
  void clear() => delegate.onClear();

  // Color Options
  void setColor(Color color) => delegate.onSetColor(color);
  Color getColor() => delegate.onGetColor();

  // Import Export Functions
  List<Stroke> export() => delegate.onExport();
  void import(List<Stroke> strokes) => delegate.onImport(strokes);

  // Import Functions (Partial)
  void importChanges(Map<String, List<Stroke>> changes) =>
      delegate.onImportChanges(changes);
}

class WhiteboardControllerDelegate {
  // Basic Tools (Controls)
  late VoidCallback onUndo;
  late VoidCallback onRedo;
  late VoidCallback onClear;

  // Color Options
  late void Function(Color color) onSetColor;
  late Color Function() onGetColor;

  // Import Export Functions
  late List<Stroke> Function() onExport;
  late void Function(List<Stroke> strokes) onImport;

  // Import Functions (Partial)
  late void Function(Map<String, List<Stroke>> strokes) onImportChanges;
}
