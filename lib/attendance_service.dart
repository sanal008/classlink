import 'dart:async';
import 'models.dart';
import 'firebase_service.dart';
import 'package:firebase_database/firebase_database.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  // Minimum presence required: 70% of scheduled session time
  static const double _minPresencePercentage = 0.70;
  final Map<String, DateTime> _sessionJoinTimes = {};
  final Map<String, Set<String>> _activeStudents = {};
  final Map<String, Timer?> _sessionTimers = {};
  final Map<String, bool> _sessionEnded = {};
  final Map<String, DateTime> _sessionScheduledEndTimes = {}; // Track scheduled end times
  final Map<String, Duration> _sessionScheduledDurations = {}; // Store scheduled duration
  final Map<String, Set<String>> _recordedStudents = {}; // Track which students already have records for a session

  /// Called when a student joins a class session
  Future<void> onStudentJoin({
    required String classId,
    required String studentId,
    required String studentName,
  }) async {
    final now = DateTime.now();
    
    // Record join time
    _sessionJoinTimes['${classId}_$studentId'] = now;
    
    // Add to active students for this session
    if (!_activeStudents.containsKey(classId)) {
      _activeStudents[classId] = <String>{};
    }
    _activeStudents[classId]!.add(studentId);
    
    // Store session participant in Firebase for real-time tracking
    await FirebaseDatabase.instance
        .ref('active_sessions/$classId/participants/$studentId')
        .set({
          'studentId': studentId,
          'studentName': studentName,
          'joinTime': now.toIso8601String(),
          'status': 'active',
        });
    
    print('Student $studentName ($studentId) joined class $classId at $now');
  }

  /// Set scheduled session duration for accurate 70% calculation
  void setScheduledSessionDuration(String classId, Duration duration, DateTime? scheduledEndTime) {
    _sessionScheduledDurations[classId] = duration;
    if (scheduledEndTime != null) {
      _sessionScheduledEndTimes[classId] = scheduledEndTime;
    }
    print('Set scheduled duration for session $classId: ${duration.inMinutes} minutes');
  }

  /// Called when a student leaves a class session
  Future<void> onStudentLeave({
    required String classId,
    required String studentId,
    required String studentName,
    bool sessionEnded = false,
  }) async {
    final joinTimeKey = '${classId}_$studentId';
    final joinTime = _sessionJoinTimes[joinTimeKey];
    
    // Check if session has been marked as ended by teacher
    final hasSessionEnded = _sessionEnded[classId] ?? false;
    
    // Remove from active students
    _activeStudents[classId]?.remove(studentId);
    
    // Get teacher name and ID from active session
    String? teacherName;
    String? teacherId;
    try {
      final sessionSnapshot = await FirebaseDatabase.instance.ref('active_sessions/$classId').once();
      if (sessionSnapshot.snapshot.exists) {
        final sessionData = Map<String, dynamic>.from(sessionSnapshot.snapshot.value as Map);
        teacherName = sessionData['teacherName']?.toString();
        teacherId = sessionData['teacherId']?.toString();
      }
    } catch (e) {
      print('Error fetching teacher info: $e');
    }
    
    // Record leave time once and update Firebase participant status
    final leaveTime = DateTime.now();
    await FirebaseDatabase.instance
        .ref('active_sessions/$classId/participants/$studentId')
        .update({
          'status': hasSessionEnded ? 'session_ended' : (sessionEnded ? 'session_ended' : 'left_early'),
          'leaveTime': leaveTime.toIso8601String(),
        });
    
    // If session ended OR sessionEnded parameter is true, we'll handle attendance in onSessionEnd
    if (!hasSessionEnded && !sessionEnded) {
      // Student left early - determine present/absent based on 70% of scheduled duration
      String statusToMark = 'absent';
      if (joinTime != null) {
        final duration = leaveTime.difference(joinTime);
        final scheduledDuration = _sessionScheduledDurations[classId];
        
        if (scheduledDuration != null) {
          // Calculate if student was present for 70% of scheduled time
          final requiredDuration = Duration(
            milliseconds: (scheduledDuration.inMilliseconds * _minPresencePercentage).toInt(),
          );
          if (duration >= requiredDuration) {
            statusToMark = 'present';
          }
        } else {
          // Fallback: mark as present if at least 10 seconds
          if (duration >= const Duration(seconds: 10)) {
            statusToMark = 'present';
          }
        }
      }
      await _createAttendanceRecord(
        classId: classId,
        studentId: studentId,
        studentName: studentName,
        status: statusToMark,
        joinTime: joinTime,
        leaveTime: leaveTime,
        scheduledDuration: _sessionScheduledDurations[classId],
        teacherName: teacherName, // Pass teacher name
        teacherId: teacherId, // Pass teacher ID
      );
    }
    
    // Clean up join time tracking
    _sessionJoinTimes.remove(joinTimeKey);
    
    print('Student $studentName ($studentId) left class $classId ${hasSessionEnded ? "at session end" : (sessionEnded ? "at session end" : "early")}');
  }

  /// Called when teacher ends the session
  Future<void> onSessionEnd({
    required String classId,
    required String teacherId,
    required String className,
    DateTime? scheduledEndTime,
  }) async {
    // Mark session as ended
    _sessionEnded[classId] = true;
    
    final activeStudents = _activeStudents[classId] ?? <String>{};
    
    // Calculate scheduled duration for attendance calculation
    DateTime? sessionStartTime;
    DateTime? sessionEndTime = scheduledEndTime;
    
    if (scheduledEndTime == null) {
      // If no scheduled end time provided, use current time as end
      sessionEndTime = DateTime.now();
    }
    
    print('Session $classId ended by teacher. Active students: ${activeStudents.length}');
    
    // Get teacher name and ID from active session
    String? teacherName;
    String? teacherId;
    try {
      final sessionSnapshot = await FirebaseDatabase.instance.ref('active_sessions/$classId').once();
      if (sessionSnapshot.snapshot.exists) {
        final sessionData = Map<String, dynamic>.from(sessionSnapshot.snapshot.value as Map);
        teacherName = sessionData['teacherName']?.toString();
        teacherId = sessionData['teacherId']?.toString();
      }
    } catch (e) {
      print('Error fetching teacher info: $e');
    }
    
    // Mark all currently active students as present or absent based on 70% attendance
    for (final studentId in activeStudents) {
      final joinTimeKey = '${classId}_$studentId';
      final joinTime = _sessionJoinTimes[joinTimeKey];
      
      // Get student name from Firebase
      final studentSnapshot = await FirebaseDatabase.instance
          .ref('users/$studentId/name')
          .once();
      
      final studentName = studentSnapshot.snapshot.value?.toString() ?? 'Unknown Student';
      
      final leaveTime = DateTime.now();
      String statusToMark = 'absent';
      
      if (joinTime != null) {
        final duration = leaveTime.difference(joinTime);
        final scheduledDuration = _sessionScheduledDurations[classId];
        
        if (scheduledDuration != null) {
          // Calculate if student was present for 70% of scheduled time
          final requiredDuration = Duration(
            milliseconds: (scheduledDuration.inMilliseconds * _minPresencePercentage).toInt(),
          );
          if (duration >= requiredDuration) {
            statusToMark = 'present';
          }
        } else {
          // Fallback: mark as present if at least 10 seconds
          if (duration >= const Duration(seconds: 10)) {
            statusToMark = 'present';
          }
        }
      }
      
      await _createAttendanceRecord(
        classId: classId,
        studentId: studentId,
        studentName: studentName,
        status: statusToMark,
        joinTime: joinTime,
        leaveTime: leaveTime,
        scheduledDuration: _sessionScheduledDurations[classId],
        teacherName: teacherName, // Pass teacher name
        teacherId: teacherId, // Pass teacher ID
      );
    }
    
    // Clean up session data
    _activeStudents.remove(classId);
    _sessionTimers[classId]?.cancel();
    _sessionTimers.remove(classId);
    _sessionEnded.remove(classId);
    _sessionScheduledDurations.remove(classId);
    _sessionScheduledEndTimes.remove(classId);
    _recordedStudents.remove(classId);
    
    // Remove session from active sessions in Firebase
    await FirebaseDatabase.instance
        .ref('active_sessions/$classId')
        .remove()
        .catchError((e) {
          print('Note: active_sessions/$classId may already be removed: $e');
        });
    
    // Clean up join times for this session
    _sessionJoinTimes.removeWhere((key, value) => key.startsWith('${classId}_'));
    
    print('Session $classId attendance processing completed');
  }

  /// Create attendance record in Firebase
  Future<void> _createAttendanceRecord({
    required String classId,
    required String studentId,
    required String studentName,
    required String status,
    DateTime? joinTime,
    DateTime? leaveTime,
    Duration? scheduledDuration,
    String? teacherName, // Add teacher name parameter
    String? teacherId, // Add teacher ID parameter
  }) async {
    try {
      // Check if attendance already recorded for this student in this session
      if (_recordedStudents[classId]?.contains(studentId) ?? false) {
        print('Attendance already recorded for student $studentId in session $classId');
        return;
      }
      
      final now = DateTime.now();
      final attendanceId = 'attendance_${classId}_${studentId}_${now.millisecondsSinceEpoch}';
      
      // Calculate duration if both times are available
      Duration duration = Duration.zero;
      if (joinTime != null && leaveTime != null) {
        duration = leaveTime.difference(joinTime);
      }
      
      final attendance = Attendance(
        id: attendanceId,
        studentId: studentId,
        classId: classId,
        date: now,
        status: status,
        duration: duration,
        joinTime: joinTime,
        leaveTime: leaveTime,
        teacherName: teacherName, // Pass teacher name to constructor
        teacherId: teacherId, // Pass teacher ID to constructor
      );
      
      await _firebaseService.markAttendance(attendance);
      
      // Mark this student as having a record for this session
      if (!_recordedStudents.containsKey(classId)) {
        _recordedStudents[classId] = <String>{};
      }
      _recordedStudents[classId]!.add(studentId);
      
      // Calculate presence percentage if scheduled duration available
      double presencePercentage = 0;
      if (scheduledDuration != null && scheduledDuration.inMilliseconds > 0) {
        presencePercentage = (duration.inMilliseconds / scheduledDuration.inMilliseconds) * 100;
      }
      
      print('Created attendance record: $attendanceId for $studentName - Status: $status, Duration: ${duration.inMinutes}min, Presence: ${presencePercentage.toStringAsFixed(1)}%');
    } catch (e) {
      print('Error creating attendance record: $e');
    }
  }

  /// Get active students count for a session
  int getActiveStudentsCount(String classId) {
    return _activeStudents[classId]?.length ?? 0;
  }

  /// Check if a student is currently active in a session
  bool isStudentActive(String classId, String studentId) {
    return _activeStudents[classId]?.contains(studentId) ?? false;
  }

  /// Clean up expired sessions (call this periodically)
  Future<void> cleanupExpiredSessions() async {
    final now = DateTime.now();
    final expiredSessions = <String>[];
    
    for (final classId in _activeStudents.keys) {
      final sessionSnapshot = await FirebaseDatabase.instance
          .ref('active_sessions/$classId')
          .once();
      
      if (!sessionSnapshot.snapshot.exists) {
        expiredSessions.add(classId);
      }
    }
    
    for (final classId in expiredSessions) {
      _activeStudents.remove(classId);
      _sessionTimers[classId]?.cancel();
      _sessionTimers.remove(classId);
      _sessionJoinTimes.removeWhere((key, value) => key.startsWith('${classId}_'));
    }
  }
}
