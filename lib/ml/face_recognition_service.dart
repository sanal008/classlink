import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:isolate';

class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  
  // Model parameters for YOLOv8
  static const int _inputSize = 640;
  static const List<String> _labels = ['Abel', 'Alen', 'Anamika', 'Athul'];
  static const double _confThreshold = 0.50;
  static const double _iouThreshold = 0.45;

  bool get isModelLoaded => _isModelLoaded;

  /// Load the TFLite model
  Future<void> initialize() async {
    if (_isModelLoaded) return;
    try {
      final options = InterpreterOptions();
      // Use XNNPACK delegate for better CPU performance if available, or GPU delegate
      if (Platform.isAndroid) {
        options.addDelegate(XNNPackDelegate());
      }
      
      _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite', options: options);
      _isModelLoaded = true;
      print('Face Recognition Model loaded successfully.');
      
      // Print input/output shapes for debugging
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      print('Model Input Shape: $inputShape'); // Expected: [1, 640, 640, 3] or [1, 3, 640, 640]
      print('Model Output Shape: $outputShape');
    } catch (e) {
      print('Error loading Face Recognition Model: $e');
    }
  }

  /// Close interpreter
  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
  }

  /// Run inference on an image
  /// Returns the name of the detected person with the highest confidence, or null if none/unknown
  Future<String?> detectFaces(img.Image image) async {
    if (!_isModelLoaded || _interpreter == null) return null;

    try {
      // 1. Preprocess
      final inputTensor = _preprocessImage(image);

      // 2. Inference
      // output shape depends on model export. YOLOv8 usually: [1, 84, 8400] (class: 80) -> here classes=4, so [1, 4+4, 8400] -> [1, 8, 8400]
      // Or transposed [1, 8400, 8]
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputBuffer = Float32List(outputShape.reduce((a, b) => a * b));
      
      // Use ByteBuffer to avoid shape mismatch issues with flattened lists
      // This maps 1:1 to the input tensor memory
      _interpreter!.run(inputTensor.buffer, outputBuffer.buffer);

      // 3. Postprocess (Parse YOLOv8 output)
      // We need to reshape the flat buffer to the output dimensions
      // Assuming output is [1, 8400, 8] or [1, 8, 8400]. 
      // Most standard YOLOv8 tflite exports are [1, 4+nc, 8400]
      
      final detections = _postProcessYOLOv8(outputBuffer, outputShape, image.width, image.height);
      
      // LOGGING FOR USER
      if (detections.isNotEmpty) {
        print('--- TFLite Detections ---');
        for (var d in detections) {
            print('${d.label}: ${(d.confidence * 100).toStringAsFixed(1)}%');
        }
        print('-------------------------');
      } else {
        print('--- TFLite: No faces detected ---');
      }
      
      if (detections.isEmpty) return null;

      // Return the label of the highest confidence detection
      return detections.first.label;

    } catch (e) {
      print('Error running detection: $e');
      return null;
    }
  }

  /// Preprocess image for YOLOv8 (Letterbox Resize to 640x640, Normalize 0-1)
  Float32List _preprocessImage(img.Image srcImage) {
    // Calculate scale to fit 640x640 while maintaining aspect ratio
    double scale = min(_inputSize / srcImage.width, _inputSize / srcImage.height);
    int newWidth = (srcImage.width * scale).round();
    int newHeight = (srcImage.height * scale).round();

    // Resize source image
    final resized = img.copyResize(srcImage, width: newWidth, height: newHeight);

    // Create a black square canvas
    final canvas = img.Image(width: _inputSize, height: _inputSize);
    // Fill with black (0,0,0) - assuming image package v4+ semantics or default
    // If fill is not available/easy, the default image is usually 0-initialized (black transparent or black)
    // For standard RGB, 0 values are fine.
    
    // Center the image on the canvas
    int offsetX = (_inputSize - newWidth) ~/ 2;
    int offsetY = (_inputSize - newHeight) ~/ 2;
    
    img.compositeImage(canvas, resized, dstX: offsetX, dstY: offsetY);
    
    // Convert to Float32 List [1, 640, 640, 3] and normalize to 0-1
    final imageBytes = canvas.getBytes(order: img.ChannelOrder.rgb);
    final input = Float32List(1 * _inputSize * _inputSize * 3);
    
    for (int i = 0; i < imageBytes.length; i++) {
        input[i] = imageBytes[i] / 255.0;
    }
    
    return input;
  }

  /// Post-process YOLOv8 output
  List<DetectionResult> _postProcessYOLOv8(Float32List output, List<int> shape, int imgWidth, int imgHeight) {
   
    
    int numAttributes = 4 + _labels.length; // 4 box + 4 classes = 8
    int numAnchors = 8400; // usually fixed for 640x640
    
    // Check shapes
    bool isOutputTransposed = false;
    if (shape[1] == numAnchors && shape[2] == numAttributes) {
        // Shape is [1, 8400, 8]
        isOutputTransposed = true;
    }
    
    List<DetectionResult> results = [];

    for (int i = 0; i < numAnchors; i++) {
      double maxClassScore = 0.0;
      int classId = -1;
      
      // Extract class scores
      for (int c = 0; c < _labels.length; c++) {
        double score;
        if (isOutputTransposed) {
            score = output[i * numAttributes + 4 + c];
        } else {
            // [1, 8, 8400] -> [0][4+c][i]
           score = output[(4 + c) * numAnchors + i];
        }
        
        if (score > maxClassScore) {
          maxClassScore = score;
          classId = c;
        }
      }

      if (maxClassScore > _confThreshold) {
        // Extract Box
        double cx, cy, w, h;
        if (isOutputTransposed) {
            cx = output[i * numAttributes + 0];
            cy = output[i * numAttributes + 1];
            w = output[i * numAttributes + 2];
            h = output[i * numAttributes + 3];
        } else {
            cx = output[0 * numAnchors + i];
            cy = output[1 * numAnchors + i];
            w = output[2 * numAnchors + i];
            h = output[3 * numAnchors + i];
        }
        
        // Convert to corner coords (cx,cy,w,h is normalized to 640x640 usually, or absolute 640)
        // YOLOv8 tflite usually outputs absolute coords in 640x640 space
        
        // We don't strictly need accurate bounding boxes for this task, just the class with high confidence.
        // But let's keep it clean.
        
        results.add(DetectionResult(
          label: _labels[classId],
          confidence: maxClassScore,
          box: [cx, cy, w, h], // Just storing distinct values
        ));
      }
    }

    // Apply NMS (Non-Max Suppression) - Simplified: Just take highest confidence for now
    // Since we just need to know "Is the user present?", highest confidence is usually enough.
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return results;
  }
  
  /// Helper to convert CameraImage to Image (if needed later)
  // This is complex in Dart, usually better done via FFI or platform channels, 
  // but for TFLite we typically need RGB bytes.
}

class DetectionResult {
  final String label;
  final double confidence;
  final List<double> box;

  DetectionResult({required this.label, required this.confidence, required this.box});
}
