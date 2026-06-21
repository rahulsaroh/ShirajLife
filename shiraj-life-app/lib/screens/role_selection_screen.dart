import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'owner_dashboard.dart';
import 'trainer_dashboard.dart';
import 'student_dashboard.dart';
import 'gym_link_dialog.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _linkedGymName;
  String? _linkedTrainerName;
  String? _linkedClientName;

  @override
  void initState() {
    super.initState();
    _loadLinkingStatus();
  }

  Future<void> _loadLinkingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _linkedGymName = prefs.getString('linkedGymName');
        _linkedTrainerName = prefs.getString('linkedTrainerName');
        _linkedClientName = prefs.getString('linkedClientName');
      });
    } catch (e) {
      // SharedPreferences load failed
    }
  }

  @override
  Widget build(BuildContext context) {
    const limeColor = Color(0xFFA3E635);
    const darkBg = Color(0xFF0A0B0D);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.link, color: limeColor),
            label: Text(
              _linkedClientName != null || _linkedGymName != null || _linkedTrainerName != null
                  ? 'Linked'
                  : 'Link Account',
              style: const TextStyle(color: limeColor, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => const GymLinkDialog(),
              );
              _loadLinkingStatus();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0x15A3E635),
              Colors.transparent,
            ],
            center: Alignment(0.0, -0.3),
            radius: 1.2,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: limeColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33A3E635),
                              blurRadius: 15,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          "💪",
                          style: TextStyle(fontSize: 26),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "goJim",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            "Gym Management B2B Suite",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E94A0),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    "Select Portal Role",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Demo the software flow for different facility members",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5C626E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Display Linking Status if linked
                  if (_linkedClientName != null || _linkedGymName != null || _linkedTrainerName != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14171D),
                        border: Border.all(color: const Color(0xFF22262F)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: limeColor, size: 16),
                              SizedBox(width: 8),
                              Text(
                                "Linked Ecosystem Details",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_linkedClientName != null)
                            Text("• Client Member: $_linkedClientName", style: const TextStyle(color: limeColor, fontSize: 12)),
                          if (_linkedGymName != null)
                            Text("• Gym Branch: $_linkedGymName", style: const TextStyle(color: Colors.cyan, fontSize: 12)),
                          if (_linkedTrainerName != null)
                            Text("• Trainer Coach: $_linkedTrainerName", style: const TextStyle(color: Color(0xFFA855F7), fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Owner Role Button Card
                  _buildRoleCard(
                    context: context,
                    icon: Icons.admin_panel_settings,
                    title: "Gym Owner Portal",
                    description: "View financial reports, manage trainers, adjust capacity, and enroll members.",
                    accentColor: limeColor,
                    glowColor: const Color(0x22A3E635),
                    onTap: () => _showOwnerPasscodeDialog(context),
                  ),
                  const SizedBox(height: 16),

                  // Trainer Role Button Card
                  _buildRoleCard(
                    context: context,
                    icon: Icons.fitness_center,
                    title: "Personal Trainer Workspace",
                    description: "Track your assigned clients, view activity, and log post-workout advice/corrections.",
                    accentColor: const Color(0xFFA855F7), // Purple
                    glowColor: const Color(0x22A855F7),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TrainerDashboardScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Student/Client Role Button Card
                  _buildRoleCard(
                    context: context,
                    icon: Icons.person,
                    title: "Student / Member Portal",
                    description: "Check active routines, view dynamic tips from your coach, and scan/simulate check-in.",
                    accentColor: const Color(0xFF06B6D4), // Cyan
                    glowColor: const Color(0x2206B6D4),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StudentDashboardScreen()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  // Footer details
                  const Center(
                    child: Text(
                      "Shiraj Life • Stacked & Compiled in Flutter",
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        color: Color(0xFF5C626E),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14171D),
        border: Border.all(color: const Color(0xFF262A34), width: 1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          hoverColor: glowColor,
          splashColor: glowColor,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E94A0),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF5C626E),
                  size: 14,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOwnerPasscodeDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14171D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF22262F)),
          ),
          title: const Text(
            "Enter Owner Passcode",
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Access to administrative metrics is restricted.",
                style: TextStyle(fontSize: 12, color: Color(0xFF8E94A0)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Passcode",
                  labelStyle: TextStyle(fontSize: 12, color: Color(0xFF8E94A0)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF22262F))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA3E635))),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.white),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF8E94A0))),
            ),
            TextButton(
              onPressed: () {
                final input = controller.text.trim();
                Navigator.pop(context);
                if (input == "owner123") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OwnerDashboardScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Incorrect passcode. Access denied."),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text("Verify", style: TextStyle(color: Color(0xFFA3E635), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
