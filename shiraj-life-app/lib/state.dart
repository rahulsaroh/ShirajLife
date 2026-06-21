import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class GymAppState extends ChangeNotifier {
  // Singleton pattern for easy global access
  static final GymAppState instance = GymAppState._internal();
  
  GymAppState._internal() {
    _initializeData();
    // Load offline cached routine, then fetch updates from Firestore in the background
    loadCachedRoutine().then((_) {
      syncActiveRoutinesFromFirestore();
    });
  }

  // Active sync scope fields
  String? _currentGymId;
  String? _currentUserRole;
  String? _currentLinkedId;

  // Stream Subscriptions
  final List<StreamSubscription> _subscriptions = [];

  // Cached active training routine of linked client
  Map<String, dynamic>? activeClientRoutine;

  Future<void> loadCachedRoutine() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routineJson = prefs.getString('cachedRoutine');
      if (routineJson != null) {
        activeClientRoutine = jsonDecode(routineJson);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached routine: $e');
    }
  }

  Future<void> syncActiveRoutinesFromFirestore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientId = prefs.getString('linkedClientId');
      if (clientId == null || clientId.isEmpty) {
        debugPrint('Sync: No linked client account found.');
        return;
      }

      debugPrint('Sync: Fetching routine for clientId $clientId from Firestore...');
      final query = await FirebaseFirestore.instance
          .collection('routines')
          .where('clientId', isEqualTo: clientId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final routineDoc = query.docs.first;
        final routineData = routineDoc.data();
        activeClientRoutine = routineData;
        await prefs.setString('cachedRoutine', jsonEncode(routineData));
        notifyListeners();
        debugPrint('Sync: Successfully synced active client routine from Firestore.');
      } else {
        debugPrint('Sync: No active routine found on Firestore for client.');
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  // Lists populated via Firestore
  late List<Branch> branches;
  late List<Trainer> trainers;
  late List<Student> students;
  late List<CoachingAdvice> adviceHistory;
  late List<Equipment> equipment;
  
  // Local default mock tables (for demo/fallback use)
  late List<dynamic> rawLeads;
  late List<dynamic> proShopInventory;
  late List<dynamic> checklists;
  late List<dynamic> trainerAvailability;
  late List<dynamic> zones;
  late List<dynamic> workoutLogs;
  late List<dynamic> announcements;
  late List<dynamic> socialSchedule;

  void _initializeData() {
    branches = [
      Branch(id: "downtown", name: "Downtown Fitness Center", location: "New York, USA"),
      Branch(id: "west-end", name: "West End Strength Gym", location: "London, UK"),
      Branch(id: "east-side", name: "East Side HIIT Club", location: "Tokyo, Japan"),
    ];

    trainers = [
      Trainer(id: "none", name: "No Trainer", clientsCount: 0, yearsExperience: 0, tags: ["N/A"], branchId: "all"),
      Trainer(id: "king", name: "King Zarips", clientsCount: 3, yearsExperience: 2, tags: ["Motivation", "Mentality"], branchId: "downtown"),
      Trainer(id: "lerry", name: "Lerry Rops", clientsCount: 2, yearsExperience: 1, tags: ["Weight", "Power"], branchId: "west-end"),
      Trainer(id: "sarah", name: "Sarah Connor", clientsCount: 0, yearsExperience: 4, tags: ["Kettlebell", "HIIT"], branchId: "east-side"),
    ];

    rawLeads = [];
    proShopInventory = [];
    checklists = [];
    trainerAvailability = [];
    zones = [];
    workoutLogs = [];
    announcements = [];
    socialSchedule = [];
    
    students = [
      Student(id: "bessie", name: "Bessie Cooper", email: "bessiecop@hotmail.com", expiredDate: "08/05/2026", age: 24, status: "Active", tel: "277-555-0119", lastVisited: "Yesterday", trainerId: "king", isCheckedIn: false, branchId: "downtown", streakCount: 3, benchPressPr: 70, squatPr: 95, bodyWeight: 62, workoutCredits: 12, billingFailed: false, gracePeriodDays: 3, totalWorkouts: 99, referralsCount: 2, staffNotes: "Prefers barbell squats; slight shoulder stiffness."),
      Student(id: "eleanor", name: "Eleanor Pena", email: "eleanor.pena@icloud.com", expiredDate: "12/07/2026", age: 24, status: "In Active", tel: "290-902-4829", lastVisited: "Today", trainerId: "lerry", isCheckedIn: true, branchId: "west-end", streakCount: 1, benchPressPr: 55, squatPr: 80, bodyWeight: 58, workoutCredits: 5, billingFailed: true, gracePeriodDays: 0, totalWorkouts: 45, referralsCount: 0, staffNotes: "Recovering from ankle strain. Avoid heavy dynamic jumping."),
      Student(id: "albert", name: "Albert Flores", email: "albert.flores@yahoo.com", expiredDate: "12/09/2026", age: 28, status: "Active", tel: "505-555-0125", lastVisited: "Today", trainerId: "king", isCheckedIn: false, branchId: "downtown", streakCount: 0, benchPressPr: 110, squatPr: 145, bodyWeight: 82, workoutCredits: 8, billingFailed: false, gracePeriodDays: 3, totalWorkouts: 78, referralsCount: 1, staffNotes: "Focus on progressive loading. Absent warning triggered."),
      Student(id: "jane", name: "Jane Cooper", email: "jane.cooper@gmail.com", expiredDate: "15/07/2026", age: 22, status: "Active", tel: "302-555-0199", lastVisited: "Yesterday", trainerId: "king", isCheckedIn: true, branchId: "downtown", streakCount: 4, benchPressPr: 60, squatPr: 90, bodyWeight: 60, workoutCredits: 10, billingFailed: false, gracePeriodDays: 3, totalWorkouts: 120, referralsCount: 4, staffNotes: "Prep for half-marathon; emphasize hamstring and calf foam roll."),
      Student(id: "robert", name: "Robert Fox", email: "robert.fox@gmail.com", expiredDate: "30/08/2026", age: 29, status: "Active", tel: "704-555-0182", lastVisited: "Yesterday", trainerId: "none", isCheckedIn: false, branchId: "west-end", streakCount: 2, benchPressPr: 100, squatPr: 130, bodyWeight: 75, workoutCredits: 0, billingFailed: true, gracePeriodDays: 0, totalWorkouts: 12, referralsCount: 0, staffNotes: "General fitness, target fat loss. Failed auto-debit block."),
    ];

    adviceHistory = [
      CoachingAdvice(studentId: "bessie", coachId: "king", coachName: "King Zarips", text: "Ensure your knees trace outward on the barbell descent. Keep chest high to preserve pelvic alignment.", category: "Form Correction", time: "09:30 AM", branchId: "downtown"),
      CoachingAdvice(studentId: "eleanor", coachId: "lerry", coachName: "Lerry Rops", text: "Scale back carbs on non-training recovery days. Add 20g whey isolate post-workout.", category: "Dietary Recommendation", time: "11:20 AM", branchId: "west-end"),
      CoachingAdvice(studentId: "bessie", coachId: "king", coachName: "King Zarips", text: "Take 48 hours recovery before heavy pulling. Focus on hip flexor foam rolling.", category: "Recovery Advice", time: "Yesterday", branchId: "downtown"),
    ];

    equipment = [
      Equipment(id: "treadmill-1", name: "NordicTrack Treadmill T8", category: "Cardio", status: "Operational", lastMaintenance: "2026-05-15", branchId: "downtown"),
      Equipment(id: "squat-rack-1", name: "Power Squat Rack A", category: "Strength", status: "Operational", lastMaintenance: "2026-06-01", branchId: "downtown"),
      Equipment(id: "leg-press-1", name: "Linear Leg Press Machine", category: "Strength", status: "Under Maintenance", lastMaintenance: "2026-06-12", branchId: "west-end"),
      Equipment(id: "spin-bike-1", name: "Peloton Spin Bike Pro", category: "Cardio", status: "Broken", lastMaintenance: "2026-04-20", branchId: "east-side"),
    ];
  }

  // --- Real-time Firestore Sync Scope ---
  Future<void> setSyncScope(String role, String linkedId) async {
    _currentUserRole = role;
    _currentLinkedId = linkedId;

    // Reset subscriptions
    for (var sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    if (role == 'owner') {
      _currentGymId = linkedId;
      _setupOwnerListeners(linkedId);
    } else if (role == 'trainer') {
      try {
        final trainerDoc = await FirebaseFirestore.instance.collection('trainers').doc(linkedId).get();
        if (trainerDoc.exists) {
          final gymId = trainerDoc.data()?['gymId'] ?? trainerDoc.data()?['branchId'] ?? 'downtown';
          _currentGymId = gymId;
          _setupTrainerListeners(gymId, linkedId);
        }
      } catch (e) {
        debugPrint("Error loading trainer gym scope: $e");
      }
    } else if (role == 'client' || role == 'student') {
      try {
        final clientDoc = await FirebaseFirestore.instance.collection('clients').doc(linkedId).get();
        if (clientDoc.exists) {
          final gymId = clientDoc.data()?['gymId'] ?? 'downtown';
          _currentGymId = gymId;
          _setupClientListeners(gymId, linkedId);
        }
      } catch (e) {
        debugPrint("Error loading client gym scope: $e");
      }
    }
  }

  void _setupOwnerListeners(String gymId) {
    // 1. Listen for Clients
    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('clients')
          .where('gymId', isEqualTo: gymId)
          .snapshots()
          .listen((snap) {
        students = snap.docs.map((doc) => _parseStudent(doc)).toList();
        notifyListeners();
      }, onError: (e) => debugPrint("Firestore client listener error: $e"))
    );

    // 2. Listen for Trainers
    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('trainers')
          .where('gymId', isEqualTo: gymId)
          .snapshots()
          .listen((snap) {
        trainers = [
          Trainer(id: "none", name: "No Trainer", clientsCount: 0, yearsExperience: 0, tags: ["N/A"], branchId: "all"),
          ...snap.docs.map((doc) => _parseTrainer(doc))
        ];
        notifyListeners();
      }, onError: (e) => debugPrint("Firestore trainer listener error: $e"))
    );

    // 3. Listen for Equipment
    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('equipment')
          .where('branchId', isEqualTo: gymId)
          .snapshots()
          .listen((snap) {
        equipment = snap.docs.map((doc) => _parseEquipment(doc)).toList();
        notifyListeners();
      }, onError: (e) => debugPrint("Firestore equipment listener error: $e"))
    );

    // 4. Listen for Coaching Advice
    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('advice')
          .where('branchId', isEqualTo: gymId)
          .snapshots()
          .listen((snap) {
        adviceHistory = snap.docs.map((doc) => _parseAdvice(doc)).toList();
        notifyListeners();
      }, onError: (e) => debugPrint("Firestore advice listener error: $e"))
    );
  }

  void _setupTrainerListeners(String gymId, String trainerId) {
    // Trainers only see clients assigned to them
    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('clients')
          .where('gymId', isEqualTo: gymId)
          .where('trainerId', isEqualTo: trainerId)
          .snapshots()
          .listen((snap) {
        students = snap.docs.map((doc) => _parseStudent(doc)).toList();
        notifyListeners();
      })
    );

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('trainers')
          .where('gymId', isEqualTo: gymId)
          .snapshots()
          .listen((snap) {
        trainers = [
          Trainer(id: "none", name: "No Trainer", clientsCount: 0, yearsExperience: 0, tags: ["N/A"], branchId: "all"),
          ...snap.docs.map((doc) => _parseTrainer(doc))
        ];
        notifyListeners();
      })
    );

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('equipment')
          .where('branchId', isEqualTo: gymId)
          .snapshots()
          .listen((snap) {
        equipment = snap.docs.map((doc) => _parseEquipment(doc)).toList();
        notifyListeners();
      })
    );

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('advice')
          .where('branchId', isEqualTo: gymId)
          .where('coachId', isEqualTo: trainerId)
          .snapshots()
          .listen((snap) {
        adviceHistory = snap.docs.map((doc) => _parseAdvice(doc)).toList();
        notifyListeners();
      })
    );
  }

  void _setupClientListeners(String gymId, String clientId) {
    // Clients only see themselves
    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('clients')
          .doc(clientId)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          students = [_parseStudent(doc)];
          notifyListeners();
        }
      })
    );

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('trainers')
          .where('gymId', isEqualTo: gymId)
          .snapshots()
          .listen((snap) {
        trainers = snap.docs.map((doc) => _parseTrainer(doc)).toList();
        notifyListeners();
      })
    );

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('equipment')
          .where('branchId', isEqualTo: gymId)
          .snapshots()
          .listen((snap) {
        equipment = snap.docs.map((doc) => _parseEquipment(doc)).toList();
        notifyListeners();
      })
    );

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('advice')
          .where('studentId', isEqualTo: clientId)
          .snapshots()
          .listen((snap) {
        adviceHistory = snap.docs.map((doc) => _parseAdvice(doc)).toList();
        notifyListeners();
      })
    );
  }

  // --- XML / Doc Parsers ---
  Student _parseStudent(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Student(
      id: doc.id,
      name: data['name'] ?? 'Unknown Member',
      email: data['email'] ?? '',
      tel: data['tel'] ?? '',
      age: data['age'] ?? 0,
      status: data['status'] ?? 'Active',
      expiredDate: data['expiredDate'] ?? '',
      trainerId: data['trainerId'] ?? 'none',
      isCheckedIn: data['isCheckedIn'] ?? false,
      lastVisited: data['lastVisited'] ?? '',
      branchId: data['gymId'] ?? 'downtown',
      streakCount: data['streakCount'] ?? 0,
      benchPressPr: data['benchPressPr'] ?? 0,
      squatPr: data['squatPr'] ?? 0,
      bodyWeight: data['bodyWeight'] ?? 0,
      workoutCredits: data['workoutCredits'] ?? 0,
      billingFailed: data['subscription']?['billingFailed'] ?? data['billingFailed'] ?? false,
      gracePeriodDays: data['subscription']?['gracePeriodDays'] ?? data['gracePeriodDays'] ?? 3,
      totalWorkouts: data['totalWorkouts'] ?? 0,
      referralsCount: data['referralsCount'] ?? 0,
      staffNotes: data['staffNotes'] ?? '',
    );
  }

  Trainer _parseTrainer(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Trainer(
      id: doc.id,
      name: data['name'] ?? 'Unknown Trainer',
      clientsCount: data['clientsCount'] ?? 0,
      yearsExperience: data['yearsExperience'] ?? data['years'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      branchId: data['gymId'] ?? data['branchId'] ?? 'downtown',
    );
  }

  Equipment _parseEquipment(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Equipment(
      id: doc.id,
      name: data['name'] ?? 'Unknown Equipment',
      category: data['category'] ?? 'General',
      status: data['status'] ?? 'Operational',
      lastMaintenance: data['lastMaintenance'] ?? '',
      branchId: data['branchId'] ?? 'downtown',
    );
  }

  CoachingAdvice _parseAdvice(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CoachingAdvice(
      studentId: data['studentId'] ?? '',
      coachId: data['coachId'] ?? '',
      coachName: data['coachName'] ?? '',
      text: data['text'] ?? '',
      category: data['category'] ?? 'General',
      time: data['time'] ?? '',
      branchId: data['branchId'] ?? 'downtown',
    );
  }

  // --- ACTIONS WITH LIVE WRITES TO FIRESTORE ---

  Future<void> assignTrainer(String studentId, String trainerId) async {
    try {
      await FirebaseFirestore.instance.collection('clients').doc(studentId).update({
        'trainerId': trainerId,
      });
      debugPrint("Firestore: Assigned trainer $trainerId to student $studentId");
    } catch (e) {
      debugPrint("Error assigning trainer in Firestore: $e");
    }
  }

  Future<void> addMember({
    required String name,
    required String email,
    required String tel,
    required int age,
    required String trainerId,
    required String status,
    String? branchId,
  }) async {
    final gymId = _currentGymId ?? 'downtown';
    final randomId = "${name.toLowerCase().replaceAll(' ', '-')}-${Random().nextInt(100)}";
    final linkingCode = 'CLI-${1000 + Random().nextInt(9000)}';

    try {
      await FirebaseFirestore.instance.collection('clients').doc(randomId).set({
        'id': randomId,
        'name': name,
        'email': email,
        'tel': tel,
        'age': age,
        'status': status,
        'expiredDate': "08/12/2026",
        'trainerId': trainerId,
        'isCheckedIn': false,
        'lastVisited': "Today",
        'gymId': gymId,
        'linkingCode': linkingCode,
        'streakCount': 0,
        'benchPressPr': 0,
        'squatPr': 0,
        'bodyWeight': 0,
        'workoutCredits': 10,
        'billingFailed': false,
        'gracePeriodDays': 3,
        'totalWorkouts': 0,
        'referralsCount': 0,
        'staffNotes': "",
      });
      debugPrint("Firestore: Added new member $name to gym $gymId");
    } catch (e) {
      debugPrint("Error adding member to Firestore: $e");
    }
  }

  Future<void> toggleStudentCheckIn(String studentId) async {
    try {
      final student = students.firstWhere((s) => s.id == studentId);
      final nextCheckIn = !student.isCheckedIn;

      await FirebaseFirestore.instance.collection('clients').doc(studentId).update({
        'isCheckedIn': nextCheckIn,
        'lastVisited': "Today",
        'totalWorkouts': FieldValue.increment(nextCheckIn ? 1 : 0),
      });
      debugPrint("Firestore: Toggled check-in for $studentId to $nextCheckIn");
    } catch (e) {
      debugPrint("Error toggling student check-in in Firestore: $e");
    }
  }

  String? simulateCheckIn() {
    final checkedOut = students.where((s) => !s.isCheckedIn).toList();
    if (checkedOut.isEmpty) {
      // Check out everyone
      for (var s in students) {
        FirebaseFirestore.instance.collection('clients').doc(s.id).update({
          'isCheckedIn': false,
        });
      }
      return "Cleared all active check-ins";
    }

    final randStudent = checkedOut[Random().nextInt(checkedOut.length)];
    FirebaseFirestore.instance.collection('clients').doc(randStudent.id).update({
      'isCheckedIn': true,
      'lastVisited': "Today",
      'totalWorkouts': FieldValue.increment(1),
    });
    return "${randStudent.name} checked into the facility!";
  }

  Future<void> sendAdvice({
    required String coachId,
    required String coachName,
    required String studentId,
    required String category,
    required String text,
  }) async {
    final gymId = _currentGymId ?? 'downtown';
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute < 10 ? '0${now.minute}' : '${now.minute}';
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = "Today at $hour:$minute $ampm";

    try {
      final adviceRef = FirebaseFirestore.instance.collection('advice').doc();
      await adviceRef.set({
        'id': adviceRef.id,
        'studentId': studentId,
        'coachId': coachId,
        'coachName': coachName,
        'text': text,
        'category': category,
        'time': timeStr,
        'branchId': gymId,
      });
      debugPrint("Firestore: Sent coaching advice to student $studentId");
    } catch (e) {
      debugPrint("Error sending coaching advice to Firestore: $e");
    }
  }

  Future<void> saveStateToServer() async {
    if (_currentUserRole == 'client' || _currentUserRole == 'student') {
      if (_currentLinkedId != null && students.isNotEmpty) {
        final student = students.firstWhere((s) => s.id == _currentLinkedId, orElse: () => students.first);
        try {
          await FirebaseFirestore.instance.collection('clients').doc(student.id).update({
            'bodyWeight': student.bodyWeight,
            'benchPressPr': student.benchPressPr,
            'squatPr': student.squatPr,
            'streakCount': student.streakCount,
            'status': student.status,
            'billingFailed': student.billingFailed,
            'gracePeriodDays': student.gracePeriodDays,
            'workoutCredits': student.workoutCredits,
          });
          debugPrint("Firestore: Synchronized student metrics & session details.");
        } catch (e) {
          debugPrint("Error syncing state to Firestore: $e");
        }
      }
    } else if (_currentUserRole == 'owner') {
      for (var eq in equipment) {
        try {
          await FirebaseFirestore.instance.collection('equipment').doc(eq.id).update({
            'status': eq.status,
            'lastMaintenance': eq.lastMaintenance,
          });
        } catch (e) {
          debugPrint("Error syncing equipment to Firestore: $e");
        }
      }
      for (var s in students) {
        try {
          await FirebaseFirestore.instance.collection('clients').doc(s.id).update({
            'status': s.status,
            'trainerId': s.trainerId,
            'isCheckedIn': s.isCheckedIn,
            'lastVisited': s.lastVisited,
          });
        } catch (e) {}
      }
    }
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
