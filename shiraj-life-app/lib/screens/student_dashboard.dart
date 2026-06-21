import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models.dart';
import '../state.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final GymAppState _state = GymAppState.instance;
  late String _selectedStudentId;
  String? _aiReportText;
  bool _generatingReport = false;

  int _selectedDayIndex = 0;
  final Set<String> _completedSets = {};

  // Custom mock routine tracker (fallback)
  final List<Map<String, dynamic>> _routineItems = [
    {"title": "Barbell Back Squats (4 Sets x 8 Reps)", "done": false},
    {"title": "Romanian Deadlifts (3 Sets x 10 Reps)", "done": false},
    {"title": "Dumbbell Bench Press (4 Sets x 10 Reps)", "done": false},
    {"title": "Cable Lat Pulldowns (3 Sets x 12 Reps)", "done": false},
  ];

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _selectedStudentId = _state.students.first.id;
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const limeColor = Color(0xFFA3E635);
    const darkBg = Color(0xFF0A0B0D);
    const cardBg = Color(0xFF14171D);
    const borderColor = Color(0xFF22262F);

    final currentStudent = _state.students.firstWhere((s) => s.id == _selectedStudentId);
    final coach = _state.trainers.firstWhere((t) => t.id == currentStudent.trainerId);
    final initials = coach.name.split(" ").map((n) => n[0]).join("");

    final inboxMessages = _state.adviceHistory.where((a) => a.studentId == _selectedStudentId).toList();

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        title: const Row(
          children: [
            Text("📱 ", style: TextStyle(fontSize: 20)),
            Text(
              "Member Zone",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ACS Access Block warning card
            if (currentStudent.billingFailed && currentStudent.gracePeriodDays == 0)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0x33EF4444),
                  border: Border.all(color: Colors.redAccent, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.gpp_bad, color: Colors.redAccent, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "ACCESS REVOKED: BILLING FAILURE",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Your recurring auto-debit membership invoice has failed to process. Entrance turnstiles are locked. Please contact front-desk or pay online to restore access.",
                      style: TextStyle(color: Color(0xFFC5C6C9), fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          currentStudent.billingFailed = false;
                          currentStudent.gracePeriodDays = 3;
                          currentStudent.status = "Active";
                        });
                        _state.saveStateToServer();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Subscription paid via Stripe! turnstile access authorized. 💳")),
                        );
                      },
                      icon: const Icon(Icons.credit_card, size: 16),
                      label: const Text("Pay Expired Invoice (Stripe / Razorpay)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size.fromHeight(36),
                      ),
                    ),
                  ],
                ),
              ),

            // Welcome banner & student profile switcher
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "MEMBER WORKSPACE",
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      color: Color(0xFF06B6D4), // Cyan
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Welcome back, ${currentStudent.name}",
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select active student profile for demo view:",
                    style: TextStyle(fontSize: 12, color: Color(0xFF8E94A0)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: cardBg,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.2),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                    ),
                    value: _selectedStudentId,
                    style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    items: _state.students.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedStudentId = val;
                          _aiReportText = null;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Two columns layout
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                // Left Column
                SizedBox(
                  width: 380,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Active Coach Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "MY PERSONAL COACH",
                                    style: TextStyle(fontSize: 9, fontFamily: 'JetBrains Mono', color: Color(0xFF8E94A0), fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    coach.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    "Hypertrophy and Strength specialist",
                                    style: TextStyle(fontSize: 11, color: Color(0xFF5C626E)),
                                  )
                                ],
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.cyan.withOpacity(0.1),
                              foregroundColor: Colors.cyan,
                              radius: 24,
                              child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Routine checklist card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _state.activeClientRoutine == null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Active Strength Routine (Offline Demo)",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const Text(
                                    "Check off sets completed in this session",
                                    style: TextStyle(fontSize: 11, color: Color(0xFF5C626E)),
                                  ),
                                  const SizedBox(height: 20),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _routineItems.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final item = _routineItems[index];
                                      final isDone = item["done"];
                                      
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            item["done"] = !isDone;
                                          });
                                          if (!isDone) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Set completed! Progressive load logged."),
                                                duration: Duration(milliseconds: 1500),
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isDone ? const Color(0x06A3E635) : Colors.black.withOpacity(0.15),
                                            border: Border.all(color: isDone ? limeColor.withOpacity(0.3) : borderColor),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: isDone ? limeColor : Colors.transparent,
                                                  border: Border.all(color: isDone ? limeColor : const Color(0xFF5C626E), width: 1.5),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: isDone ? const Icon(Icons.check, color: Colors.black, size: 12) : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  item["title"],
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDone ? const Color(0xFF8E94A0) : Colors.white,
                                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _state.activeClientRoutine!['title'] ?? 'Trainer Routine',
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            Text(
                                              _state.activeClientRoutine!['description'] ?? 'Assigned by trainer',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF5C626E)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.fitness_center, color: limeColor, size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Days tabs switcher
                                  if ((_state.activeClientRoutine!['days'] as List<dynamic>? ?? []).isNotEmpty) ...[
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: (_state.activeClientRoutine!['days'] as List<dynamic>).asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final day = entry.value;
                                          final isSelected = _selectedDayIndex == index;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedDayIndex = index;
                                              });
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isSelected ? limeColor : Colors.black.withOpacity(0.2),
                                                border: Border.all(color: isSelected ? limeColor : borderColor),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                day['name'] ?? 'Day ${index + 1}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? Colors.black : Colors.white70,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  // Exercises list for selected day
                                  (() {
                                    final days = _state.activeClientRoutine!['days'] as List<dynamic>? ?? [];
                                    if (days.isEmpty || _selectedDayIndex >= days.length) {
                                      return const Text("No days configured in this routine.", style: TextStyle(fontSize: 12, color: Color(0xFF5C626E)));
                                    }
                                    final day = days[_selectedDayIndex];
                                    final exercises = day['exercises'] as List<dynamic>? ?? [];
                                    if (exercises.isEmpty) {
                                      return const Text("No exercises assigned for this day.", style: TextStyle(fontSize: 12, color: Color(0xFF5C626E)));
                                    }
                                    
                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: exercises.length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                                      itemBuilder: (context, exIndex) {
                                        final ex = exercises[exIndex];
                                        final String name = ex['exerciseName'] ?? 'Exercise';
                                        final int rest = ex['restTime'] ?? 90;
                                        final String? notes = ex['notes'];
                                        final dynamic setsData = ex['setsJson'];
                                        List<dynamic> sets = [];
                                        if (setsData is String) {
                                          try {
                                            sets = jsonDecode(setsData);
                                          } catch (_) {}
                                        } else if (setsData is List) {
                                          sets = setsData;
                                        }
                                        
                                        return Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.15),
                                            border: Border.all(color: borderColor),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                                  ),
                                                  Text(
                                                    "Rest: ${rest}s",
                                                    style: const TextStyle(fontSize: 10, color: limeColor, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              if (notes != null && notes.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Notes: $notes",
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF8E94A0), fontStyle: FontStyle.italic),
                                                ),
                                              ],
                                              const SizedBox(height: 10),
                                              // Render each set inside this exercise
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: List.generate(sets.length, (setIndex) {
                                                  final setObj = sets[setIndex];
                                                  final int reps = setObj['reps'] ?? 10;
                                                  final dynamic weight = setObj['weight'] ?? 0;
                                                  final String setKey = "${_selectedDayIndex}_${exIndex}_$setIndex";
                                                  final isSetDone = _completedSets.contains(setKey);
                                                  
                                                  return GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        if (isSetDone) {
                                                          _completedSets.remove(setKey);
                                                        } else {
                                                          _completedSets.add(setKey);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text("Completed Set ${setIndex + 1} of $name!"),
                                                              duration: const Duration(milliseconds: 1000),
                                                            ),
                                                          );
                                                        }
                                                      });
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: isSetDone ? limeColor.withOpacity(0.1) : Colors.black.withOpacity(0.3),
                                                        border: Border.all(
                                                          color: isSetDone ? limeColor : borderColor,
                                                        ),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            "S${setIndex + 1}: ${reps}x${weight}kg",
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: isSetDone ? limeColor : Colors.white70,
                                                            ),
                                                          ),
                                                          if (isSetDone) ...[
                                                            const SizedBox(width: 4),
                                                            const Icon(Icons.check, color: limeColor, size: 10),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  })(),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),
                      _buildWorkoutLoggerCard(context, currentStudent, limeColor, cardBg, borderColor),
                      const SizedBox(height: 20),
                      _buildAIFitnessReportCard(context, currentStudent, limeColor, cardBg, borderColor),
                      const SizedBox(height: 20),
                      _buildStaffNotesCard(context, currentStudent, limeColor, cardBg, borderColor),
                    ],
                  ),
                ),

                // Right Column
                SizedBox(
                  width: 380,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Gym Access Key card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Gym Access Key",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const Text(
                              "Scan this card at the checkin reader",
                              style: TextStyle(fontSize: 11, color: Color(0xFF5C626E)),
                            ),
                            const SizedBox(height: 16),
                            // Simulated QR Code Visual Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: currentStudent.isCheckedIn
                                    ? [const BoxShadow(color: limeColor, blurRadius: 15, offset: Offset(0, 4))]
                                    : [],
                              ),
                              child: Icon(
                                Icons.qr_code_2,
                                size: 120,
                                color: Colors.black.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: currentStudent.isCheckedIn ? const Color(0x1122C55E) : const Color(0x11EF4444),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: currentStudent.isCheckedIn ? const Color(0x3322C55E) : const Color(0x33EF4444)),
                              ),
                              child: Text(
                                currentStudent.isCheckedIn ? "Status: Checked In Gym" : "Status: Checked Out",
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: currentStudent.isCheckedIn ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentStudent.isCheckedIn ? const Color(0xFFEF4444) : limeColor,
                                foregroundColor: currentStudent.isCheckedIn ? Colors.white : Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: (currentStudent.billingFailed && currentStudent.gracePeriodDays == 0)
                                  ? null
                                  : () {
                                      final wasCheckedIn = currentStudent.isCheckedIn;
                                      _state.toggleStudentCheckIn(_selectedStudentId);
                                      if (!wasCheckedIn && currentStudent.isCheckedIn && currentStudent.totalWorkouts == 100) {
                                        _showMilestoneDialog(context, currentStudent.name);
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            currentStudent.isCheckedIn ? "Checked in! Enjoy your strength session 💪" : "Checked out! Great work today 👍",
                                          ),
                                        ),
                                      );
                                    },
                              child: Text(
                                currentStudent.isCheckedIn ? "Scan Out (Check-Out)" : "Scan In (Check-In)",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Messages / advice feed card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Coach Feed & Advice",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            if (inboxMessages.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text(
                                    "No coaching corrections on your feed yet.",
                                    style: TextStyle(color: Color(0xFF5C626E), fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: inboxMessages.length,
                                separatorBuilder: (context, index) => const Divider(color: borderColor, height: 20),
                                itemBuilder: (context, index) {
                                  final msg = inboxMessages[index];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            msg.coachName,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              msg.category,
                                              style: const TextStyle(fontSize: 8, color: limeColor, fontWeight: FontWeight.bold),
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        msg.text,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E94A0), height: 1.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          msg.time,
                                          style: const TextStyle(fontSize: 9, color: Color(0xFF5C626E), fontFamily: 'JetBrains Mono'),
                                        ),
                                      )
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildLiveTrafficAndZonesCard(context, currentStudent, limeColor, cardBg, borderColor),
                              const SizedBox(height: 20),
                              _buildQRScannerCard(context, currentStudent, limeColor, cardBg, borderColor),
                              const SizedBox(height: 20),
                              _buildTrainerSlotsCard(context, currentStudent, limeColor, cardBg, borderColor),
                              const SizedBox(height: 20),
                              _buildReferralWidget(context, currentStudent, limeColor, cardBg, borderColor),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutLoggerCard(BuildContext context, Student student, Color limeColor, Color cardBg, Color borderColor) {
    final weightController = TextEditingController(text: student.bodyWeight > 0 ? student.bodyWeight.toString() : "");
    final benchController = TextEditingController(text: student.benchPressPr > 0 ? student.benchPressPr.toString() : "");
    final squatController = TextEditingController(text: student.squatPr > 0 ? student.squatPr.toString() : "");

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Log Workout & Progress",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Text(
            "Track bodyweight & hit new PR milestones",
            style: TextStyle(fontSize: 11, color: Color(0xFF5C626E)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Bodyweight (kg)", style: TextStyle(fontSize: 10, color: Colors.white70)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Bench PR (kg)", style: TextStyle(fontSize: 10, color: Colors.white70)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: benchController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Squat PR (kg)", style: TextStyle(fontSize: 10, color: Colors.white70)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: squatController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: limeColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size.fromHeight(38),
            ),
            onPressed: () {
              final w = int.tryParse(weightController.text) ?? student.bodyWeight;
              final b = int.tryParse(benchController.text) ?? student.benchPressPr;
              final s = int.tryParse(squatController.text) ?? student.squatPr;

              setState(() {
                student.bodyWeight = w;
                student.benchPressPr = b;
                student.squatPr = s;
                student.streakCount = student.streakCount + 1; // Habit milestone
              });

              _state.saveStateToServer();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("PR and bodyweight logged! Streak count incremented ⚡")),
              );
            },
            child: const Text("Save Daily Log ✍️", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPrMetric("Streak", "${student.streakCount} days", Colors.amber),
                _buildPrMetric("Bench PR", "${student.benchPressPr}kg", Colors.cyan),
                _buildPrMetric("Squat PR", "${student.squatPr}kg", limeColor),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPrMetric(String label, String val, Color col) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF8E94A0))),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: col)),
      ],
    );
  }

  Widget _buildLiveTrafficAndZonesCard(BuildContext context, Student student, Color limeColor, Color cardBg, Color borderColor) {
    final checkedInCount = _state.students.where((s) => s.isCheckedIn).length;
    final totalMembers = _state.students.length;
    final capacityPct = totalMembers > 0 ? (checkedInCount / totalMembers) : 0.0;

    final branchZones = _state.zones.where((z) => z["branchId"] == student.branchId).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📉 Live Gym Density",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Text(
            "Real-time crowd traffic based on turnstile logs",
            style: TextStyle(fontSize: 11, color: Color(0xFF5C626E)),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Floor occupancy rate", style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                  Text("${(capacityPct * 100).round()}% capacity ($checkedInCount/$totalMembers)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: limeColor)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: capacityPct,
                  backgroundColor: Colors.black.withOpacity(0.3),
                  color: capacityPct > 0.8 ? Colors.redAccent : (capacityPct > 0.5 ? Colors.orangeAccent : limeColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Zone Reservation & Waitlists",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          if (branchZones.isEmpty)
            const Text("No active assets configured for this branch.", style: TextStyle(fontSize: 11, color: Color(0xFF5C626E)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: branchZones.length,
              separatorBuilder: (context, idx) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final z = branchZones[idx];
                final String zoneName = z["name"] ?? "";
                final String status = z["status"] ?? "Available";
                
                final activeBooking = z["activeBooking"];
                final isBookedByMe = activeBooking != null && activeBooking["studentId"] == student.id;

                final List waitlist = z["waitlist"] ?? [];
                final inWaitlist = waitlist.any((w) => w["studentId"] == student.id);

                Widget actionButton;
                if (status == "Available") {
                  actionButton = ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: limeColor, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(60, 24)),
                    onPressed: () {
                      setState(() {
                        z["status"] = "Reserved";
                        z["activeBooking"] = {"studentId": student.id, "until": "1 Hour"};
                      });
                      _state.saveStateToServer();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$zoneName reserved successfully!")));
                    },
                    child: const Text("Claim", style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                  );
                } else if (isBookedByMe) {
                  actionButton = ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(60, 24)),
                    onPressed: () {
                      setState(() {
                        z["activeBooking"] = null;
                        if (waitlist.isNotEmpty) {
                          final next = waitlist.removeAt(0);
                          z["status"] = "Reserved";
                          z["activeBooking"] = {"studentId": next["studentId"], "until": "1 Hour"};
                          final nextStudent = _state.students.firstWhere((s) => s.id == next["studentId"], orElse: () => student);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Alerted next in queue: ${nextStudent.name}!")));
                        } else {
                          z["status"] = "Available";
                        }
                      });
                      _state.saveStateToServer();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Released reserved asset.")));
                    },
                    child: const Text("Release", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  );
                } else if (inWaitlist) {
                  actionButton = OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(60, 24)),
                    onPressed: () {
                      setState(() {
                        waitlist.removeWhere((w) => w["studentId"] == student.id);
                      });
                      _state.saveStateToServer();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from waitlist.")));
                    },
                    child: const Text("Leave Q", style: TextStyle(fontSize: 10, color: Colors.redAccent)),
                  );
                } else {
                  actionButton = ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(60, 24)),
                    onPressed: () {
                      setState(() {
                        waitlist.add({"studentId": student.id, "timestamp": "Now"});
                      });
                      _state.saveStateToServer();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Joined queue for $zoneName.")));
                    },
                    child: const Text("Queue", style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(zoneName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(
                          status == "Available" ? "Status: Free" : (isBookedByMe ? "Booked by You" : "Occupied (Q: ${waitlist.length})"),
                          style: TextStyle(fontSize: 10, color: status == "Available" ? limeColor : Colors.orange),
                        ),
                      ],
                    ),
                    actionButton,
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQRScannerCard(BuildContext context, Student student, Color limeColor, Color cardBg, Color borderColor) {
    final branchMachines = _state.equipment.where((e) => e.branchId == student.branchId).toList();
    if (branchMachines.isEmpty) return const SizedBox.shrink();

    String selectedMachineId = branchMachines.first.id;

    return StatefulBuilder(
      builder: (context, setCardState) {
        final currentMachine = _state.equipment.firstWhere((e) => e.id == selectedMachineId, orElse: () => branchMachines.first);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🛠️ Scan Equipment QR",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Text(
                "Report broken cables or machines directly to mechanics",
                style: TextStyle(fontSize: 11, color: Color(0xFF5C626E)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                dropdownColor: cardBg,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                ),
                value: selectedMachineId,
                style: const TextStyle(fontSize: 12, color: Colors.white),
                items: branchMachines.map((m) => DropdownMenuItem(
                  value: m.id,
                  child: Text("${m.name} (SN: QR-${m.id.toUpperCase()})"),
                )).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setCardState(() {
                      selectedMachineId = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Condition: ${currentMachine.status}", style: TextStyle(fontSize: 11, color: currentMachine.status == "Operational" ? limeColor : Colors.red)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () {
                      setState(() {
                        currentMachine.status = "Broken";
                        currentMachine.lastMaintenance = DateTime.now().toString().split(' ')[0];
                      });
                      _state.saveStateToServer();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Webhook alert sent to mechanic for: ${currentMachine.name}!"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    },
                    child: const Text("Report Breakage", style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrainerSlotsCard(BuildContext context, Student student, Color limeColor, Color cardBg, Color borderColor) {
    if (student.trainerId == "none") {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: cardBg, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(24)),
        child: const Text(
          "Personal Trainer Schedule\nNo assigned coach found.",
          style: TextStyle(color: Color(0xFF5C626E), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    final coachSchedule = _state.trainerAvailability.firstWhere(
      (a) => a["trainerId"] == student.trainerId,
      orElse: () => {"trainerId": student.trainerId, "slots": [], "bookings": []},
    );

    final List openSlots = coachSchedule["slots"] ?? [];
    final List bookings = coachSchedule["bookings"] ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "📅 PT Booking Calendar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                "Credits: ${student.workoutCredits}",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: limeColor),
              ),
            ],
          ),
          const Text(
            "Enforces strict 12-hour late cancellation rules",
            style: TextStyle(fontSize: 11, color: Color(0xFF5C626E)),
          ),
          const SizedBox(height: 16),
          const Text("Assigned Trainer Slots Today:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          if (openSlots.isEmpty)
            const Text("No slots open today on trainer's calendar.", style: TextStyle(fontSize: 11, color: Color(0xFF5C626E)))
          else
            Column(
              children: openSlots.map<Widget>((slot) {
                final isBooked = bookings.any((b) => b["slot"] == slot);
                final isBookedByMe = bookings.any((b) => b["slot"] == slot && b["studentId"] == student.id);

                if (isBooked && !isBookedByMe) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(slot, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      if (isBookedByMe)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(60, 24)),
                          onPressed: () => _cancelPtSession(context, student, coachSchedule, slot),
                          child: const Text("Cancel", style: TextStyle(fontSize: 10, color: Colors.white)),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: limeColor, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(60, 24)),
                          onPressed: student.workoutCredits <= 0
                              ? null
                              : () {
                                  setState(() {
                                    bookings.add({
                                      "slot": slot,
                                      "studentId": student.id,
                                      "bookedAt": DateTime.now().toString().split(' ')[0]
                                    });
                                    student.workoutCredits--;
                                  });
                                  _state.saveStateToServer();
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PT Session booked at $slot!")));
                                },
                          child: const Text("Book Slot", style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _cancelPtSession(BuildContext context, Student student, Map coachSchedule, String slot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171D),
        title: const Text("Cancel PT Session?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "⚠️ PT ATTENDANCE PENALTY RULE:\nAre you canceling this session less than 12 hours before schedule?\n\nIf Yes: 1 session credit is deducted as a penalty charge.\nIf No: Credit is refunded.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final List bookings = coachSchedule["bookings"];
                bookings.removeWhere((b) => b["slot"] == slot && b["studentId"] == student.id);
              });
              _state.saveStateToServer();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Late cancellation processed. 1 penalty credit deducted.")));
            },
            child: const Text("Yes (Late Cancellation)", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final List bookings = coachSchedule["bookings"];
                bookings.removeWhere((b) => b["slot"] == slot && b["studentId"] == student.id);
                student.workoutCredits++;
              });
              _state.saveStateToServer();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cancelled successfully. Credit refunded.")));
            },
            child: const Text("No (Early Cancellation)", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFitnessReportCard(BuildContext context, Student currentStudent, Color limeColor, Color cardBg, Color borderColor) {
    return StatefulBuilder(
      builder: (context, setStateReport) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🤖 AI Monthly Fitness Report",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Text(
                "Let goJim AI analyze your PR progress and training consistency",
                style: TextStyle(fontSize: 11, color: Color(0xFF5C626E)),
              ),
              const SizedBox(height: 16),
              if (_aiReportText != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withOpacity(0.05),
                    border: Border.all(color: const Color(0xFF06B6D4)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text("🧠 ", style: TextStyle(fontSize: 16)),
                          Text(
                            "goJim AI insights:",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _aiReportText!,
                        style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: limeColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _generatingReport
                    ? null
                    : () {
                        setStateReport(() {
                          _generatingReport = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("AI Agent analyzing muscle loads and progress curves... 🧠")),
                        );
                        Future.delayed(const Duration(seconds: 1), () {
                          final relativeBench = currentStudent.bodyWeight > 0 ? (currentStudent.benchPressPr / currentStudent.bodyWeight).toStringAsFixed(2) : "0.00";
                          final relativeSquat = currentStudent.bodyWeight > 0 ? (currentStudent.squatPr / currentStudent.bodyWeight).toStringAsFixed(2) : "0.00";
                          if (mounted) {
                            setState(() {
                              _aiReportText = "• Relative Strength: Bench: ${relativeBench}x BW (${currentStudent.benchPressPr}kg) | Squat: ${relativeSquat}x BW (${currentStudent.squatPr}kg).\n"
                                  "• Consistency Tracker: ${currentStudent.streakCount} days streak. Consistency score is excellent.\n"
                                  "• Coaching Correction: Based on your bench press sets, narrow your grip by 2cm to relieve front shoulder pain and target triceps lockout biomechanics.";
                              _generatingReport = false;
                            });
                          }
                        });
                      },
                child: Text(
                  _generatingReport ? "Analyzing Workout Logs..." : "Generate AI Fitness Report 🤖",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaffNotesCard(BuildContext context, Student currentStudent, Color limeColor, Color cardBg, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📝 Trainer Handover Notes",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            "Direct instructions left by your coach for floor trainers",
            style: TextStyle(fontSize: 11, color: Color(0xFF5C626E)),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              currentStudent.staffNotes.isNotEmpty 
                  ? currentStudent.staffNotes 
                  : "No specific injuries or recovery instructions logged for this cycle. Coach updates these after physical reviews.",
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF8E94A0), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralWidget(BuildContext context, Student currentStudent, Color limeColor, Color cardBg, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🔗 Refer-a-Friend Kiosk Program",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Text(
            "Refer friends at the check-in desk and earn free credits",
            style: TextStyle(fontSize: 11, color: Color(0xFF5C626E)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Your Kiosk Invite Code / Link:",
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF8E94A0), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  "https://shirajlife.com/gym-dashboard.html?ref=${currentStudent.id}",
                  style: TextStyle(fontSize: 10, fontFamily: 'JetBrains Mono', color: limeColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Successful Referrals:",
                style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                "${currentStudent.referralsCount} Friends",
                style: TextStyle(fontSize: 13, color: limeColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMilestoneDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFA3E635), width: 2)),
        title: const Center(
          child: Text(
            "🎉 MILESTONE UNLOCKED!",
            style: TextStyle(color: Color(0xFFA3E635), fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🎉", style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              "Congratulations $name!\nYou just checked in for your 100th workout at goJim! Show this screen at the pro-shop to claim your complimentary protein shake voucher.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA3E635), foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Awesome! Let's Lift 💪", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
