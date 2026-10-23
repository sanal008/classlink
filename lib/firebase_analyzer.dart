import 'package:firebase_database/firebase_database.dart';

class FirebaseAnalyzer {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> analyzeCompleteDatabase() async {
    print('\n🔍 FIREBASE REALTIME DATABASE COMPLETE ANALYSIS 🔍');
    print('=' * 60);
    
    try {
      // Get all root nodes
      final rootSnapshot = await _database.once();
      
      if (rootSnapshot.snapshot.value != null) {
        final rootData = Map<String, dynamic>.from(
          rootSnapshot.snapshot.value as Map<dynamic, dynamic>
        );
        
        print('\n📁 ROOT NODES FOUND: ${rootData.keys.length}');
        print('Root nodes: ${rootData.keys.toList()}');
        print('=' * 60);
        
        // Analyze each root node
        for (final nodeName in rootData.keys) {
          await analyzeNode(nodeName.toString(), rootData[nodeName]);
        }
        
      } else {
        print('❌ No data found in Firebase root');
      }
      
      // Specific node analysis
      print('\n🎯 SPECIFIC NODE ANALYSIS');
      print('=' * 60);
      await analyzeSpecificNodes();
      
    } catch (e) {
      print('❌ Error analyzing database: $e');
    }
    
    print('\n🏁 ANALYSIS COMPLETE');
  }

  Future<void> analyzeNode(String nodeName, dynamic nodeData) async {
    print('\n📂 ANALYZING NODE: $nodeName');
    print('-' * 40);
    
    if (nodeData is Map) {
      final data = Map<String, dynamic>.from(nodeData as Map<dynamic, dynamic>);
      print('Type: Map/Object');
      print('Child count: ${data.keys.length}');
      
      if (data.keys.length <= 10) {
        print('Children: ${data.keys.toList()}');
        
        // Show sample data for each child
        for (final childKey in data.keys.take(3)) {
          final childData = data[childKey];
          print('  └─ $childKey: ${getDataSummary(childData)}');
          
          // If this is a small object, show its structure
          if (childData is Map && (childData as Map).length <= 5) {
            (childData as Map).forEach((key, value) {
              print('     └─ $key: ${getDataSummary(value)}');
            });
          }
        }
      } else {
        print('Children: ${data.keys.take(10).toList()}... (${data.keys.length - 10} more)');
      }
      
      // Look for common patterns
      await lookForPatterns(nodeName, data);
      
    } else if (nodeData is List) {
      print('Type: Array/List');
      print('Length: ${nodeData.length}');
      print('Sample items: ${nodeData.take(3).toList()}');
    } else {
      print('Type: ${nodeData.runtimeType}');
      print('Value: $nodeData');
    }
  }

  Future<void> lookForPatterns(String nodeName, Map<String, dynamic> data) async {
    print('\n🔍 Pattern Analysis for $nodeName:');
    
    // Check for user-like data
    if (data.isNotEmpty) {
      final firstItem = data.values.first;
      if (firstItem is Map) {
        final firstMap = Map<String, dynamic>.from(firstItem as Map<dynamic, dynamic>);
        final keys = firstMap.keys.toList();
        
        print('  Sample structure keys: $keys');
        
        // Identify common patterns
        if (keys.contains('role') && (keys.contains('email') || keys.contains('name'))) {
          print('  🎯 Likely USERS node (contains role, email/name)');
        }
        
        if (keys.contains('teacherId') || keys.contains('teacherName')) {
          print('  🎯 Likely CLASS/SESSION node (contains teacher info)');
        }
        
        if (keys.contains('studentId') || keys.contains('status')) {
          print('  🎯 Likely ATTENDANCE node (contains student/status)');
        }
        
        if (keys.contains('scheduledDateTime') || keys.contains('startTime')) {
          print('  🎯 Likely SCHEDULED CLASSES node (contains time info)');
        }
        
        if (keys.contains('participants') || keys.contains('status') && keys.contains('teacherName')) {
          print('  🎯 Likely ACTIVE SESSIONS node (contains participants/status)');
        }
        
        // Count items by common identifiers
        if (keys.contains('teacherId')) {
          final teacherCounts = <String, int>{};
          for (final item in data.values.take(20)) {
            if (item is Map) {
              final teacherId = item['teacherId']?.toString() ?? 'unknown';
              teacherCounts[teacherId] = (teacherCounts[teacherId] ?? 0) + 1;
            }
          }
          if (teacherCounts.isNotEmpty) {
            print('  👥 Teacher distribution (sample): $teacherCounts');
          }
        }
      }
    }
  }

  Future<void> analyzeSpecificNodes() async {
    // Check specific important nodes
    final importantNodes = [
      'users', 'attendance', 'active_sessions', 'scheduled_classes', 
      'classes', 'students', 'teachers'
    ];
    
    for (final nodeName in importantNodes) {
      try {
        final snapshot = await _database.child(nodeName).once();
        if (snapshot.snapshot.value != null) {
          print('\n✅ Node "$nodeName" EXISTS');
          await analyzeNode(nodeName, snapshot.snapshot.value);
        } else {
          print('\n❌ Node "$nodeName" NOT FOUND or EMPTY');
        }
      } catch (e) {
        print('\n❌ Error accessing node "$nodeName": $e');
      }
    }
  }

  String getDataSummary(dynamic data) {
    if (data == null) return 'null';
    
    if (data is String) {
      if (data.length > 50) return '"${data.substring(0, 47)}..."';
      return '"$data"';
    }
    
    if (data is Map) {
      final keys = (data as Map).keys.toList();
      return 'Map(${keys.length} keys: ${keys.take(3).toList()}...)';
    }
    
    if (data is List) {
      return 'List(${data.length} items)';
    }
    
    return '${data.runtimeType}: $data';
  }
}

// Usage function to run the analysis
Future<void> runFirebaseAnalysis() async {
  final analyzer = FirebaseAnalyzer();
  await analyzer.analyzeCompleteDatabase();
}
