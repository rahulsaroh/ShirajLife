import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  final GymAppState _state = GymAppState.instance;
  late String _selectedTrainerId;

  // Form controllers
  String? _targetStudentId;
  String _adviceCategory = "Form Correction";
  final _adviceTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _selectedTrainerId = _state.trainers.firstWhere((t) => t.id != "none").id;
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _adviceTextController.dispose();
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

    final currentTrainer = _state.trainers.firstWhere((t) => t.id == _selectedTrainerId);
    final assignedStudents = _state.students.where((s) => s.trainerId == _selectedTrainerId).toList();

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        title: const Row(
          children: [
            Text("🏋️‍♂️ ", style: TextStyle(fontSize: 20)),
            Text(
              "Trainer Hub",
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
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Section with Dropdown Selector
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
                    "COACH PORTAL",
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      color: Color(0xFFA855F7), // Purple
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Welcome back, ${currentTrainer.name}",
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select active trainer profile for demo workspace:",
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
                    value: _selectedTrainerId,
                    style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    items: _state.trainers.where((t) => t.id != "none").map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedTrainerId = val;
                          _targetStudentId = null; // Reset form choice
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main Columns
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                // List of Students Card
                Container(
                  width: 330,
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
                        "My Assigned Clients",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      if (assignedStudents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Text(
                              "No students currently assigned.",
                              style: TextStyle(color: Color(0xFF5C626E), fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: assignedStudents.length,
                          separatorBuilder: (context, index) => const Divider(color: borderColor, height: 20),
                          itemBuilder: (context, index) {
                            final s = assignedStudents[index];
                            final initials = s.name.split(" ").map((n) => n[0]).join("");
                            
                            return Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF22262F),
                                  radius: 16,
                                  child: Text(
                                    initials,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                      ),
                                      Text(
                                        s.tel,
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF5C626E)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: s.isCheckedIn ? limeColor.withOpacity(0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    s.isCheckedIn ? "Inside" : "Away",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: s.isCheckedIn ? limeColor : const Color(0xFF5C626E),
                                    ),
                                  ),
                                )
                              ],
                            );
                          },
                        )
                    ],
                  ),
                ),

                // Advice form card
                Container(
                  width: 440,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Post Workout Advice & Corrections",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      // Dropdown select student
                      const Text("Target Student", style: TextStyle(fontSize: 11, color: Color(0xFF8E94A0), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        dropdownColor: cardBg,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.2),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderColor)),
                        ),
                        hint: const Text("Select a student...", style: TextStyle(fontSize: 12, color: Color(0xFF5C626E))),
                        value: _targetStudentId,
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                        items: assignedStudents.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        )).toList(),
                        onChanged: (val) {
                          setState(() {
                            _targetStudentId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dropdown select category
                      const Text("Advice Category", style: TextStyle(fontSize: 11, color: Color(0xFF8E94A0), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        dropdownColor: cardBg,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.2),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderColor)),
                        ),
                        value: _adviceCategory,
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: "Form Correction", child: Text("🏋️ Form Correction")),
                          DropdownMenuItem(value: "Dietary Recommendation", child: Text("🍏 Dietary Recommendation")),
                          DropdownMenuItem(value: "Recovery Advice", child: Text("💤 Recovery & Rest")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _adviceCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Text message field
                      const Text("Advice Message details", style: TextStyle(fontSize: 11, color: Color(0xFF8E94A0), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _adviceTextController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Explain plateaus, squat depth corrections, diet modifications...",
                          hintStyle: const TextStyle(color: Color(0xFF5C626E), fontSize: 12),
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: limeColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: limeColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _sendAdviceSubmit,
                        child: const Text(
                          "Send Advice to Student",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
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

  void _sendAdviceSubmit() {
    final studentId = _targetStudentId;
    final text = _adviceTextController.text.trim();

    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a target student first.")),
      );
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Advice message cannot be empty.")),
      );
      return;
    }

    final currentTrainer = _state.trainers.firstWhere((t) => t.id == _selectedTrainerId);
    final targetStudentName = _state.students.firstWhere((s) => s.id == studentId).name;

    _state.sendAdvice(
      coachId: _selectedTrainerId,
      coachName: currentTrainer.name,
      studentId: studentId,
      category: _adviceCategory,
      text: text,
    );

    // Reset fields
    setState(() {
      _adviceTextController.clear();
      _targetStudentId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Coaching advice successfully sent to $targetStudentName's feed!")),
    );
  }
}
