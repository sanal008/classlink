class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' or 'teacher'
  final String enrollmentId;
  final String? department;
  final String? phone;
  final String? profileImage;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.enrollmentId,
    this.department,
    this.phone,
    this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'enrollmentId': enrollmentId,
      'department': department,
      'phone': phone,
      'profileImage': profileImage,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      role: map['role'],
      enrollmentId: map['enrollmentId'],
      department: map['department'],
      phone: map['phone'],
      profileImage: map['profileImage'],
    );
  }
}

class ClassSession {
  final String id;
  final String title;
  final String teacherId;
  final String teacherName;
  final String subject;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // 'scheduled', 'ongoing', 'ended'
  final String joinCode;

  ClassSession({
    required this.id,
    required this.title,
    required this.teacherId,
    required this.teacherName,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.joinCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subject': subject,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
      'joinCode': joinCode,
    };
  }

  static ClassSession fromMap(Map<String, dynamic> map) {
    // Parse start and end times with fallbacks
    DateTime startTime = DateTime.now();
    DateTime endTime = DateTime.now().add(const Duration(hours: 1));
    
    try {
      if (map['startTime'] != null) {
        startTime = DateTime.parse(map['startTime']);
      } else if (map['scheduledDateTime'] != null) {
        final ms = map['scheduledDateTime'];
        final scheduledMs = ms is int ? ms : int.tryParse(ms.toString());
        if (scheduledMs != null) {
          startTime = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
        }
      }
      
      if (map['endTime'] != null) {
        endTime = DateTime.parse(map['endTime']);
      } else if (map['scheduledDateTime'] != null) {
        final ms = map['scheduledDateTime'];
        final scheduledMs = ms is int ? ms : int.tryParse(ms.toString());
        if (scheduledMs != null) {
          startTime = DateTime.fromMillisecondsSinceEpoch(scheduledMs);
          final durationMins = map['duration'] ?? map['lengthMinutes'] ?? 2;
          final mins = durationMins is int ? durationMins : int.tryParse(durationMins.toString()) ?? 2;
          endTime = startTime.add(Duration(minutes: mins));
        }
      }
    } catch (e) {
      print('Error parsing ClassSession dates: $e');
    }
    
    return ClassSession(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Class',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      subject: map['subject'] ?? '',
      startTime: startTime,
      endTime: endTime,
      status: map['status'] ?? 'scheduled',
      joinCode: map['joinCode'] ?? map['join_code'] ?? '',
    );
  }
}

class Attendance {
  final String id;
  final String studentId;
  final String classId;
  final String? classTitle;
  final String? classDescription;
  final DateTime date;
  final String status; // 'present', 'absent'
  final Duration duration;
  final DateTime? joinTime;
  final DateTime? leaveTime;
  final String? teacherName;
  final String? teacherId;

  Attendance({
    required this.id,
    required this.studentId,
    required this.classId,
    this.classTitle,
    this.classDescription,
    required this.date,
    required this.status,
    required this.duration,
    this.joinTime,
    this.leaveTime,
    this.teacherName,
    this.teacherId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'classId': classId,
      'classTitle': classTitle,
      'classDescription': classDescription,
      'date': date.toIso8601String(),
      'status': status,
      'duration': duration.inMinutes,
      'joinTime': joinTime?.toIso8601String(),
      'leaveTime': leaveTime?.toIso8601String(),
      'teacherName': teacherName,
      'teacherId': teacherId,
    };
  }

  static Attendance fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      studentId: map['studentId'],
      classId: map['classId'],
      classTitle: map['classTitle'],
      classDescription: map['classDescription'],
      date: DateTime.parse(map['date']),
      status: map['status'],
      duration: Duration(minutes: map['duration'] ?? 0),
      joinTime: map['joinTime'] != null ? DateTime.parse(map['joinTime']) : null,
      leaveTime: map['leaveTime'] != null ? DateTime.parse(map['leaveTime']) : null,
      teacherName: map['teacherName'],
      teacherId: map['teacherId'],
    );
  }
}