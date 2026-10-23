import 'package:firebase_database/firebase_database.dart';
import 'models.dart';
import 'email_service.dart';

class FirebaseService {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Authentication Simulation
  Future<User?> authenticate(String enrollmentId, String password, String role) async {
    try {
      final snapshot = await _database.child('users').orderByChild('enrollmentId')
          .equalTo(enrollmentId).once();
      
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(
          (snapshot.snapshot.value as Map<dynamic, dynamic>).values.first
        );
        
        // Simple password validation (in real app, use proper auth)
        if (data['password'] == password && data['role'] == role) {
          return User.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }

  // Get user by ID
  Future<User?> getUser(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId').once();
      if (snapshot.snapshot.value != null) {
        return User.fromMap(Map<String, dynamic>.from(
          snapshot.snapshot.value as Map<dynamic, dynamic>
        ));
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Get user data as Map for email service
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId').once();
      if (snapshot.snapshot.value != null) {
        return Map<String, dynamic>.from(
          snapshot.snapshot.value as Map<dynamic, dynamic>
        );
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Create new class
  Future<void> createClass(ClassSession classSession) async {
    await _database.child('classes/${classSession.id}').set(
      classSession.toMap()
    );
  }

  // Get all classes for teacher
  Stream<List<ClassSession>> getTeacherClasses(String teacherId) {
    return _database.child('classes')
      .orderByChild('teacherId')
      .equalTo(teacherId)
      .onValue
      .map((event) {
        if (event.snapshot.value != null) {
          final Map<dynamic, dynamic> classes = 
            event.snapshot.value as Map<dynamic, dynamic>;
          return classes.values
            .map((c) => ClassSession.fromMap(
              Map<String, dynamic>.from(c as Map<dynamic, dynamic>)
            ))
            .toList();
        }
        return [];
      });
  }

  // Get available classes for student
  Stream<List<ClassSession>> getAvailableClasses() {
    return _database.child('classes')
      .orderByChild('status')
      .equalTo('scheduled')
      .onValue
      .map((event) {
        if (event.snapshot.value != null) {
          final Map<dynamic, dynamic> classes = 
            event.snapshot.value as Map<dynamic, dynamic>;
          return classes.values
            .map((c) => ClassSession.fromMap(
              Map<String, dynamic>.from(c as Map<dynamic, dynamic>)
            ))
            .toList();
        }
        return [];
      });
  }

  // Mark attendance
  Future<void> markAttendance(Attendance attendance) async {
    await _database.child('attendance/${attendance.id}').set(
      attendance.toMap()
    );
  }

  // Get student attendance
  Stream<List<Attendance>> getStudentAttendance(String studentId) {
    return _database.child('attendance')
      .orderByChild('studentId')
      .equalTo(studentId)
      .onValue
      .map((event) {
        if (event.snapshot.value != null) {
          final Map<dynamic, dynamic> attendance = 
            event.snapshot.value as Map<dynamic, dynamic>;
          return attendance.values
            .map((a) => Attendance.fromMap(
              Map<String, dynamic>.from(a as Map<dynamic, dynamic>)
            ))
            .toList();
        }
        return [];
      });
  }

  // Get attendance analytics for teacher
  Future<Map<String, dynamic>> getAttendanceAnalytics(String teacherId) async {
    final snapshot = await _database.child('attendance').once();
    
    // Simplified analytics
    return {
      'totalClasses': 15,
      'averageAttendance': 85.5,
      'topStudents': ['John Doe', 'Jane Smith', 'Bob Johnson'],
      'weakStudents': ['Alice Brown', 'Charlie Wilson'],
    };
  }

  // Get detailed session reports for teacher
  Future<List<Map<String, dynamic>>> getSessionReports(String teacherId, String teacherName) async {
    List<Map<String, dynamic>> sessionReports = [];
    
    print('DEBUG: getSessionReports called for teacherId: $teacherId, teacherName: $teacherName');
    
    try {
      // 1. Get attendance records for this teacher (PRIMARY SOURCE)
      final attendanceSnapshot = await _database.child('attendance').once();
      
      if (attendanceSnapshot.snapshot.value != null) {
        final attendance = Map<String, dynamic>.from(attendanceSnapshot.snapshot.value as Map);
        print('DEBUG: Total attendance records: ${attendance.length}');
        
        // Group attendance by class session
        Map<String, List<Map<String, dynamic>>> sessionsMap = {};
        
        attendance.forEach((key, value) {
          final attendanceData = Map<String, dynamic>.from(value as Map);
          final attendanceClassId = attendanceData['classId']?.toString() ?? '';
          final attendanceStudentId = attendanceData['studentId']?.toString() ?? '';
          final date = attendanceData['date']?.toString() ?? '';
          
          print('DEBUG: Processing attendance - ClassId: "$attendanceClassId", StudentId: "$attendanceStudentId"');
          
          // Get class details to check teacher
          if (attendanceClassId.isNotEmpty) {
            _getClassSessionById(attendanceClassId).then((classSession) {
              if (classSession != null) {
                final classTeacherId = classSession.teacherId ?? '';
                final classTeacherName = classSession.teacherName ?? '';
                
                print('DEBUG: Class TeacherId: "$classTeacherId", TeacherName: "$classTeacherName"');
                
                // Filter by teacher (both ID and name for compatibility)
                bool teacherMatches = false;
                if (classTeacherId.isNotEmpty && classTeacherId == teacherId) {
                  teacherMatches = true;
                  print('DEBUG: Matched by teacherId');
                } else if (classTeacherName.isNotEmpty && classTeacherName == teacherName) {
                  teacherMatches = true;
                  print('DEBUG: Matched by teacherName');
                }
                
                if (teacherMatches) {
                  final sessionKey = '$attendanceClassId-$date';
                  
                  if (!sessionsMap.containsKey(sessionKey)) {
                    sessionsMap[sessionKey] = [];
                  }
                  sessionsMap[sessionKey]!.add(attendanceData);
                  print('DEBUG: Added attendance to session: $sessionKey');
                }
              }
            });
          }
        });
        
        // Wait a bit for async operations to complete
        await Future.delayed(Duration(milliseconds: 500));
        
        print('DEBUG: Total matched sessions: ${sessionsMap.length}');
        
        // Convert grouped data to session reports
        for (final sessionKey in sessionsMap.keys) {
          final sessionAttendances = sessionsMap[sessionKey]!;
          if (sessionAttendances.isNotEmpty) {
            final firstAttendance = sessionAttendances.first;
            final classId = firstAttendance['classId']?.toString() ?? '';
            final date = firstAttendance['date']?.toString() ?? '';
            
            // Get session details
            final classSession = await _getClassSessionById(classId);
            
            // Calculate session statistics
            int presentCount = 0;
            int absentCount = 0;
            List<Map<String, dynamic>> studentDetails = [];
            
            for (final attendance in sessionAttendances) {
              final studentId = attendance['studentId']?.toString() ?? '';
              final status = attendance['status']?.toString() ?? 'absent';
              final duration = attendance['duration']?.toString() ?? '0';
              final joinTime = attendance['joinTime']?.toString() ?? '';
              final leaveTime = attendance['leaveTime']?.toString() ?? '';
              
              // Get student name from users node
              String studentName = 'Unknown Student';
              try {
                final userSnapshot = await _database.child('users/$studentId').once();
                if (userSnapshot.snapshot.value != null) {
                  final userData = Map<String, dynamic>.from(userSnapshot.snapshot.value as Map);
                  studentName = userData['name']?.toString() ?? 'Unknown Student';
                }
              } catch (e) {
                print('Error getting student name: $e');
              }
              
              if (status == 'present') {
                presentCount++;
              } else {
                absentCount++;
              }
              
              studentDetails.add({
                'studentId': studentId,
                'studentName': studentName,
                'status': status,
                'duration': duration,
                'joinTime': joinTime,
                'leaveTime': leaveTime,
              });
            }
            
            sessionReports.add({
              'sessionId': sessionKey,
              'classId': classId,
              'className': classSession?.title ?? classId,
              'subject': classSession?.subject ?? 'General',
              'date': date,
              'teacherName': classSession?.teacherName ?? teacherName,
              'totalStudents': sessionAttendances.length,
              'presentCount': presentCount,
              'absentCount': absentCount,
              'attendanceRate': sessionAttendances.length > 0 
                  ? ((presentCount / sessionAttendances.length) * 100).toStringAsFixed(1) + '%'
                  : '0%',
              'studentDetails': studentDetails,
              'isAttendance': true,
            });
          }
        }
      }
      
      // 2. Get scheduled classes for this teacher (SECONDARY SOURCE)
      final scheduledClassesSnapshot = await _database.child('scheduled_classes').once();
      
      if (scheduledClassesSnapshot.snapshot.value != null) {
        final scheduledClasses = Map<String, dynamic>.from(scheduledClassesSnapshot.snapshot.value as Map);
        print('DEBUG: Total scheduled classes: ${scheduledClasses.length}');
        
        scheduledClasses.forEach((classId, classData) {
          final classSession = Map<String, dynamic>.from(classData as Map);
          final scheduledTeacherId = classSession['teacherId']?.toString() ?? '';
          final scheduledTeacherName = classSession['teacherName']?.toString() ?? '';
          
          print('DEBUG: Processing scheduled class - TeacherId: "$scheduledTeacherId", TeacherName: "$scheduledTeacherName"');
          
          // Filter by teacher (both ID and name for compatibility)
          bool teacherMatches = false;
          if (scheduledTeacherId.isNotEmpty && scheduledTeacherId == teacherId) {
            teacherMatches = true;
            print('DEBUG: Matched scheduled class by teacherId');
          } else if (scheduledTeacherName.isNotEmpty && scheduledTeacherName == teacherName) {
            teacherMatches = true;
            print('DEBUG: Matched scheduled class by teacherName');
          }
          
          if (teacherMatches) {
            final title = classSession['title']?.toString() ?? 'Untitled Class';
            final subject = classSession['description']?.toString() ?? classSession['subject']?.toString() ?? 'General';
            final status = classSession['status']?.toString() ?? 'scheduled';
            final scheduledDateTime = classSession['scheduledDateTime']?.toString();
            
            print('DEBUG: Adding scheduled class: $title');
            
            sessionReports.add({
              'sessionId': classId,
              'classId': classId,
              'className': title,
              'subject': subject,
              'date': scheduledDateTime != null ? DateTime.fromMillisecondsSinceEpoch(int.parse(scheduledDateTime)).toIso8601String() : DateTime.now().toIso8601String(),
              'teacherName': scheduledTeacherName.isNotEmpty ? scheduledTeacherName : teacherName,
              'totalStudents': 0,
              'presentCount': 0,
              'absentCount': 0,
              'attendanceRate': '0%',
              'studentDetails': [],
              'status': status,
              'isScheduled': true,
            });
          }
        });
      }
      
      // 3. Get active sessions for this teacher
      final activeSessionsSnapshot = await _database.child('active_sessions').once();
      
      if (activeSessionsSnapshot.snapshot.value != null) {
        final activeSessions = Map<String, dynamic>.from(activeSessionsSnapshot.snapshot.value as Map);
        print('DEBUG: Processing active sessions...');
        
        for (final sessionId in activeSessions.keys) {
          final sessionData = activeSessions[sessionId];
          final session = Map<String, dynamic>.from(sessionData as Map);
          final sessionTeacherId = session['teacherId']?.toString() ?? '';
          final sessionTeacherName = session['teacherName']?.toString() ?? '';
          
          print('DEBUG: Processing active session - TeacherId: "$sessionTeacherId", TeacherName: "$sessionTeacherName"');
          
          // Filter by teacher (both ID and name for compatibility)
          bool teacherMatches = false;
          if (sessionTeacherId.isNotEmpty && sessionTeacherId == teacherId) {
            teacherMatches = true;
            print('DEBUG: Matched active session by teacherId');
          } else if (sessionTeacherName.isNotEmpty && sessionTeacherName == teacherName) {
            teacherMatches = true;
            print('DEBUG: Matched active session by teacherName');
          }
          
          if (teacherMatches) {
            final participants = session['participants'] as Map<dynamic, dynamic>? ?? {};
            
            // Get class details from scheduledClassId if available
            String className = session['title']?.toString() ?? 'Active Session';
            String subject = session['subject']?.toString() ?? 'Live Class';
            
            final scheduledClassId = session['scheduledClassId']?.toString();
            if (scheduledClassId != null && scheduledClassId.isNotEmpty) {
              try {
                final classSession = await _getClassSessionById(scheduledClassId);
                if (classSession != null) {
                  className = classSession.title ?? className;
                  subject = classSession.subject ?? subject;
                }
              } catch (e) {
                print('Error getting class session details: $e');
              }
            }
            
            int activeCount = 0;
            List<Map<String, dynamic>> activeStudents = [];
            
            for (final studentId in participants.keys) {
              final participantData = participants[studentId];
              final participant = Map<String, dynamic>.from(participantData as Map);
              
              // Get student name from users node
              String studentName = 'Unknown Student';
              try {
                final userSnapshot = await _database.child('users/$studentId').once();
                if (userSnapshot.snapshot.value != null) {
                  final userData = Map<String, dynamic>.from(userSnapshot.snapshot.value as Map);
                  studentName = userData['name']?.toString() ?? 'Unknown Student';
                }
              } catch (e) {
                print('Error getting student name: $e');
              }
              
              final status = participant['status']?.toString() ?? 'unknown';
              final joinTime = participant['joinTime']?.toString() ?? '';
              
              if (status == 'active') {
                activeCount++;
              }
              
              activeStudents.add({
                'studentId': studentId.toString(),
                'studentName': studentName,
                'status': status,
                'joinTime': joinTime,
                'leaveTime': participant['leaveTime']?.toString() ?? '',
              });
            }
            
            if (participants.isNotEmpty) {
              print('DEBUG: Adding active session: $className with ${participants.length} participants');
              
              sessionReports.add({
                'sessionId': sessionId,
                'classId': sessionId,
                'className': className,
                'subject': subject,
                'date': DateTime.now().toIso8601String(),
                'teacherName': sessionTeacherName.isNotEmpty ? sessionTeacherName : teacherName,
                'totalStudents': participants.length,
                'presentCount': activeCount,
                'absentCount': participants.length - activeCount,
                'attendanceRate': participants.length > 0 
                    ? ((activeCount / participants.length) * 100).toStringAsFixed(1) + '%'
                    : '0%',
                'studentDetails': activeStudents,
                'isActive': true,
              });
            }
          }
        }
      }
      
      // Sort by date (newest first)
      sessionReports.sort((a, b) {
        final dateA = a['isActive'] == true ? DateTime.now() : DateTime.parse(a['date']);
        final dateB = b['isActive'] == true ? DateTime.now() : DateTime.parse(b['date']);
        return dateB.compareTo(dateA);
      });
      
      print('DEBUG: Final sessionReports count: ${sessionReports.length}');
      print('DEBUG: SessionReports data: $sessionReports');
      
    } catch (e) {
      print('Error getting session reports: $e');
    }
    
    return sessionReports;
  }
  
  // Helper method to get class session by ID
  Future<ClassSession?> _getClassSessionById(String classId) async {
    try {
      // Try scheduled_classes first
      final snapshot = await _database.child('scheduled_classes/$classId').once();
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(
          snapshot.snapshot.value as Map<dynamic, dynamic>
        );
        
        DateTime? startTime, endTime;
        if (data['scheduledDateTime'] != null) {
          final ms = data['scheduledDateTime'];
          final scheduledMs = ms is int ? ms : int.tryParse(ms.toString());
          if (scheduledMs != null) {
            startTime = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
            final durationMins = data['duration'] ?? data['lengthMinutes'] ?? 2;
            final mins = durationMins is int ? durationMins : int.tryParse(durationMins.toString()) ?? 2;
            endTime = startTime.add(Duration(minutes: mins));
          }
        }
        
        return ClassSession(
          id: data['id'] ?? classId,
          title: data['title'] ?? 'Untitled Class',
          teacherId: data['teacherId'] ?? '',
          teacherName: data['teacherName'] ?? '',
          subject: data['description'] ?? data['subject'] ?? '',
          startTime: startTime ?? DateTime.now(),
          endTime: endTime ?? DateTime.now(),
          status: data['status'] ?? 'scheduled',
          joinCode: data['joinCode'] ?? '',
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting class session by ID: $e');
      return null;
    }
  }

  // Get all students
  Stream<List<User>> getAllStudents() {
    return _database.child('users')
      .orderByChild('role')
      .equalTo('student')
      .onValue
      .map((event) {
        if (event.snapshot.value != null) {
          final Map<dynamic, dynamic> users = 
            event.snapshot.value as Map<dynamic, dynamic>;
          return users.values
            .map((u) => User.fromMap(
              Map<String, dynamic>.from(u as Map<dynamic, dynamic>)
            ))
            .toList();
        }
        return [];
      });
    }

    // Register a new user (teacher or student)
    Future<bool> registerUser(User user, String password) async {
      try {
        final newRef = _database.child('users').push();
        final id = newRef.key ?? user.id;
        final data = user.toMap();
        data['password'] = password;
        data['id'] = id;
        await newRef.set(data);
        return true;
      } catch (e) {
        print('Error registering user: $e');
        return false;
      }
    }

    // Save scheduled class to Firebase
    Future<bool> saveScheduledClass(ClassSession classSession) async {
      try {
        await _database.child('scheduled_classes/${classSession.id}').set(
          classSession.toMap()
        );
        return true;
      } catch (e) {
        print('Error saving scheduled class: $e');
        return false;
      }
    }

    // Get all upcoming scheduled classes for a teacher
    Stream<List<ClassSession>> getTeacherScheduledClasses(String teacherId) {
      return _database.child('scheduled_classes')
        .orderByChild('teacherId')
        .equalTo(teacherId)
        .onValue
        .map((event) {
          if (event.snapshot.value != null) {
            final Map<dynamic, dynamic> classes = 
              event.snapshot.value as Map<dynamic, dynamic>;
            final classList = classes.values
              .map((c) => ClassSession.fromMap(
                Map<String, dynamic>.from(c as Map<dynamic, dynamic>)
              ))
              .toList();
            // Filter for future classes only
            classList.sort((a, b) => a.startTime.compareTo(b.startTime));
            return classList;
          }
          return [];
        });
    }

    // Get all upcoming scheduled classes for students
    Stream<List<ClassSession>> getUpcomingScheduledClasses() {
      return _database.child('scheduled_classes').onValue.map((event) {
        if (event.snapshot.value != null) {
          final Map<dynamic, dynamic> classes = event.snapshot.value as Map<dynamic, dynamic>;
          final now = DateTime.now();
          final classList = <ClassSession>[];

          classes.forEach((key, value) {
            try {
              final map = Map<String, dynamic>.from(value as Map<dynamic, dynamic>);

              // Normalize fields with fallbacks for legacy data
              final id = map['id'] ?? key.toString();
              final title = map['title'] ?? 'Untitled Class';
              final teacherId = map['teacherId'] ?? '';
              final teacherName = map['teacherName'] ?? '';
              final subject = map['subject'] ?? '';
              final status = map['status'] ?? 'scheduled';
              final joinCode = map['joinCode'] ?? map['join_code'] ?? id;

              DateTime? startTime;
              DateTime? endTime;

              if (map['startTime'] != null && map['endTime'] != null) {
                startTime = DateTime.parse(map['startTime']);
                endTime = DateTime.parse(map['endTime']);
              } else if (map['scheduledDateTime'] != null) {
                final ms = map['scheduledDateTime'];
                final scheduledMs = ms is int ? ms : int.tryParse(ms.toString());
                if (scheduledMs == null) {
                  print('Skipping scheduled class $key: invalid scheduledDateTime');
                  return; // skip this entry
                }
                startTime = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
                final durationMins = map['duration'] ?? map['lengthMinutes'] ?? 2;
                final mins = durationMins is int ? durationMins : int.tryParse(durationMins.toString()) ?? 2;
                endTime = startTime.add(Duration(minutes: mins));
              } else {
                print('Skipping scheduled class $key due to missing time fields');
                return; // skip this entry
              }

              final cs = ClassSession(
                id: id,
                title: title,
                teacherId: teacherId,
                teacherName: teacherName,
                subject: subject,
                startTime: startTime!,
                endTime: endTime!,
                status: status,
                joinCode: joinCode,
              );

              // only include future or ongoing classes
              if (cs.endTime.isAfter(now)) {
                classList.add(cs);
              }
            } catch (e) {
              print('Error parsing scheduled class $key: $e');
            }
          });

          classList.sort((a, b) => a.startTime.compareTo(b.startTime));
          return classList;
        }
        return [];
      });
    }

    // Query a scheduled class by its join code
    Future<ClassSession?> getScheduledClassByJoinCode(String code) async {
      try {
        final snapshot = await _database.child('scheduled_classes')
          .orderByChild('joinCode')
          .equalTo(code)
          .once();

        if (snapshot.snapshot.value != null) {
          final Map<dynamic, dynamic> classes = snapshot.snapshot.value as Map<dynamic, dynamic>;
          final first = classes.values.first as Map<dynamic, dynamic>;
          return ClassSession.fromMap(Map<String, dynamic>.from(first));
        }
        return null;
      } catch (e) {
        print('Error querying by join code: $e');
        return null;
      }
    }

    // Get class session by ID
    Future<ClassSession?> getClassSession(String classId) async {
      try {
        // Try multiple possible paths where class sessions might be stored
        ClassSession? session;
        
        // Try 1: classes path
        final snapshot1 = await _database.child('classes/$classId').once();
        if (snapshot1.snapshot.value != null) {
          final data = Map<String, dynamic>.from(
            snapshot1.snapshot.value as Map<dynamic, dynamic>
          );
          session = ClassSession(
            id: data['id'] ?? classId,
            title: data['title'] ?? 'Untitled Class',
            teacherId: data['teacherId'] ?? '',
            teacherName: data['teacherName'] ?? '',
            subject: data['subject'] ?? data['description'] ?? '',
            startTime: data['startTime'] != null ? DateTime.parse(data['startTime']) : DateTime.now(),
            endTime: data['endTime'] != null ? DateTime.parse(data['endTime']) : DateTime.now(),
            status: data['status'] ?? 'scheduled',
            joinCode: data['joinCode'] ?? '',
          );
        }
        
        // Try 2: scheduled_classes path (for ongoing/scheduled classes)
        if (session == null) {
          final snapshot2 = await _database.child('scheduled_classes/$classId').once();
          if (snapshot2.snapshot.value != null) {
            final data = Map<String, dynamic>.from(
              snapshot2.snapshot.value as Map<dynamic, dynamic>
            );
            // Handle scheduledDateTime conversion
            DateTime? startTime, endTime;
            if (data['scheduledDateTime'] != null) {
              final ms = data['scheduledDateTime'];
              final scheduledMs = ms is int ? ms : int.tryParse(ms.toString());
              if (scheduledMs != null) {
                startTime = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
                final durationMins = data['duration'] ?? data['lengthMinutes'] ?? 2;
                final mins = durationMins is int ? durationMins : int.tryParse(durationMins.toString()) ?? 2;
                endTime = startTime.add(Duration(minutes: mins));
              }
            }
            
            session = ClassSession(
              id: data['id'] ?? classId,
              title: data['title'] ?? 'Untitled Class',
              teacherId: data['teacherId'] ?? '',
              teacherName: data['teacherName'] ?? '',
              subject: data['subject'] ?? data['description'] ?? '',
              startTime: startTime ?? DateTime.now(),
              endTime: endTime ?? DateTime.now(),
              status: data['status'] ?? 'scheduled',
              joinCode: data['joinCode'] ?? data['join_code'] ?? '',
            );
          }
        }
        
        // Try 3: active_sessions path
        if (session == null) {
          final snapshot3 = await _database.child('active_sessions/$classId').once();
          if (snapshot3.snapshot.value != null) {
            final data = Map<String, dynamic>.from(
              snapshot3.snapshot.value as Map<dynamic, dynamic>
            );
            session = ClassSession(
              id: data['id'] ?? classId,
              title: data['title'] ?? 'Untitled Class',
              teacherId: data['teacherId'] ?? '',
              teacherName: data['teacherName'] ?? '',
              subject: data['subject'] ?? data['description'] ?? '',
              startTime: data['startTime'] != null ? DateTime.parse(data['startTime']) : DateTime.now(),
              endTime: data['endTime'] != null ? DateTime.parse(data['endTime']) : DateTime.now(),
              status: data['status'] ?? 'scheduled',
              joinCode: data['joinCode'] ?? '',
            );
          }
        }
        
        return session;
      } catch (e) {
        print('Error getting class session: $e');
        return null;
      }
    }

    // Delete scheduled class
    Future<bool> deleteScheduledClass(String classId) async {
      try {
        await _database.child('scheduled_classes/$classId').remove();
        return true;
      } catch (e) {
        print('Error deleting scheduled class: $e');
        return false;
      }
    }

    // Enqueue an email request to be sent by a backend worker/service
    Future<void> sendEmailRequest({
      required String to,
      required String subject,
      required String body,
      String? studentId,
    }) async {
      try {
        final ref = _database.child('email_requests').push();
        await ref.set({
          'to': to,
          'subject': subject,
          'body': body,
          'studentId': studentId,
          'timestamp': DateTime.now().toIso8601String(),
          'status': 'pending',
        });
      } catch (e) {
        print('Error enqueueing email request: $e');
      }
    }

    // Find user by email for password reset
    Future<User?> findUserByEmail(String email) async {
      try {
        final snapshot = await _database.child('users')
            .orderByChild('email')
            .equalTo(email)
            .once();
        
        if (snapshot.snapshot.value != null) {
          final Map<dynamic, dynamic> users = 
              snapshot.snapshot.value as Map<dynamic, dynamic>;
          final userData = users.values.first as Map<dynamic, dynamic>;
          return User.fromMap(Map<String, dynamic>.from(userData));
        }
        return null;
      } catch (e) {
        print('Error finding user by email: $e');
        return null;
      }
    }

    // Send password reset email
    Future<bool> sendPasswordResetEmail(String email) async {
      try {
        final user = await findUserByEmail(email);
        if (user == null) {
          return false; // User not found
        }

        // Generate a simple reset token (in production, use proper token generation)
        final resetToken = _generateResetToken();
        final resetCode = resetToken.substring(0, 6).toUpperCase(); // 6-digit code
        
        // Store reset token with expiration (24 hours)
        await _database.child('password_resets/$resetToken').set({
          'userId': user.id,
          'email': email,
          'createdAt': DateTime.now().toIso8601String(),
          'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          'used': false,
        });

        // Send reset email
        final resetSubject = 'ClassLink+ Password Reset';
        final resetBody = '''
Hello ${user.name},

You requested a password reset for your ClassLink+ account.

Your password reset code is: $resetCode

This code will expire in 24 hours.

If you didn't request this password reset, please ignore this email.

Best regards,
ClassLink+ Team
        ''';

        // Send reset email directly using EmailService
        await EmailService.sendEmail(
          to: email,
          subject: resetSubject,
          body: resetBody.trim(),
        );

        return true;
      } catch (e) {
        print('Error sending password reset email: $e');
        return false;
      }
    }

    // Verify reset token and update password
    Future<bool> resetPassword(String resetCode, String newPassword) async {
      try {
        // Find the reset token by matching the 6-digit code
        final snapshot = await _database.child('password_resets').once();
        
        if (snapshot.snapshot.value != null) {
          final Map<dynamic, dynamic> resets = 
              snapshot.snapshot.value as Map<dynamic, dynamic>;
          
          String? validToken;
          String? userId;
          
          // Find matching reset token
          for (var entry in resets.entries) {
            final token = entry.key.toString();
            final tokenData = entry.value as Map<dynamic, dynamic>;
            
            if (token.substring(0, 6).toUpperCase() == resetCode.toUpperCase() &&
                tokenData['used'] == false) {
              final expiresAt = DateTime.parse(tokenData['expiresAt']);
              if (expiresAt.isAfter(DateTime.now())) {
                validToken = token;
                userId = tokenData['userId'];
                break;
              }
            }
          }
          
          if (validToken != null && userId != null) {
            // Update user password
            await _database.child('users/$userId/password').set(newPassword);
            
            // Mark reset token as used
            await _database.child('password_resets/$validToken/used').set(true);
            
            return true;
          }
        }
        
        return false;
      } catch (e) {
        print('Error resetting password: $e');
        return false;
      }
    }

    // Generate simple reset token (numeric only)
    String _generateResetToken() {
      const chars = '0123456789';
      final random = DateTime.now().millisecondsSinceEpoch;
      final buffer = StringBuffer();
      
      for (int i = 0; i < 32; i++) {
        final index = (random + i) % chars.length;
        buffer.write(chars[index]);
      }
      
      return buffer.toString();
    }
  }