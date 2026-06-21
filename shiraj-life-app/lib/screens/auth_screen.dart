import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'owner_dashboard.dart';
import 'trainer_dashboard.dart';
import 'student_dashboard.dart';
import '../state.dart';

const limeColor = Color(0xFFA3E635);
const darkBg = Color(0xFF0A0B0D);
const cardBg = Color(0xFF14171D);
const borderColor = Color(0xFF22262F);

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: darkBg,
            body: Center(
              child: CircularProgressIndicator(color: limeColor),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: darkBg,
                body: Center(
                  child: CircularProgressIndicator(color: limeColor),
                ),
              );
            }

            if (!userSnap.hasData || !userSnap.data!.exists) {
              // Authenticated but no Firestore profile document yet (e.g. first-time Google sign-in)
              return CompleteRegistrationScreen(user: user);
            }

            final userData = userSnap.data!.data() as Map<String, dynamic>;
            final role = userData['role'] ?? 'client';
            final linkedId = userData['linkedId'] ?? userData['clientId'] ?? '';

            // Store credentials locally for local sync compatibility
            _saveSessionLocally(user.email ?? '', role, userData['name'] ?? '', linkedId);

            // Initialize GymAppState sync scope
            GymAppState.instance.setSyncScope(role, linkedId);

            if (role == 'owner') {
              return const OwnerDashboardScreen();
            } else if (role == 'trainer') {
              return const TrainerDashboardScreen();
            } else {
              return const StudentDashboardScreen();
            }
          },
        );
      },
    );
  }

  Future<void> _saveSessionLocally(String email, String role, String name, String linkedId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gojim_gym_email', email);
      await prefs.setString('gojim_gym_role', role);
      await prefs.setString('gojim_gym_name_user', name);
      
      if (role == 'owner') {
        await prefs.setString('linkedGymId', linkedId);
      } else if (role == 'trainer') {
        await prefs.setString('linkedTrainerId', linkedId);
      } else {
        await prefs.setString('linkedClientId', linkedId);
      }
    } catch (e) {
      debugPrint("Error saving session locally: $e");
    }
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  bool _isLoading = false;
  String _selectedRole = 'owner'; // 'owner', 'trainer', 'client'

  // Input Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  // Gym Owner specific fields
  final _gymNameController = TextEditingController();
  final _gymLocationController = TextEditingController();
  final _partnerCodeController = TextEditingController();

  // Trainer / Client linking code
  final _linkingCodeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User cancelled the flow
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Try legacy check or profile check
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // Check for legacy record under /users/{email}
          final emailDoc = await FirebaseFirestore.instance.collection('users').doc(user.email!.toLowerCase()).get();
          if (emailDoc.exists) {
            final legacyData = emailDoc.data()!;
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'email': user.email!.toLowerCase(),
              'role': legacyData['role'],
              'name': legacyData['name'] ?? user.displayName ?? '',
              'linkedId': legacyData['linkedId'] ?? legacyData['clientId'] ?? '',
              'clientId': legacyData['linkedId'] ?? legacyData['clientId'] ?? '',
            });
            await FirebaseFirestore.instance.collection('users').doc(user.email!.toLowerCase()).delete().catchError((e) => debugPrint("Legacy delete error: $e"));
          }
        }
      }
    } catch (e) {
      _showSnackbar("Google Sign-In failed: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    try {
      if (_isSignIn) {
        // Sign In
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = userCredential.user;

        if (user != null) {
          // Check/Migrate profile
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (!doc.exists) {
            final emailDoc = await FirebaseFirestore.instance.collection('users').doc(email).get();
            if (emailDoc.exists) {
              final legacyData = emailDoc.data()!;
              await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'email': email,
                'role': legacyData['role'],
                'name': legacyData['name'] ?? email,
                'linkedId': legacyData['linkedId'] ?? legacyData['clientId'] ?? '',
                'clientId': legacyData['linkedId'] ?? legacyData['clientId'] ?? '',
              });
              await FirebaseFirestore.instance.collection('users').doc(email).delete().catchError((e) => debugPrint("Legacy delete error: $e"));
            }
          }
        }
      } else {
        // Sign Up
        String linkedId = '';

        if (_selectedRole == 'owner') {
          // Create Gym branch first
          final gymName = _gymNameController.text.trim();
          final gymLocation = _gymLocationController.text.trim();
          final partnerCode = _partnerCodeController.text.trim().toUpperCase();
          final linkingCode = 'GYM-${1000 + DateTime.now().millisecond % 9000}';

          final gymRef = FirebaseFirestore.instance.collection('gyms').doc();
          linkedId = gymRef.id;

          final gymData = {
            'id': linkedId,
            'name': gymName,
            'location': gymLocation,
            'linkingCode': linkingCode,
          };
          if (partnerCode.isNotEmpty) {
            gymData['referredByPartnerCode'] = partnerCode;
          }
          await gymRef.set(gymData);

          // Mirror Gym into ShirajLife client list
          final clientUsername = gymName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
          await FirebaseFirestore.instance.collection('clients').doc(linkedId).set({
            'id': linkedId,
            'name': gymName,
            'username': clientUsername.isNotEmpty ? clientUsername : 'gym_${linkedId.substring(0, 4)}',
            'password': 'gym123_${linkedId.substring(0, 4)}',
            'service': 'Gym Mentor SaaS Onboarding',
            'totalContract': 0.0,
            'paidAmount': 0.0,
            'balanceAmount': 0.0,
            'progress': 20,
            'status': 'In Progress',
            'renewalDate': '',
            'details': 'B2B Onboarding. Location: $gymLocation. Linking Code: $linkingCode.',
            'timeline': [
              {'label': 'Requirements Gathering', 'completed': true},
              {'label': 'UI Design Mockups', 'completed': false},
              {'label': 'Frontend Development', 'completed': false},
              {'label': 'Quality Checks', 'completed': false},
              {'label': 'Final Launch & Handover', 'completed': false}
            ],
            'messages': [
              {
                'sender': 'Shiraj',
                'text': 'Welcome to Gym Mentor! Your SaaS workspace provisioning is in progress.',
                'time': DateTime.now().toIso8601String().substring(0, 16).replaceFirst('T', ' ')
              }
            ]
          });

        } else {
          // Verify Gym linking code for Trainers / Clients
          final linkingCode = _linkingCodeController.text.trim().toUpperCase();
          final gymSnap = await FirebaseFirestore.instance
              .collection('gyms')
              .where('linkingCode', isEqualTo: linkingCode)
              .limit(1)
              .get();

          if (gymSnap.docs.isEmpty) {
            throw Exception("Invalid Gym Linking Code. Please check and try again.");
          }
          final gymDoc = gymSnap.docs.first;

          if (_selectedRole == 'trainer') {
            final trainerRef = FirebaseFirestore.instance.collection('trainers').doc();
            linkedId = trainerRef.id;

            await trainerRef.set({
              'id': linkedId,
              'name': name,
              'email': email,
              'linkingCode': 'TRN-${1000 + DateTime.now().millisecond % 9000}',
              'clientsCount': 0,
              'yearsExperience': 3,
              'tags': ['General Trainer'],
              'branchId': gymDoc.id,
              'gymId': gymDoc.id,
            });
          } else {
            final clientRef = FirebaseFirestore.instance.collection('clients').doc();
            linkedId = clientRef.id;

            await clientRef.set({
              'id': linkedId,
              'name': name,
              'email': email,
              'linkingCode': 'CLI-${1000 + DateTime.now().millisecond % 9000}',
              'gymId': gymDoc.id,
              'trainerId': 'none',
              'status': 'Active',
              'tel': '',
              'lastVisited': 'Today',
              'isCheckedIn': false,
            });
          }
        }

        // Create Auth User
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = userCredential.user;

        if (user != null) {
          // Write to Firestore /users/{uid}
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'email': email,
            'role': _selectedRole == 'client' ? 'client' : _selectedRole,
            'name': name,
            'linkedId': linkedId,
            'clientId': linkedId,
          });
        }
      }
    } catch (e) {
      _showSnackbar("Authentication error: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '')}", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0x15A3E635), Colors.transparent],
            center: Alignment(0.0, -0.4),
            radius: 1.2,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Brand Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: limeColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text("💪", style: TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "goJim Suite",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Form mode switcher tab
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _isSignIn = true),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _isSignIn ? limeColor : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "Sign In",
                                      style: TextStyle(
                                        color: _isSignIn ? Colors.black : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _isSignIn = false),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: !_isSignIn ? limeColor : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        color: !_isSignIn ? Colors.black : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Shared Field: Portal Role Selector
                        DropdownButtonFormField<String>(
                          dropdownColor: cardBg,
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: "Access Portal Role",
                            labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'owner', child: Text("💪 Gym Owner")),
                            DropdownMenuItem(value: 'trainer', child: Text("🏋️ Personal Trainer")),
                            DropdownMenuItem(value: 'client', child: Text("👤 Gym Client / Member")),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedRole = val);
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Name Field (Sign Up only)
                        if (!_isSignIn) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "Full Name",
                              labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                            ),
                            style: const TextStyle(fontSize: 14),
                            validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Shared Field: Email
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "Email Address",
                            labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                          ),
                          style: const TextStyle(fontSize: 14),
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) => val == null || !val.contains('@') ? "Enter a valid email" : null,
                        ),
                        const SizedBox(height: 12),

                        // Shared Field: Password
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                          ),
                          style: const TextStyle(fontSize: 14),
                          obscureText: true,
                          validator: (val) => val == null || val.length < 6 ? "Password must be at least 6 characters" : null,
                        ),
                        const SizedBox(height: 12),

                        // Role-specific sign up fields
                        if (!_isSignIn) ...[
                          if (_selectedRole == 'owner') ...[
                            TextFormField(
                              controller: _gymNameController,
                              decoration: const InputDecoration(
                                labelText: "Gym Name",
                                labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                              ),
                              style: const TextStyle(fontSize: 14),
                              validator: (val) => val == null || val.isEmpty ? "Gym Name is required" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _gymLocationController,
                              decoration: const InputDecoration(
                                labelText: "Gym Location",
                                labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                              ),
                              style: const TextStyle(fontSize: 14),
                              validator: (val) => val == null || val.isEmpty ? "Location is required" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _partnerCodeController,
                              decoration: const InputDecoration(
                                labelText: "Referral / Partner Code (Optional)",
                                labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ] else ...[
                            TextFormField(
                              controller: _linkingCodeController,
                              decoration: const InputDecoration(
                                labelText: "Gym Linking Code (e.g. GYM-XXXX)",
                                labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                              ),
                              style: const TextStyle(fontSize: 14),
                              validator: (val) => val == null || val.isEmpty ? "Linking Code is required" : null,
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 8),
                        // Submit Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: limeColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _isLoading ? null : _handleSubmit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : Text(
                                  _isSignIn ? "Sign In" : "Sign Up",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),
                        const SizedBox(height: 14),

                        const Row(
                          children: [
                            Expanded(child: Divider(color: borderColor)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text("OR", style: TextStyle(color: Colors.white30, fontSize: 11)),
                            ),
                            Expanded(child: Divider(color: borderColor)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Google Sign-In Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: borderColor),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Image.network(
                            "https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png",
                            height: 18,
                            width: 18,
                            errorBuilder: (context, _, __) => const Icon(Icons.g_mobiledata, size: 20),
                          ),
                          label: Text(
                            _isSignIn ? "Continue with Google" : "Sign Up with Google",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CompleteRegistrationScreen extends StatefulWidget {
  final User user;
  const CompleteRegistrationScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<CompleteRegistrationScreen> createState() => _CompleteRegistrationScreenState();
}

class _CompleteRegistrationScreenState extends State<CompleteRegistrationScreen> {
  String _selectedRole = 'owner';
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Inputs
  final _nameController = TextEditingController();
  final _gymNameController = TextEditingController();
  final _gymLocationController = TextEditingController();
  final _partnerCodeController = TextEditingController();
  final _linkingCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.displayName ?? '';
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = widget.user.email!.toLowerCase();
    final name = _nameController.text.trim();
    String linkedId = '';

    try {
      if (_selectedRole == 'owner') {
        final gymName = _gymNameController.text.trim();
        final gymLocation = _gymLocationController.text.trim();
        final partnerCode = _partnerCodeController.text.trim().toUpperCase();
        final linkingCode = 'GYM-${1000 + DateTime.now().millisecond % 9000}';

        final gymRef = FirebaseFirestore.instance.collection('gyms').doc();
        linkedId = gymRef.id;

        final gymData = {
          'id': linkedId,
          'name': gymName,
          'location': gymLocation,
          'linkingCode': linkingCode,
        };
        if (partnerCode.isNotEmpty) {
          gymData['referredByPartnerCode'] = partnerCode;
        }
        await gymRef.set(gymData);

        // Mirror Gym to ShirajLife client list
        final clientUsername = gymName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        await FirebaseFirestore.instance.collection('clients').doc(linkedId).set({
          'id': linkedId,
          'name': gymName,
          'username': clientUsername.isNotEmpty ? clientUsername : 'gym_${linkedId.substring(0, 4)}',
          'password': 'gym123_${linkedId.substring(0, 4)}',
          'service': 'Gym Mentor SaaS Onboarding',
          'totalContract': 0.0,
          'paidAmount': 0.0,
          'balanceAmount': 0.0,
          'progress': 20,
          'status': 'In Progress',
          'renewalDate': '',
          'details': 'B2B Onboarding. Location: $gymLocation. Linking Code: $linkingCode.',
          'timeline': [
            {'label': 'Requirements Gathering', 'completed': true},
            {'label': 'UI Design Mockups', 'completed': false},
            {'label': 'Frontend Development', 'completed': false},
            {'label': 'Quality Checks', 'completed': false},
            {'label': 'Final Launch & Handover', 'completed': false}
          ],
          'messages': [
            {
              'sender': 'Shiraj',
              'text': 'Welcome to Gym Mentor! Your SaaS workspace provisioning is in progress.',
              'time': DateTime.now().toIso8601String().substring(0, 16).replaceFirst('T', ' ')
            }
          ]
        });

      } else {
        final linkingCode = _linkingCodeController.text.trim().toUpperCase();
        final gymSnap = await FirebaseFirestore.instance
            .collection('gyms')
            .where('linkingCode', isEqualTo: linkingCode)
            .limit(1)
            .get();

        if (gymSnap.docs.isEmpty) {
          throw Exception("Invalid Gym Linking Code. Verify and try again.");
        }
        final gymDoc = gymSnap.docs.first;

        if (_selectedRole == 'trainer') {
          final trainerRef = FirebaseFirestore.instance.collection('trainers').doc();
          linkedId = trainerRef.id;

          await trainerRef.set({
            'id': linkedId,
            'name': name,
            'email': email,
            'linkingCode': 'TRN-${1000 + DateTime.now().millisecond % 9000}',
            'clientsCount': 0,
            'yearsExperience': 3,
            'tags': ['General Trainer'],
            'branchId': gymDoc.id,
            'gymId': gymDoc.id,
          });
        } else {
          final clientRef = FirebaseFirestore.instance.collection('clients').doc();
          linkedId = clientRef.id;

          await clientRef.set({
            'id': linkedId,
            'name': name,
            'email': email,
            'linkingCode': 'CLI-${1000 + DateTime.now().millisecond % 9000}',
            'gymId': gymDoc.id,
            'trainerId': 'none',
            'status': 'Active',
            'tel': '',
            'lastVisited': 'Today',
            'isCheckedIn': false,
          });
        }
      }

      // Write user profile to Firestore
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'email': email,
        'role': _selectedRole == 'client' ? 'client' : _selectedRole,
        'name': name,
        'linkedId': linkedId,
        'clientId': linkedId,
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              color: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Complete Registration",
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
                        "Finish setting up your gym profile to get started.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Your Full Name",
                          labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        dropdownColor: cardBg,
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: "Select Role",
                          labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'owner', child: Text("💪 Gym Owner")),
                          DropdownMenuItem(value: 'trainer', child: Text("🏋️ Personal Trainer")),
                          DropdownMenuItem(value: 'client', child: Text("👤 Gym Client / Member")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRole = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      if (_selectedRole == 'owner') ...[
                        TextFormField(
                          controller: _gymNameController,
                          decoration: const InputDecoration(
                            labelText: "Gym Name",
                            labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                          ),
                          style: const TextStyle(fontSize: 14),
                          validator: (val) => val == null || val.isEmpty ? "Gym name is required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _gymLocationController,
                          decoration: const InputDecoration(
                            labelText: "Gym Location",
                            labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                          ),
                          style: const TextStyle(fontSize: 14),
                          validator: (val) => val == null || val.isEmpty ? "Location is required" : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _partnerCodeController,
                          decoration: const InputDecoration(
                            labelText: "Referral / Partner Code (Optional)",
                            labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _linkingCodeController,
                          decoration: const InputDecoration(
                            labelText: "Gym Linking Code (e.g. GYM-XXXX)",
                            labelStyle: TextStyle(color: Colors.white70, fontSize: 13),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: limeColor)),
                          ),
                          style: const TextStyle(fontSize: 14),
                          validator: (val) => val == null || val.isEmpty ? "Linking Code is required" : null,
                        ),
                      ],
                      const SizedBox(height: 24),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: limeColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isLoading ? null : _handleComplete,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Text(
                                "Complete Setup",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text("Sign Out", style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
