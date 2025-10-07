import 'package:flutter/material.dart';
//import 'dart:ui' as ui;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '无边界草稿纸',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: InfiniteSketchPad(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum DrawingMode {
  Pen,
  Line,
  Rectangle,
  Circle,
  Eraser,
}

class InfiniteSketchPad extends StatefulWidget {
  @override
  _InfiniteSketchPadState createState() => _InfiniteSketchPadState();
}

class _InfiniteSketchPadState extends State<InfiniteSketchPad> {
  List<DrawingPoint> drawingPoints = [];
  List<List<DrawingPoint>> history = [];
  List<List<DrawingPoint>> redoHistory = [];
  double strokeWidth = 3.0;
  Color selectedColor = Colors.black;
  DrawingMode drawingMode = DrawingMode.Pen;
  Offset? startOffset;
  Offset? currentOffset;
  Offset? previousOffset;

  List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

  void _saveToHistory() {
    history.add(List.from(drawingPoints));
    redoHistory.clear();
  }

  void _undo() {
    if (history.isNotEmpty) {
      redoHistory.add(List.from(drawingPoints));
      drawingPoints = history.removeLast();
      setState(() {});
    }
  }

  void _redo() {
    if (redoHistory.isNotEmpty) {
      history.add(List.from(drawingPoints));
      drawingPoints = redoHistory.removeLast();
      setState(() {});
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      startOffset = details.localPosition;
      currentOffset = details.localPosition;
      previousOffset = details.localPosition;
      
      _saveToHistory();
      
      if (drawingMode == DrawingMode.Pen || drawingMode == DrawingMode.Eraser) {
        drawingPoints.add(
          DrawingPoint(
            offset: details.localPosition,
            paint: _getCurrentPaint(),
            mode: drawingMode,
          ),
        );
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      currentOffset = details.localPosition;
      
      if (drawingMode == DrawingMode.Pen || drawingMode == DrawingMode.Eraser) {
        final currentOffset = details.localPosition;
        
        if (previousOffset != null) {
          final distance = (currentOffset - previousOffset!).distance;
          if (distance > 3) {
            final steps = (distance / 3).ceil();
            for (int i = 0; i <= steps; i++) {
              final t = i / steps;
              final point = Offset.lerp(previousOffset, currentOffset, t)!;
              drawingPoints.add(
                DrawingPoint(
                  offset: point,
                  paint: _getCurrentPaint(),
                  mode: drawingMode,
                ),
              );
            }
          }
        }
        
        previousOffset = currentOffset;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      if (drawingMode != DrawingMode.Pen && drawingMode != DrawingMode.Eraser) {
        // 对于形状工具，在结束拖动时添加最终形状
        if (startOffset != null && currentOffset != null) {
          drawingPoints.add(
            DrawingPoint(
              offset: startOffset!,
              endOffset: currentOffset,
              paint: _getCurrentPaint(),
              mode: drawingMode,
            ),
          );
        }
      }
      
      startOffset = null;
      currentOffset = null;
      previousOffset = null;
    });
  }

  Paint _getCurrentPaint() {
    return Paint()
      ..color = drawingMode == DrawingMode.Eraser ? Colors.white : selectedColor
      ..strokeWidth = drawingMode == DrawingMode.Eraser ? strokeWidth * 2 : strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = drawingMode == DrawingMode.Pen || drawingMode == DrawingMode.Eraser 
          ? PaintingStyle.stroke 
          : PaintingStyle.stroke;
  }

  void clearCanvas() {
    _saveToHistory();
    setState(() {
      drawingPoints.clear();
    });
  }

  void _setDrawingMode(DrawingMode mode) {
    setState(() {
      drawingMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('无边界草稿纸'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          // 撤销按钮
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: _undo,
            tooltip: '撤销',
          ),
          // 重做按钮
          IconButton(
            icon: Icon(Icons.redo),
            onPressed: _redo,
            tooltip: '重做',
          ),
          IconButton(
            icon: Icon(Icons.cleaning_services),
            onPressed: clearCanvas,
            tooltip: '清空画布',
          ),
        ],
      ),
      body: Column(
        children: [
          // 工具栏
          Container(
            height: 120,
            color: Colors.grey[100],
            child: Column(
              children: [
                // 绘图工具选择
                Container(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildToolButton(Icons.brush, '画笔', DrawingMode.Pen),
                      _buildToolButton(Icons.horizontal_rule, '直线', DrawingMode.Line),
                      _buildToolButton(Icons.crop_square, '矩形', DrawingMode.Rectangle),
                      _buildToolButton(Icons.circle, '圆形', DrawingMode.Circle),
                      _buildToolButton(Icons.auto_fix_high, '橡皮擦', DrawingMode.Eraser),
                    ],
                  ),
                ),
                // 颜色和笔刷大小选择
                Container(
                  height: 60,
                  child: Row(
                    children: [
                      // 颜色选择
                      Expanded(
                        child: Container(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: colors.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = colors[index];
                                    drawingMode = DrawingMode.Pen;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.all(4),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: colors[index],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColor == colors[index] 
                                        ? Colors.black 
                                        : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // 笔刷大小
                      PopupMenuButton<double>(
                        icon: Icon(Icons.brush),
                        onSelected: (value) {
                          setState(() {
                            strokeWidth = value;
                          });
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 2.0,
                            child: Text('细'),
                          ),
                          PopupMenuItem(
                            value: 5.0,
                            child: Text('中'),
                          ),
                          PopupMenuItem(
                            value: 10.0,
                            child: Text('粗'),
                          ),
                          PopupMenuItem(
                            value: 15.0,
                            child: Text('特粗'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 画布区域
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                color: Colors.white,
                child: CustomPaint(
                  painter: SketchPainter(
                    drawingPoints,
                    currentStartOffset: startOffset,
                    currentEndOffset: currentOffset,
                    currentMode: drawingMode,
                    currentPaint: _getCurrentPaint(),
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String tooltip, DrawingMode mode) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Tooltip(
        message: tooltip,
        child: ElevatedButton(
          onPressed: () => _setDrawingMode(mode),
          style: ElevatedButton.styleFrom(
            backgroundColor: drawingMode == mode ? Colors.blue : Colors.grey[300],
            shape: CircleBorder(),
            padding: EdgeInsets.all(12),
          ),
          child: Icon(
            icon,
            color: drawingMode == mode ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class DrawingPoint {
  final Offset offset;
  final Offset? endOffset;
  final Paint paint;
  final DrawingMode mode;

  DrawingPoint({
    required this.offset,
    this.endOffset,
    required this.paint,
    required this.mode,
  });
}

class SketchPainter extends CustomPainter {
  final List<DrawingPoint> drawingPoints;
  final Offset? currentStartOffset;
  final Offset? currentEndOffset;
  final DrawingMode? currentMode;
  final Paint? currentPaint;

  SketchPainter(
    this.drawingPoints, {
    this.currentStartOffset,
    this.currentEndOffset,
    this.currentMode,
    this.currentPaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制已完成的图形
    for (int i = 0; i < drawingPoints.length; i++) {
      final point = drawingPoints[i];
      _drawPoint(canvas, point);
    }

    // 绘制当前正在绘制的预览图形
    if (currentStartOffset != null && 
        currentEndOffset != null && 
        currentMode != null && 
        currentPaint != null) {
      
      final previewPoint = DrawingPoint(
        offset: currentStartOffset!,
        endOffset: currentEndOffset,
        paint: currentPaint!,
        mode: currentMode!,
      );
      _drawPoint(canvas, previewPoint);
    }
  }

  void _drawPoint(Canvas canvas, DrawingPoint point) {
    switch (point.mode) {
      case DrawingMode.Pen:
      case DrawingMode.Eraser:
        _drawFreehand(canvas, point);
        break;
      case DrawingMode.Line:
        if (point.endOffset != null) {
          canvas.drawLine(point.offset, point.endOffset!, point.paint);
        }
        break;
      case DrawingMode.Rectangle:
        if (point.endOffset != null) {
          final rect = Rect.fromPoints(point.offset, point.endOffset!);
          canvas.drawRect(rect, point.paint);
        }
        break;
      case DrawingMode.Circle:
        if (point.endOffset != null) {
          final center = Offset(
            (point.offset.dx + point.endOffset!.dx) / 2,
            (point.offset.dy + point.endOffset!.dy) / 2,
          );
          final radius = (point.offset - point.endOffset!).distance / 2;
          canvas.drawCircle(center, radius, point.paint);
        }
        break;
    }
  }

  void _drawFreehand(Canvas canvas, DrawingPoint point) {
    final index = drawingPoints.indexOf(point);
    if (index < drawingPoints.length - 1) {
      final nextPoint = drawingPoints[index + 1];
      if (nextPoint.mode == DrawingMode.Pen || nextPoint.mode == DrawingMode.Eraser) {
        canvas.drawLine(point.offset, nextPoint.offset, point.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}