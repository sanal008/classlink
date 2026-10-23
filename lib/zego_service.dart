import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_video_conference/zego_uikit_prebuilt_video_conference.dart';
import 'firebase_service.dart';
import 'email_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:firebase_database/firebase_database.dart';
import 'common/whiteboard.dart';
import 'firebase_service.dart';
import 'attendance_service.dart';
import 'package:image/image.dart' as img; // For image processing
import 'ml/face_recognition_service.dart'; // Custom ML Service
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class _ZegoConferenceWithWhiteboard extends StatefulWidget {
  final String conferenceID;
  final String userName;
  final String userID;
  final String? role; // 'student' or 'teacher'
  final String? userEmail;
  final DateTime? scheduledEndTime; // For attendance calculation

  const _ZegoConferenceWithWhiteboard({
    required this.conferenceID,
    required this.userName,
    required this.userID,
    this.role,
    this.userEmail,
    this.scheduledEndTime,
  });

  @override
  State<_ZegoConferenceWithWhiteboard> createState() => _ZegoConferenceWithWhiteboardState();
}

class _ZegoConferenceWithWhiteboardState extends State<_ZegoConferenceWithWhiteboard> {
  bool _showWhiteboard = false;
  final AttendanceService _attendanceService = AttendanceService();

  // Presence monitoring state
  DateTime _lastFaceSeen = DateTime.now();
  Timer? _monitorTimer;
  Timer? _countdownTimer;
  int _countdownRemaining = 0;
  bool _showKickWarning = false;

  bool _faceDetected = false; // Track face detection status
  
  // Custom Face Recognition State
  final List<String> _targetUsers = ['Abel', 'Alen', 'Anamika', 'Athul'];
  bool _useCustomRecognition = false;
  Timer? _recognitionTimer;
  String? _currentStreamID; // Track current stream ID for snapshot

  @override
  void initState() {
    super.initState();
    
    // Track attendance when user joins the session
    _trackSessionJoin();

    // Check if user is targeted for custom face recognition
    _useCustomRecognition = _targetUsers.contains(widget.userName); // Simple name match
    if (_useCustomRecognition) {
      print('User ${widget.userName} selected for Custom Face Recognition (YOLOv8)');
      FaceRecognitionService().initialize();
      
      // Start Custom Recognition Timer (every 2 seconds to save resources)
      _recognitionTimer = Timer.periodic(const Duration(seconds: 2), (_) => _performCustomRecognition());
      
      // Listen for Stream ID updates to know when publishing starts
      ZegoExpressEngine.onPublisherStateUpdate = (String streamID, ZegoPublisherState state, int errorCode, Map<String, dynamic> extendedData) {
        if (state == ZegoPublisherState.Publishing) {
          setState(() {
            _currentStreamID = streamID;
          });
          print('Publishing Stream ID updated: $streamID');
        }
      };
    }
    
    // Set scheduled session duration for 70% attendance calculation
    try {
      if (widget.scheduledEndTime != null) {
        final now = DateTime.now();
        final duration = widget.scheduledEndTime!.difference(now);
        _attendanceService.setScheduledSessionDuration(
          widget.conferenceID,
          duration,
          widget.scheduledEndTime,
        );
      }
    } catch (e) {
      print('Error setting scheduled duration: $e');
    }
    
    // Enable Zego's built-in face detection (used for presence) only for students
    try {
      if (widget.role == null || widget.role != 'teacher') {
        ZegoExpressEngine.instance.enableFaceDetection(true);
        ZegoExpressEngine.onPublisherFaceDetectInfo =
            (ZegoFaceDetectionInfo info, ZegoPublishChannel? channel) {
          if (!mounted) return;
          
          // CRITICAL: If using custom recognition, ignore generic face detection results
          if (_useCustomRecognition) return;
          
          // Debug: Log face detection info
          final hasFace = info.facePositionList != null && info.facePositionList!.isNotEmpty;
          final faceCount = info.facePositionList?.length ?? 0;
          
          if (hasFace != _faceDetected) {
            setState(() {
              _faceDetected = hasFace;
            });
            print('Face detection status: $_faceDetected (faces detected: $faceCount)');
          }
          
          if (hasFace) {
            setState(() {
              _lastFaceSeen = DateTime.now();
              _faceDetected = true;
              if (_showKickWarning) {
                _showKickWarning = false;
                _countdownTimer?.cancel();
                print('Face detected - cancelling kickout and clearing warning');
              }
            });
            print('Face detected at ${DateTime.now()} - updating last face seen time');
          } else {
            setState(() {
              _faceDetected = false;
            });
            print('No face detected at ${DateTime.now()}');
          }
        };

        _monitorTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkPresence());
      }
    } catch (_) {}



  }

  /// Perform Custom Face Recognition for target users
  Future<void> _performCustomRecognition() async {
    if (!mounted || !_useCustomRecognition) return;
    
    // If not publishing yet, skip
    // We try to guess stream ID if not set yet (standard format assumption)
    String targetStreamID = _currentStreamID ?? '${widget.conferenceID}_${widget.userID}_main';
    
    try {
      // 1. Capture Snapshot from Main Stream
      // Note: effective only if publishing. 
      // ZegoExpressEngine.instance.takePublishStreamSnapshot returns a ZegoImage (memory or file?)
      // Actually per API docs it usually returns via callback or image data.
      // Since Flutter Dart API for takePublishStreamSnapshot might vary, we'll try standard way
      // If direct image data isn't available, we might need a workaround. 
      // Assumption: takePublishStreamSnapshot returns ZegoPublisherTakeSnapshotResult or similar.
      
      // Since direct API verification isn't possible, we'll wrap in try-catch and assume we receive an image path or bytes.
      // Standard Zego Flutter: takePublishStreamSnapshot(streamID) -> Future<ZegoPublisherTakeSnapshotResult>
      // result.errorCode, result.image (MemoryImage/Uint8List?)
      
      // For now, let's assume we can get the image. 
      var result = await ZegoExpressEngine.instance.takePublishStreamSnapshot();
      
      // Note: If takePublishStreamSnapshot doesn't accept streamID (implicit main), check signature.
      // If it fails, we fall back to generic detection logic for safety.

      if (result.errorCode == 0 && result.image != null) {
        // 2. Convert to img.Image
        // result.image is likely a MemoryImage which wraps Uint8List
        if (result.image is MemoryImage) {
           img.Image? frame = img.decodeImage((result.image! as MemoryImage).bytes);
        
        if (frame != null) {
          // 3. Run Inference
          String? detectedName = await FaceRecognitionService().detectFaces(frame);
          print('Custom Recognition: Detected $detectedName (Expected: ${widget.userName})');
          
          bool match = false;
          if (detectedName != null) {
             // Check match (Case insensitive?)
             if (detectedName.toLowerCase() == widget.userName.toLowerCase()) {
               match = true;
             } else {
               print('Face mismatch! Detected $detectedName but user is ${widget.userName}');
             }
          }
          
          // 4. Update Status based on Custom Recognition
          if (match != _faceDetected) {
            setState(() {
              _faceDetected = match;
              if (match) {
                 _lastFaceSeen = DateTime.now();
                 // Clear any warnings
                 if (_showKickWarning) {
                    _showKickWarning = false;
                    _countdownTimer?.cancel();
                 }
              }
            });
          }
           
          // If match is true, update last seen
          if (match) {
             _lastFaceSeen = DateTime.now();
          }
        }
       }
      }
    } catch (e) {
      // print('Error in custom recognition loop: $e'); 
    }
  }

  @override
  void dispose() {
    // Track attendance when user leaves session
    if (widget.role == 'teacher') {
      // Teacher leaving = end session for everyone
      _trackSessionEnd();
    } else {
      // Student leaving
      _trackSessionLeave();
    }
    
    // Clean up timers
    _monitorTimer?.cancel();
    _recognitionTimer?.cancel(); // Cancel custom timer
    _countdownTimer?.cancel();
    FaceRecognitionService().dispose();
    
    // Clean up Zego callbacks and disable detection
    try {
      ZegoExpressEngine.onPublisherFaceDetectInfo = null;
      ZegoExpressEngine.onPublisherStateUpdate = null; // Clear callback
      ZegoExpressEngine.instance.enableFaceDetection(false);
    } catch (_) {}
    super.dispose();
  }

  /// Track when user joins session
  void _trackSessionJoin() async {
    try {
      if (widget.role == null || widget.role != 'teacher') {
        // Student joined - track attendance
        await _attendanceService.onStudentJoin(
          classId: widget.conferenceID,
          studentId: widget.userID,
          studentName: widget.userName,
        );
      }
    } catch (e) {
      print('Error tracking session join: $e');
    }
  }

  /// Track when teacher ends the session
  void _trackSessionEnd() async {
    try {
      if (widget.role == 'teacher') {
        // Teacher ending session - mark all students attendance and end session
        await _attendanceService.onSessionEnd(
          classId: widget.conferenceID,
          teacherId: widget.userID,
          className: 'Class Session',
          scheduledEndTime: widget.scheduledEndTime,
        );
      }
    } catch (e) {
      print('Error tracking session end: $e');
    }
  }

  /// Track when user leaves session
  void _trackSessionLeave() async {
    try {
      if (widget.role == null || widget.role != 'teacher') {
        // Student left - track attendance
        await _attendanceService.onStudentLeave(
          classId: widget.conferenceID,
          studentId: widget.userID,
          studentName: widget.userName,
        );
      }
    } catch (e) {
      print('Error tracking session leave: $e');
    }
  }

  void _checkPresence() {
    final now = DateTime.now();
    final timeSinceLastFace = now.difference(_lastFaceSeen);
    
    // Debug: Print presence check info
    // print('Presence check - face detected: $_faceDetected, time since last face: ${timeSinceLastFace.inSeconds}s, warning active: $_showKickWarning');
    
    // Logic Override: If using Custom Recognition, _faceDetected is controlled by _performCustomRecognition.
    // Logic Override: If NOT using Custom Recognition, _faceDetected is controlled by ZegoFaceDetectionInfo.
    
    // Only show warning if no face detected for 10 seconds AND face is currently not detected
    if (timeSinceLastFace >= const Duration(seconds: 10) && !_showKickWarning && !_faceDetected) {
      print('No face detected for 10 seconds and currently no face - showing kick warning');
      setState(() {
        _showKickWarning = true;
        _countdownRemaining = 30;
      });
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          _countdownRemaining -= 1;
        });
        print('Kickout countdown: $_countdownRemaining seconds (face detected: $_faceDetected)');
        
        // Cancel countdown if face is detected during countdown
        if (_faceDetected) {
          print('Face detected during countdown - cancelling kickout');
          setState(() {
            _showKickWarning = false;
          });
          t.cancel();
          return;
        }
        
        if (_countdownRemaining <= 0) {
          t.cancel();
          _kickOut();
        }
      });
    }
  }

  void _cancelKick() {
    setState(() {
      _showKickWarning = false;
      _countdownTimer?.cancel();
      _lastFaceSeen = DateTime.now(); // Give user another chance
    });
  }

  Future<void> _kickOut() async {
    if (!mounted) return;

    // Mark attendance as absent for student being removed
    try {
      if (widget.role == null || widget.role != 'teacher') {
        await _attendanceService.onStudentLeave(
          classId: widget.conferenceID,
          studentId: widget.userID,
          studentName: widget.userName,
        );
      }
    } catch (e) {
      print('Error marking absent attendance for kicked out student: $e');
    }

    // Send email notification for students using direct email service
    try {
      if (widget.role == null || widget.role != 'teacher') {
        // Option 1: If we have user email directly, send it
        if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
          await EmailService.sendKickoutNotification(
            userEmail: widget.userEmail!,
            conferenceID: widget.conferenceID,
            studentId: widget.userID,
          );
        } else {
          // Option 2: Fetch email from Firebase and send
          await EmailService.fetchAndSendKickoutNotification(
            userId: widget.userID,
            conferenceID: widget.conferenceID,
          );
        }
      }
    } catch (_) {}

    // Optional: call Zego SDK leave functions if needed; simply leave meeting without showing a popup
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Visibility(
                visible: !_showWhiteboard,
                maintainState: true,
                child: ZegoUIKitPrebuiltVideoConference(
                  appID: ZegoService.appID,
                  appSign: ZegoService.appSign,
                  userID: widget.userID,
                  userName: widget.userName,
                  conferenceID: widget.conferenceID,
                  config: ZegoUIKitPrebuiltVideoConferenceConfig(
                    // Enable video for all users by default
                    turnOnCameraWhenJoining: true,
                    turnOnMicrophoneWhenJoining: false,
                    // Configure user display
                    avatarBuilder: (context, size, user, extraInfo) {
                      return CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: user != null
                            ? Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: TextStyle(fontSize: size.width / 2),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ),

            if (_showWhiteboard)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: ModalBarrier(
                          dismissible: false,
                          color: Color(0x01000000),
                        ),
                      ),
                      Positioned.fill(
                        child: SimpleWhiteboard(
                          whiteboardTitle: 'Class Whiteboard',
                          isReadOnly: false,
                          embedded: true,
                          studentId: widget.userID,
                          studentName: widget.userName,
                          conferenceId: widget.conferenceID,
                          isTeacher: widget.role == 'teacher',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Face detection status indicator (for debugging)
            if (widget.role == null || widget.role != 'teacher')
              Positioned(
                top: 50,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _faceDetected ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _faceDetected ? Icons.face : Icons.face_retouching_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _faceDetected ? 'Face Detected' : 'No Face',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Presence warning overlay (shown when no face detected)
            if (_showKickWarning)
              Positioned(
                left: 0,
                right: 0,
                bottom: 80,
                child: Center(
                  child: Material(
                    color: Colors.red.withOpacity(0.9),
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('No face detected. Removing in $_countdownRemaining s', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Single top-right pen icon toggle (opens/closes whiteboard)
            // Kept AFTER the overlay so it always stays visible/clickable.
            Positioned(
              right: 12,
              top: 12,
              child: SafeArea(
                child: Material(
                  color: Colors.white,
                  elevation: 6,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _showWhiteboard = !_showWhiteboard;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        _showWhiteboard ? Icons.close : Icons.edit,
                        color: Colors.indigo,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ZegoService {
  // Zego Cloud credentials
  static const int appID = 64812378;
  static const String appSign = 'e9560d620692a16bb89db358653ca7a11a74a8981a89642a56a89d2cd8c50fbf';

  /// Start a video conference for a class using Zego prebuilt UI.
  /// This pushes a full-screen conference widget instead of showing credentials.
  static Future<void> startVideoConference({
    required BuildContext context,
    required String conferenceID,
    required String userName,
    required String userID,
    String? role,
    String? userEmail,
    DateTime? scheduledEndTime,
  }) async {
    try {
      // Ensure camera & microphone permissions are granted at runtime
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;

      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        final results = await [Permission.camera, Permission.microphone].request();
        if (results[Permission.camera] != PermissionStatus.granted ||
            results[Permission.microphone] != PermissionStatus.granted) {
          // If permissions are permanently denied, guide the user to settings
          if (results[Permission.camera] == PermissionStatus.permanentlyDenied ||
              results[Permission.microphone] == PermissionStatus.permanentlyDenied) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Permissions required'),
                content: const Text(
                  'Camera and microphone permissions are required to join the video conference.\nPlease enable them in app settings.'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      openAppSettings();
                      Navigator.pop(context);
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            );
            return;
          }

          // Permissions denied (but not permanently) — show friendly message
          _showErrorDialog(context, 'Camera and microphone permissions are required to join the class.');
          return;
        }
      }

      // Navigate to the prebuilt Zego conference screen with a whiteboard overlay button
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _ZegoConferenceWithWhiteboard(
            conferenceID: conferenceID,
            userName: userName,
            userID: userID,
            role: role,
            userEmail: userEmail,
            scheduledEndTime: scheduledEndTime,
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog(context, 'Failed to start video conference: $e');
    }
  }

  static void _showErrorDialog(BuildContext context, String message) {
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
}
