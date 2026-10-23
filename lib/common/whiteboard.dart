import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../whiteboard_service.dart';
import '../zego_service.dart';

class DrawingPoint {
  final Offset point;
  final Paint paint;
  final bool isBreak;

  DrawingPoint({required this.point, required this.paint, this.isBreak = false});
}

class SimpleWhiteboard extends StatefulWidget {
  final String whiteboardTitle;
  final bool isReadOnly;
  final bool embedded;
  final String? studentId;
  final String? studentName;
  final String? conferenceId;
  final bool isTeacher;

  const SimpleWhiteboard({
    super.key,
    this.whiteboardTitle = 'Whiteboard',
    this.isReadOnly = false,
    this.embedded = false,
    this.studentId,
    this.studentName,
    this.conferenceId,
    this.isTeacher = false,
  });

  @override
  State<SimpleWhiteboard> createState() => _SimpleWhiteboardState();
}

class _SimpleWhiteboardState extends State<SimpleWhiteboard> {
  late List<DrawingPoint> drawingPoints;
  late Paint selectedPaint;
  late Paint linePaint;
  Color selectedColor = Colors.black;
  double strokeWidth = 2.0;
  bool isErasing = false;
  TextEditingController textController = TextEditingController();
  String displayedText = '';
  Offset textPosition = const Offset(50, 100);
  bool isSaving = false;
  List<String> textElements = []; // Store multiple text elements
  List<Offset> textPositions = []; // Store positions for each text element

  @override
  void initState() {
    super.initState();
    drawingPoints = [];
    selectedPaint = Paint()
      ..color = selectedColor
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    linePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  Widget _buildWhiteboardBody() {
    return Column(
      children: [
        // Toolbar
        if (!widget.isReadOnly)
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Essential color buttons (reduced)
                  _colorButton(Colors.black),
                  _colorButton(Colors.red),
                  _colorButton(Colors.blue),
                  _colorButton(Colors.green),

                  // Divider
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),

                  // Stroke width slider
                  Text(
                    'Width: ${strokeWidth.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      min: 1.0,
                      max: 20.0,
                      value: strokeWidth,
                      onChanged: _updateStrokeWidth,
                    ),
                  ),

                  // Divider
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),

                  // Essential toolbar buttons
                  // Text button
                  IconButton(
                    icon: const Icon(Icons.text_fields),
                    tooltip: 'Add Text',
                    onPressed: _addText,
                  ),

                  // Save button for embedded mode
                  if (widget.embedded) ...[
                    IconButton(
                      icon: const Icon(Icons.save),
                      tooltip: 'Save Whiteboard',
                      onPressed: _saveWhiteboard,
                      color: Colors.green,
                    ),
                  ],

                  // Clear button for embedded mode
                  if (widget.embedded) ...[
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear All',
                      onPressed: _clearWhiteboard,
                      color: Colors.red,
                    ),
                  ],

                  // Proper eraser button (removes content)
                  IconButton(
                    icon: const Icon(Icons.back_hand),
                    tooltip: 'Eraser',
                    onPressed: _setEraser,
                    isSelected: isErasing,
                    selectedIcon: const Icon(
                      Icons.back_hand,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Drawing area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  if (widget.isReadOnly) return;
                  final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(event.position);
                  
                  // Constrain drawing to the canvas bounds
                  if (localPosition.dx >= 0 && 
                      localPosition.dx <= constraints.maxWidth &&
                      localPosition.dy >= 0 && 
                      localPosition.dy <= constraints.maxHeight) {
                    setState(() {
                      drawingPoints = List<DrawingPoint>.from(drawingPoints)
                        ..add(
                          DrawingPoint(
                            point: localPosition,
                            paint: selectedPaint,
                          ),
                        );
                    });
                  }
                },
                onPointerMove: (event) {
                  if (widget.isReadOnly) return;
                  final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(event.position);
                  
                  // Constrain drawing to the canvas bounds
                  if (localPosition.dx >= 0 && 
                      localPosition.dx <= constraints.maxWidth &&
                      localPosition.dy >= 0 && 
                      localPosition.dy <= constraints.maxHeight) {
                    setState(() {
                      drawingPoints = List<DrawingPoint>.from(drawingPoints)
                        ..add(
                          DrawingPoint(
                            point: localPosition,
                            paint: selectedPaint,
                          ),
                        );
                    });
                  }
                },
                onPointerUp: (event) {
                  if (widget.isReadOnly) return;
                  setState(() {
                    drawingPoints = List<DrawingPoint>.from(drawingPoints)
                      ..add(
                        DrawingPoint(
                          point: Offset.zero,
                          paint: Paint(),
                          isBreak: true,
                        ),
                      );
                  });
                },
                onPointerCancel: (event) {
                  if (widget.isReadOnly) return;
                  setState(() {
                    drawingPoints = List<DrawingPoint>.from(drawingPoints)
                      ..add(
                        DrawingPoint(
                          point: Offset.zero,
                          paint: Paint(),
                          isBreak: true,
                        ),
                      );
                  });
                },
                child: CustomPaint(
                  painter: DrawingPainter(
                    points: drawingPoints,
                    displayedText: displayedText,
                    textPosition: textPosition,
                    textElements: textElements,
                    textPositions: textPositions,
                  ),
                  size: Size.infinite, // Ensure painter covers entire area
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _updateColor(Color color) {
    setState(() {
      selectedColor = color;
      isErasing = false;
      selectedPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
    });
  }

  void _setEraser() {
    setState(() {
      isErasing = true;
      selectedPaint = Paint()
        ..color = Colors.transparent  // Transparent to remove content
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..strokeWidth = 30.0  // Larger stroke for better erasing
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.clear;  // Proper content removal
    });
  }

  void _setBrush() {
    setState(() {
      isErasing = false;
      selectedPaint = Paint()
        ..color = selectedColor
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
    });
  }

  void _updateStrokeWidth(double value) {
    setState(() {
      strokeWidth = value;
      if (!isErasing) {
        selectedPaint = Paint()
          ..color = selectedColor
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true
          ..strokeWidth = value
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
      }
    });
  }

  void _clearWhiteboard() {
    setState(() {
      drawingPoints = [];
      displayedText = '';
      textElements.clear();
      textPositions.clear();
    });
  }

  void _addText() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text'),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter text to add to whiteboard:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Enter text (use clear, block letters)',
                  border: OutlineInputBorder(),
                  helperText: 'Tip: Use uppercase and clear handwriting',
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 2,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                setState(() {
                  // Add to text elements list for multiple text support
                  final newText = textController.text.trim();
                  textElements.add(newText);
                  textPositions.add(Offset(50, 100 + (textElements.length * 40.0)));
                  
                  // Don't update displayedText to avoid duplication
                  // displayedText is only for single text mode
                });
                textController.clear();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Text added! Position: Top-left area'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWhiteboard() async {
    if (isSaving) return;
    
    setState(() {
      isSaving = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Saving whiteboard...'),
            ],
          ),
        ),
      );

      // Capture whiteboard as image
      final imageData = await _captureWhiteboardAsImage();
      
      // Enhance image for better quality
      final enhancedImageData = WhiteboardService.enhanceImageForOCR(imageData);

      // Combine all text elements for saving (avoid duplication)
      String allText = '';
      for (String text in textElements) {
        allText += text + '\n';
      }
      // Only add displayedText if it's not already in textElements
      if (displayedText.isNotEmpty && !textElements.contains(displayedText)) {
        allText += displayedText;
      }

      // Save to Firebase with text data
      final result = await WhiteboardService.saveWhiteboardWithOCR(
        imageData: enhancedImageData,
        studentId: widget.studentId ?? 'unknown',
        conferenceId: widget.conferenceId ?? 'unknown',
        whiteboardTitle: widget.whiteboardTitle,
        extractedText: allText.trim(), // Pass actual whiteboard text content
        studentName: widget.studentName,
        isTeacher: widget.isTeacher,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (result['success'] == true) {
        // Show success dialog with OCR results
        _showSaveSuccessDialog(result);
      } else {
        // Show error
        _showErrorDialog(result['message'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorDialog('Failed to save whiteboard: $e');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<Uint8List> _captureWhiteboardAsImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(1080, 1920);

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw all drawing points
    for (int i = 0; i < drawingPoints.length; i++) {
      if (i == 0) continue;

      canvas.drawLine(
        drawingPoints[i - 1].point,
        drawingPoints[i].point,
        drawingPoints[i].paint,
      );
    }

    // Draw all text elements
    for (int i = 0; i < textElements.length; i++) {
      if (i < textPositions.length) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: textElements[i],
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, textPositions[i]);
      }
    }

    // Draw legacy displayed text for backward compatibility
    if (displayedText.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: displayedText,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, textPosition);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _showSaveSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Whiteboard Saved Successfully!'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✅ Whiteboard saved successfully'),
              const SizedBox(height: 10),
              Text('📝 Session ID: ${result['sessionId'] ?? 'unknown'}', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              const Text('📝 Text Content:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result['extractedText'] ?? 'No text added',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildWhiteboardBody();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(widget.whiteboardTitle),
        elevation: 0,
        actions: [
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Whiteboard',
              onPressed: _saveWhiteboard,
            ),
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear All',
              onPressed: _clearWhiteboard,
            ),
        ],
      ),
      body: _buildWhiteboardBody(),
    );
  }

  Widget _colorButton(Color color) {
    return GestureDetector(
      onTap: () => _updateColor(color),
      child: Container(
        width: 35,
        height: 35,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.black : Colors.grey,
            width: selectedColor == color ? 2 : 1,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final String displayedText;
  final Offset textPosition;
  final List<String> textElements;
  final List<Offset> textPositions;

  DrawingPainter({
    required this.points,
    required this.displayedText,
    required this.textPosition,
    this.textElements = const [],
    this.textPositions = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw grid lines (optional - for reference)
    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Draw dots for all points so single taps / sparse updates are still visible.
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.isBreak) {
        continue;
      }
      canvas.drawPoints(ui.PointMode.points, [p.point], p.paint);
    }

    // Draw all points
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1.isBreak || p2.isBreak) {
        continue;
      }
      canvas.drawLine(p1.point, p2.point, p1.paint);
    }

    // Draw all text elements
    for (int i = 0; i < textElements.length; i++) {
      if (i < textPositions.length) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: textElements[i],
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, textPositions[i]);
      }
    }

    // Draw legacy displayed text for backward compatibility
    if (displayedText.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: displayedText,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, textPosition);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.points.length != points.length ||
        oldDelegate.displayedText != displayedText ||
        oldDelegate.textPosition != textPosition ||
        oldDelegate.textElements != textElements ||
        oldDelegate.textPositions != textPositions;
  }
}
