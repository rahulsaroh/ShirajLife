import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'models.dart';

class GymAppState extends ChangeNotifier {
  // Singleton pattern for easy global access without dependencies
  static final GymAppState instance = GymAppState._internal();
  GymAppState._internal() {
    _initializeData();
    fetchStateFromServer();
    // Auto-sync every 5 seconds
    Stream.periodic(const Duration(seconds: 5)).listen((_) {
      fetchStateFromServer();
    });
  }

  late List<Branch> branches;
  late List<Trainer> trainers;
  late List<Student> students;
  late List<CoachingAdvice> adviceHistory;
  late List<Equipment> equipment;
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

  // --- HTTP SYNC ACTIONS ---

  Future<void> fetchStateFromServer() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse("http://10.0.2.2:8000/data")).timeout(const Duration(seconds: 3));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(responseBody);
        
        // Parse branches
        if (data.containsKey("branches")) {
          final List<dynamic> brList = data["branches"];
          branches = brList.map((br) => Branch(
            id: br["id"] ?? "",
            name: br["name"] ?? "",
            location: br["location"] ?? "",
          )).toList();
        }

        // Parse trainers
        if (data.containsKey("trainers")) {
          final List<dynamic> trList = data["trainers"];
          trainers = trList.map((tr) => Trainer(
            id: tr["id"] ?? "",
            name: tr["name"] ?? "",
            clientsCount: tr["clientsCount"] ?? 0,
            yearsExperience: tr["yearsExperience"] ?? tr["years"] ?? 0,
            tags: List<String>.from(tr["tags"] ?? []),
            branchId: tr["branchId"] ?? "all",
          )).toList();
        }
        
        // Parse leads
        if (data.containsKey("leads")) {
          rawLeads = data["leads"] ?? [];
        } else {
          rawLeads = [];
        }

        // Parse students
        if (data.containsKey("students")) {
          final List<dynamic> stList = data["students"];
          students = stList.map<Student>((st) => Student(
            id: st["id"] ?? "",
            name: st["name"] ?? "",
            email: st["email"] ?? "",
            tel: st["tel"] ?? "",
            age: st["age"] ?? 0,
            status: st["status"] ?? "Active",
            expiredDate: st["expiredDate"] ?? "",
            trainerId: st["trainerId"] ?? "none",
            isCheckedIn: st["isCheckedIn"] ?? false,
            lastVisited: st["lastVisited"] ?? "",
            branchId: st["branchId"] ?? "all",
            streakCount: st["streakCount"] ?? 0,
            benchPressPr: st["benchPressPr"] ?? 0,
            squatPr: st["squatPr"] ?? 0,
            bodyWeight: st["bodyWeight"] ?? 0,
            workoutCredits: st["workoutCredits"] ?? 0,
            billingFailed: st["subscription"]?["billingFailed"] ?? false,
            gracePeriodDays: st["subscription"]?["gracePeriodDays"] ?? 3,
            totalWorkouts: st["totalWorkouts"] ?? 0,
            referralsCount: st["referralsCount"] ?? 0,
            staffNotes: st["staffNotes"] ?? "",
          )).toList();
        }
        
        // Parse advice
        if (data.containsKey("advice")) {
          final List<dynamic> adList = data["advice"];
          adviceHistory = adList.map((ad) => CoachingAdvice(
            studentId: ad["studentId"] ?? "",
            coachId: ad["coachId"] ?? "",
            coachName: ad["coachName"] ?? "",
            text: ad["text"] ?? "",
            category: ad["category"] ?? "",
            time: ad["time"] ?? "",
            branchId: ad["branchId"] ?? "all",
          )).toList();
        }

        // Parse equipment
        if (data.containsKey("equipment")) {
          final List<dynamic> eqList = data["equipment"];
          equipment = eqList.map((eq) => Equipment(
            id: eq["id"] ?? "",
            name: eq["name"] ?? "",
            category: eq["category"] ?? "",
            status: eq["status"] ?? "Operational",
            lastMaintenance: eq["lastMaintenance"] ?? "",
            branchId: eq["branchId"] ?? "all",
          )).toList();
        }

        proShopInventory = data["proShopInventory"] ?? [];
        checklists = data["checklists"] ?? [];
        trainerAvailability = data["trainerAvailability"] ?? [];
        zones = data["zones"] ?? [];
        workoutLogs = data["workoutLogs"] ?? [];
        announcements = data["announcements"] ?? [];
        socialSchedule = data["socialSchedule"] ?? [];
        
        notifyListeners();
      }
    } catch (e) {
      // Offline fallback, warning ignored to prevent spam
    }
  }

  Future<void> saveStateToServer() async {
    try {
      final payload = {
        "branches": branches.map((b) => {
          "id": b.id,
          "name": b.name,
          "location": b.location,
        }).toList(),
        "trainers": trainers.map((t) => {
          "id": t.id,
          "name": t.name,
          "clientsCount": t.clientsCount,
          "yearsExperience": t.yearsExperience,
          "tags": t.tags,
          "branchId": t.branchId,
        }).toList(),
        "leads": rawLeads,
        "students": students.map((s) => {
          "id": s.id,
          "name": s.name,
          "email": s.email,
          "tel": s.tel,
          "age": s.age,
          "status": s.status,
          "expiredDate": s.expiredDate,
          "trainerId": s.trainerId,
          "isCheckedIn": s.isCheckedIn,
          "lastVisited": s.lastVisited,
          "branchId": s.branchId,
          "streakCount": s.streakCount,
          "benchPressPr": s.benchPressPr,
          "squatPr": s.squatPr,
          "bodyWeight": s.bodyWeight,
          "workoutCredits": s.workoutCredits,
          "totalWorkouts": s.totalWorkouts,
          "referralsCount": s.referralsCount,
          "staffNotes": s.staffNotes,
          "subscription": {
            "autoDebit": true,
            "billingFailed": s.billingFailed,
            "gracePeriodDays": s.gracePeriodDays,
            "paymentMethod": "Stripe"
          }
        }).toList(),
        "advice": adviceHistory.map((a) => {
          "studentId": a.studentId,
          "coachId": a.coachId,
          "coachName": a.coachName,
          "text": a.text,
          "category": a.category,
          "time": a.time,
          "branchId": a.branchId,
        }).toList(),
        "equipment": equipment.map((e) => {
          "id": e.id,
          "name": e.name,
          "category": e.category,
          "status": e.status,
          "lastMaintenance": e.lastMaintenance,
          "branchId": e.branchId,
        }).toList(),
        "proShopInventory": proShopInventory,
        "checklists": checklists,
        "trainerAvailability": trainerAvailability,
        "zones": zones,
        "workoutLogs": workoutLogs,
        "announcements": announcements,
        "socialSchedule": socialSchedule,
      };
      
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse("http://10.0.2.2:8000/data")).timeout(const Duration(seconds: 3));
      request.headers.set('content-type', 'application/json');
      request.add(utf8.encode(jsonEncode(payload)));
      await request.close();
    } catch (e) {
      // Offline fallback
    }
  }

  // --- ACTIONS ---

  void assignTrainer(String studentId, String trainerId) {
    final studentIndex = students.indexWhere((s) => s.id == studentId);
    if (studentIndex != -1) {
      students[studentIndex].trainerId = trainerId;
      notifyListeners();
      saveStateToServer();
    }
  }

  void addMember({
    required String name,
    required String email,
    required String tel,
    required int age,
    required String trainerId,
    required String status,
    String? branchId,
  }) {
    final randomId = "${name.toLowerCase().replaceAll(' ', '-')}-${Random().nextInt(100)}";
    final trainer = trainers.firstWhere((t) => t.id == trainerId, orElse: () => trainers.first);
    final finalBranchId = branchId ?? (trainer.id != "none" ? trainer.branchId : "downtown");
    
    final newStudent = Student(
      id: randomId,
      name: name,
      email: email,
      tel: tel,
      age: age,
      status: status,
      expiredDate: "08/12/2026",
      trainerId: trainerId,
      isCheckedIn: false,
      lastVisited: "Today",
      branchId: finalBranchId,
      streakCount: 0,
      benchPressPr: 0,
      squatPr: 0,
      bodyWeight: 0,
      workoutCredits: 10,
      billingFailed: false,
      gracePeriodDays: 3,
      totalWorkouts: 0,
      referralsCount: 0,
      staffNotes: "",
    );
    students.add(newStudent);
    notifyListeners();
    saveStateToServer();
  }

  void toggleStudentCheckIn(String studentId) {
    final studentIndex = students.indexWhere((s) => s.id == studentId);
    if (studentIndex != -1) {
      final s = students[studentIndex];
      s.isCheckedIn = !s.isCheckedIn;
      if (s.isCheckedIn) {
        s.lastVisited = "Today";
        s.totalWorkouts++;
      }
      notifyListeners();
      saveStateToServer();
    }
  }

  String? simulateCheckIn() {
    final checkedOut = students.where((s) => !s.isCheckedIn).toList();
    if (checkedOut.isEmpty) {
      // Toggle all off
      for (var s in students) {
        s.isCheckedIn = false;
      }
      notifyListeners();
      saveStateToServer();
      return "Cleared all active check-ins";
    }

    final randStudent = checkedOut[Random().nextInt(checkedOut.length)];
    randStudent.isCheckedIn = true;
    randStudent.lastVisited = "Today";
    randStudent.totalWorkouts++;
    notifyListeners();
    saveStateToServer();
    return "${randStudent.name} checked into the facility!";
  }

  void sendAdvice({
    required String coachId,
    required String coachName,
    required String studentId,
    required String category,
    required String text,
  }) {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute < 10 ? '0${now.minute}' : '${now.minute}';
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = "Today at $hour:$minute $ampm";

    final student = students.firstWhere((s) => s.id == studentId, orElse: () => students.first);

    final newAdvice = CoachingAdvice(
      studentId: studentId,
      coachId: coachId,
      coachName: coachName,
      text: text,
      category: category,
      time: timeStr,
      branchId: student.branchId,
    );

    adviceHistory.insert(0, newAdvice); // Insert at top
    notifyListeners();
    saveStateToServer();
  }
}
