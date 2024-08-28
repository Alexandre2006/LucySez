import 'dart:ui';

class RedoUndo {
  final VoidCallback undo;
  final VoidCallback redo;

  RedoUndo({
    required this.undo,
    required this.redo,
  });
}
