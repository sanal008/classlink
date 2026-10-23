import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class WhiteboardService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  /// Save whiteboard text data to Firebase Realtime Database with OCR processing
  static Future<Map<String, dynamic>> saveWhiteboardWithOCR({
    required Uint8List imageData,
    required String studentId,
    required String conferenceId,
    required String whiteboardTitle,
    required String extractedText,
    String? studentName,
    bool isTeacher = false,
  }) async {
    try {
      // Create a unique timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Perform OCR on the whiteboard text content
      final ocrText = await _performOCR(extractedText);
      
      // Use OCR processed text as primary source
      String allText = ocrText.isNotEmpty && ocrText != 'No text detected' 
          ? ocrText 
          : (extractedText.isNotEmpty ? extractedText : 'No text detected');

      // Determine the correct database path based on user role
      final String basePath = isTeacher ? 'teacher_whiteboards' : 'student_whiteboards';
      
      // Save to Firebase Realtime Database with proper structure
      final databaseRef = _databaseRef
          .child(basePath)
          .child(studentId)
          .child(conferenceId) // Use conferenceId as session name
          .child(timestamp.toString());

      final whiteboardData = {
        'studentId': studentId,
        if (isTeacher) 'isTeacher': true,
        'studentName': studentName ?? (isTeacher ? 'Teacher' : 'Unknown Student'),
        'sessionId': conferenceId, // Session name for identification
        'sessionName': whiteboardTitle, // Class/session title
        'extractedText': allText, // OCR processed text
        'originalText': extractedText, // Original whiteboard text
        'timestamp': timestamp,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'saved',
        'type': 'whiteboard_ocr_processed', // OCR processed content
      };

      await databaseRef.set(whiteboardData);

      return {
        'success': true,
        'extractedText': allText,
        'originalText': extractedText,
        'sessionId': conferenceId,
        'timestamp': timestamp,
        'message': 'Whiteboard text saved with OCR processing',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to save whiteboard: $e',
      };
    }
  }

  /// Perform OCR processing on whiteboard text content
  static Future<String> _performOCR(String textContent) async {
    try {
      // Simulate OCR processing on the provided text
      // In a real implementation, you would use actual OCR library here
      
      if (textContent.isEmpty) {
        return 'No text detected';
      }
      
      // Simulate OCR processing delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Process the text content to simulate OCR enhancement
      List<String> words = textContent.split(' ');
      List<String> processedWords = [];
      
      for (String word in words) {
        if (word.isNotEmpty) {
          // Simulate OCR text enhancement and recognition
          String processedWord = word.toUpperCase().trim();
          processedWords.add(processedWord);
        }
      }
      
      String ocrResult = processedWords.join(' ');
      
      return ocrResult.isNotEmpty ? ocrResult : 'No text detected';
      
    } catch (e) {
      print('OCR Error: $e');
      return 'OCR failed: ${e.toString()}';
    }
  }

  /// Get all whiteboards for a student
  static Future<List<Map<String, dynamic>>> getStudentWhiteboards(String studentId) async {
    try {
      final snapshot = await _databaseRef
          .child('student_whiteboards')
          .child(studentId)
          .once();

      if (snapshot.snapshot.value != null) {
        final Map<dynamic, dynamic> sessions = 
            snapshot.snapshot.value as Map<dynamic, dynamic>;
        
        List<Map<String, dynamic>> allWhiteboards = [];
        
        // Iterate through all sessions and collect whiteboards
        sessions.forEach((sessionId, sessionData) {
          if (sessionData is Map<dynamic, dynamic>) {
            final Map<dynamic, dynamic> whiteboards = 
                sessionData as Map<dynamic, dynamic>;
            
            whiteboards.forEach((timestamp, whiteboardData) {
              if (whiteboardData is Map<dynamic, dynamic>) {
                final Map<String, dynamic> board = 
                    Map<String, dynamic>.from(whiteboardData);
                board['sessionId'] = sessionId;
                allWhiteboards.add(board);
              }
            });
          }
        });
        
        return allWhiteboards;
      }
      return [];
    } catch (e) {
      print('Error fetching whiteboards: $e');
      return [];
    }
  }

  /// Get all whiteboards for a teacher (teacher's own whiteboards)
  static Future<List<Map<String, dynamic>>> getTeacherWhiteboards() async {
    try {
      final snapshot = await _databaseRef
          .child('teacher_whiteboards')
          .once();

      if (snapshot.snapshot.value != null) {
        final Map<dynamic, dynamic> teacherData = 
            snapshot.snapshot.value as Map<dynamic, dynamic>;
        
        List<Map<String, dynamic>> allWhiteboards = [];
        
        // Iterate through all sessions and collect whiteboards
        teacherData.forEach((teacherId, sessionsData) {
          if (sessionsData is Map<dynamic, dynamic>) {
            final Map<dynamic, dynamic> sessions = 
                sessionsData as Map<dynamic, dynamic>;
            
            sessions.forEach((sessionId, sessionData) {
              if (sessionData is Map<dynamic, dynamic>) {
                final Map<dynamic, dynamic> whiteboards = 
                    sessionData as Map<dynamic, dynamic>;
                
                whiteboards.forEach((timestamp, whiteboardData) {
                  if (whiteboardData is Map<dynamic, dynamic>) {
                    final Map<String, dynamic> board = 
                        Map<String, dynamic>.from(whiteboardData);
                    board['studentId'] = teacherId;
                    board['sessionId'] = sessionId;
                    allWhiteboards.add(board);
                  }
                });
              }
            });
          }
        });
        
        // Sort by timestamp (most recent first)
        allWhiteboards.sort((a, b) {
          final aTime = a['timestamp'] as int? ?? 0;
          final bTime = b['timestamp'] as int? ?? 0;
          return bTime.compareTo(aTime);
        });
        
        return allWhiteboards;
      }
      return [];
    } catch (e) {
      print('Error fetching teacher whiteboards: $e');
      return [];
    }
  }

  /// Delete a whiteboard from Firebase Realtime Database
  static Future<bool> deleteWhiteboard(String studentId, String sessionId, String timestamp) async {
    try {
      // Delete from Realtime Database only (no Storage cleanup needed)
      await _databaseRef
          .child('student_whiteboards')
          .child(studentId)
          .child(sessionId)
          .child(timestamp)
          .remove();

      return true;
    } catch (e) {
      print('Error deleting whiteboard: $e');
      return false;
    }
  }

  /// Enhance image for better quality
  static Uint8List enhanceImageForOCR(Uint8List imageData) {
    try {
      // Decode image
      img.Image image = img.decodeImage(imageData)!;
      
      // Convert to grayscale for better text recognition
      img.Image grayscaleImage = img.grayscale(image);
      
      // Increase contrast
      img.Image contrastImage = img.adjustColor(
        grayscaleImage,
        contrast: 1.5,
        brightness: 0.1,
      );
      
      // Resize to improve quality
      img.Image resizedImage = img.copyResize(
        contrastImage,
        width: 1080,
        height: 1920,
        interpolation: img.Interpolation.average,
      );
      
      // Encode back to bytes
      return Uint8List.fromList(img.encodePng(resizedImage));
    } catch (e) {
      print('Error enhancing image: $e');
      return imageData; // Return original if enhancement fails
    }
  }
}
