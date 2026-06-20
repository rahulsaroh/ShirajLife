class Trainer {
  final String id;
  final String name;
  final int clientsCount;
  final int yearsExperience;
  final List<String> tags;
  final String branchId;

  Trainer({
    required this.id,
    required this.name,
    required this.clientsCount,
    required this.yearsExperience,
    required this.tags,
    required this.branchId,
  });
}

class Student {
  final String id;
  final String name;
  final String email;
  final String tel;
  final int age;
  String status; // 'Active' or 'In Active'
  final String expiredDate;
  String trainerId;
  bool isCheckedIn;
  String lastVisited;
  final String branchId;
  int streakCount;
  int benchPressPr;
  int squatPr;
  int bodyWeight;
  int workoutCredits;
  bool billingFailed;
  int gracePeriodDays;
  int totalWorkouts;
  int referralsCount;
  String staffNotes;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.tel,
    required this.age,
    required this.status,
    required this.expiredDate,
    required this.trainerId,
    required this.isCheckedIn,
    required this.lastVisited,
    required this.branchId,
    required this.streakCount,
    required this.benchPressPr,
    required this.squatPr,
    required this.bodyWeight,
    required this.workoutCredits,
    required this.billingFailed,
    required this.gracePeriodDays,
    required this.totalWorkouts,
    required this.referralsCount,
    required this.staffNotes,
  });
}

class CoachingAdvice {
  final String studentId;
  final String coachId;
  final String coachName;
  final String text;
  final String category; // 'Form Correction', 'Dietary Recommendation', 'Recovery Advice'
  final String time;
  final String branchId;

  CoachingAdvice({
    required this.studentId,
    required this.coachId,
    required this.coachName,
    required this.text,
    required this.category,
    required this.time,
    required this.branchId,
  });
}

class Equipment {
  final String id;
  final String name;
  final String category;
  String status; // 'Operational', 'Under Maintenance', or 'Broken'
  String lastMaintenance;
  final String branchId;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.lastMaintenance,
    required this.branchId,
  });
}

class Branch {
  final String id;
  final String name;
  final String location;

  Branch({
    required this.id,
    required this.name,
    required this.location,
  });
}
