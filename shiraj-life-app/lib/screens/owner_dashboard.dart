import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models.dart';
import '../state.dart';

const limeColor = Color(0xFFA3E635);
const purpleColor = Color(0xFFA855F7);
const orangeColor = Color(0xFFF97316);
const darkBg = Color(0xFF0A0B0D);
const cardBg = Color(0xFF14171D);
const borderColor = Color(0xFF22262F);

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final GymAppState _state = GymAppState.instance;
  String _searchQuery = "";
  String _sortFilter = "all";
  String _selectedMonth = "Apr";
  
  // Custom capacity grid tracker
  late List<int> _capacityGridStates;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _randomizeCapacityGrid();
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _randomizeCapacityGrid() {
    // 0 = empty, 1 = occupied (lime), 2 = HIIT (orange), 3 = Coached (purple)
    final rand = Random();
    _capacityGridStates = List.generate(60, (index) {
      final val = rand.nextDouble();
      if (val < 0.35) return 1; // Occupied
      if (val > 0.35 && val < 0.48) return 2; // HIIT
      if (val > 0.48 && val < 0.55) return 3; // Coached
      return 0; // Empty
    });
  }

  double get _capacityPercentage {
    final active = _capacityGridStates.where((s) => s > 0).length;
    return (active / _capacityGridStates.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        title: const Row(
          children: [
            Text("💪 ", style: TextStyle(fontSize: 20)),
            Text(
              "goJim Console",
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
            icon: const Icon(Icons.refresh, color: limeColor),
            onPressed: () {
              setState(() {
                _randomizeCapacityGrid();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Refreshed gym capacity data!")),
              );
            },
          ),
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
            // Row 1: Header Welcome Banner & KPIs
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.start,
              children: [
                // Welcome header card
                Container(
                  width: 320,
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
                        "GOJIM MANAGEMENT",
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          color: limeColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Manage your\nFitness business",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "6 Aug 2026, 07:20am",
                        style: TextStyle(fontSize: 13, color: Color(0xFF8E94A0)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: limeColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _showAddMemberDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          "New Member",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final msg = _state.simulateCheckIn();
                          if (msg != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Text("⚡ "),
                                    Text(msg),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF14171D),
                              ),
                            );
                            setState(() {
                              _randomizeCapacityGrid();
                            });
                          }
                        },
                        child: const Text(
                          "Simulate Check-In",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                // KPI grid panel helper
                SizedBox(
                  width: 500,
                  child: Column(
                    children: [
                      // Stat 2x2 grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.8,
                        children: [
                          _buildKpiCard(
                            title: "Revenue",
                            value: "₹3.7L",
                            trend: "+2.1%",
                            isUp: true,
                            subtitle: "Month / July",
                            icon: Icons.monetization_on,
                          ),
                          _buildKpiCard(
                            title: "Members",
                            value: "${_state.students.length}",
                            trend: "-1.8%",
                            isUp: false,
                            subtitle: "Active Members",
                            icon: Icons.people,
                          ),
                          _buildKpiCard(
                            title: "Visited",
                            value: "${_state.students.where((s) => s.isCheckedIn).length + 52}",
                            trend: "-1.3%",
                            isUp: false,
                            subtitle: "Daily Average",
                            icon: Icons.timer,
                          ),
                          _buildKpiCard(
                            title: "Trainer",
                            value: "${_state.trainers.length}",
                            trend: "+3.6%",
                            isUp: true,
                            subtitle: "Active Coaches",
                            icon: Icons.sports_gymnastics,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Row 2: Gym Capacity Visualizer & Revenue Bar Chart
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                // Capacity widget
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Gym Capacity",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Indoor and outdoor occupancy",
                                style: TextStyle(fontSize: 11, color: Color(0xFF8E94A0)),
                              ),
                            ],
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: limeColor.withOpacity(0.1),
                            ),
                            child: const Center(
                              child: Text("📊", style: TextStyle(fontSize: 10)),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Dot grid (10x6)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 10,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: 60,
                        itemBuilder: (context, index) {
                          final stateVal = _capacityGridStates[index];
                          Color dotColor = const Color(0xFF2A2E37);
                          List<BoxShadow> shadows = [];
                          if (stateVal == 1) {
                            dotColor = limeColor;
                            shadows = [const BoxShadow(color: limeColor, blurRadius: 4)];
                          } else if (stateVal == 2) {
                            dotColor = orangeColor;
                            shadows = [const BoxShadow(color: orangeColor, blurRadius: 4)];
                          } else if (stateVal == 3) {
                            dotColor = purpleColor;
                            shadows = [const BoxShadow(color: purpleColor, blurRadius: 4)];
                          }
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                              boxShadow: shadows,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Space Status:",
                              style: TextStyle(fontSize: 13, color: Color(0xFF8E94A0), fontWeight: FontWeight.w600),
                            ),
                            Text(
                              "${_capacityPercentage.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: limeColor,
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // Revenue analytics chart widget
                Container(
                  width: 500,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Revenue Analytics",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Monthly comparison metrics",
                                style: TextStyle(fontSize: 11, color: Color(0xFF8E94A0)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildLegendItem("Rev", limeColor),
                              const SizedBox(width: 12),
                              _buildLegendItem("Exp", purpleColor),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Bars comparison custom row
                      SizedBox(
                        height: 160,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildBarGroup("Jan", 0.6, 0.35),
                            _buildBarGroup("Feb", 0.8, 0.45),
                            _buildBarGroup("Mar", 0.7, 0.4),
                            _buildBarGroup("Apr", 0.75, 0.5),
                            _buildBarGroup("May", 0.72, 0.43),
                            _buildBarGroup("Jun", 0.85, 0.48),
                            _buildBarGroup("Jul", 0.65, 0.42),
                            _buildBarGroup("Aug", 0.9, 0.52),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tooltip dynamic text summary container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Selected: $_selectedMonth 2026",
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: limeColor,
                              ),
                            ),
                            Row(
                              children: [
                                const Text("Revenue: ", style: TextStyle(fontSize: 11, color: Color(0xFF8E94A0))),
                                Text("₹${_selectedMonth == 'Aug' ? '4.8L' : '3.9L'}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(width: 12),
                                const Text("Expense: ", style: TextStyle(fontSize: 11, color: Color(0xFF8E94A0))),
                                Text("₹${_selectedMonth == 'Aug' ? '2.0L' : '1.7L'}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 3: Personal Trainers Carousel
            const Text(
              "Personal Trainer",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            // Trainers Grid View
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _state.trainers.where((t) => t.id != "none").length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final trainersList = _state.trainers.where((t) => t.id != "none").toList();
                  final t = trainersList[index];
                  final initials = t.name.split(" ").map((n) => n[0]).join("");
                  final studentCount = _state.students.where((s) => s.trainerId == t.id).length;
                  
                  return Container(
                    width: 250,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: limeColor,
                              foregroundColor: Colors.black,
                              radius: 20,
                              child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text(
                                    "Personal Trainer",
                                    style: TextStyle(fontSize: 11, color: Color(0xFF8E94A0)),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTrainerMiniStat("${studentCount}+", "Clients"),
                            _buildTrainerMiniStat("${t.yearsExperience}+", "Years Exp"),
                          ],
                        ),
                        Wrap(
                          spacing: 4,
                          children: t.tags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D222B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(fontSize: 9, color: Color(0xFF8E94A0), fontWeight: FontWeight.bold),
                            ),
                          )).toList(),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Section 4: All Members Directory
            Container(
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
                    "All Members Directory",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search members by name or email...",
                            hintStyle: const TextStyle(color: Color(0xFF5C626E), fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF5C626E), size: 20),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.2),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(99),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(99),
                              borderSide: const BorderSide(color: limeColor),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        dropdownColor: cardBg,
                        underline: Container(),
                        value: _sortFilter,
                        icon: const Icon(Icons.tune, color: limeColor, size: 18),
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: "all", child: Text("All Default")),
                          DropdownMenuItem(value: "expired", child: Text("Expired Soon")),
                          DropdownMenuItem(value: "age", child: Text("Age (Youngest)")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _sortFilter = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Directory list cards (ideal for mobile layout)
                  _buildMembersList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String trend,
    required bool isUp,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14171D),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: limeColor, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8E94A0), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isUp ? const Color(0x1122C55E) : const Color(0x11EF4444),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  ),
                ),
              )
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF5C626E)),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8E94A0), fontWeight: FontWeight.bold),
        )
      ],
    );
  }

  Widget _buildBarGroup(String month, double revFactor, double expFactor) {
    final isSelected = _selectedMonth == month;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMonth = month;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rev bar
              Container(
                width: 10,
                height: 100 * revFactor,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  gradient: LinearGradient(
                    colors: [
                      limeColor.withOpacity(isSelected ? 1.0 : 0.8),
                      limeColor.withOpacity(0.2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: isSelected ? [const BoxShadow(color: limeColor, blurRadius: 4)] : [],
                ),
              ),
              const SizedBox(width: 4),
              // Exp bar
              Container(
                width: 10,
                height: 100 * expFactor,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  gradient: LinearGradient(
                    colors: [
                      purpleColor.withOpacity(isSelected ? 1.0 : 0.8),
                      purpleColor.withOpacity(0.2),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: isSelected ? [const BoxShadow(color: purpleColor, blurRadius: 4)] : [],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            month,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? limeColor : const Color(0xFF5C626E),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrainerMiniStat(String val, String lbl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
        ),
        Text(
          lbl,
          style: const TextStyle(fontSize: 10, color: Color(0xFF5C626E), fontFamily: 'JetBrains Mono'),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    var list = [..._state.students];

    // Filter query
    if (_searchQuery.isNotEmpty) {
      list = list.where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()) || m.email.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sort query
    if (_sortFilter == "expired") {
      list.sort((a, b) => a.expiredDate.compareTo(b.expiredDate));
    } else if (_sortFilter == "age") {
      list.sort((a, b) => a.age.compareTo(b.age));
    }

    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          "No members match search query",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF5C626E), fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const Divider(color: borderColor, height: 24),
      itemBuilder: (context, index) {
        final m = list[index];
        final initials = m.name.split(" ").map((n) => n[0]).join("");
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF22262F),
              foregroundColor: Colors.white,
              radius: 18,
              child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        m.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: m.status == 'Active' ? const Color(0x1122C55E) : const Color(0x11EF4444),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: m.status == 'Active' ? const Color(0x3322C55E) : const Color(0x33EF4444)),
                        ),
                        child: Text(
                          m.status,
                          style: TextStyle(
                            fontSize: 8,
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.bold,
                            color: m.status == 'Active' ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${m.email} • Age: ${m.age}",
                    style: const TextStyle(fontSize: 11, color: Color(0xFF5C626E)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Trainer selector inline dropdown
            DropdownButton<String>(
              dropdownColor: const Color(0xFF14171D),
              underline: Container(),
              value: m.trainerId,
              style: const TextStyle(fontSize: 11, color: limeColor, fontWeight: FontWeight.bold),
              items: _state.trainers.map((t) => DropdownMenuItem(
                value: t.id,
                child: Text(t.name),
              )).toList(),
              onChanged: (newTrainerId) {
                if (newTrainerId != null) {
                  _state.assignTrainer(m.id, newTrainerId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Reassigned ${m.name} to ${_state.trainers.firstWhere((t) => t.id == newTrainerId).name}!")),
                  );
                }
              },
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Expires: ${m.expiredDate}",
                  style: const TextStyle(fontSize: 10, color: Color(0xFF5C626E), fontFamily: 'JetBrains Mono'),
                ),
                const SizedBox(height: 2),
                Text(
                  m.isCheckedIn ? "✅ Active inside" : m.lastVisited,
                  style: TextStyle(fontSize: 10, color: m.isCheckedIn ? limeColor : const Color(0xFF5C626E), fontWeight: m.isCheckedIn ? FontWeight.bold : FontWeight.normal),
                )
              ],
            )
          ],
        );
      },
    );
  }

  // Add Member form Dialog box Modal
  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final telController = TextEditingController();
    int age = 25;
    String trainerId = _state.trainers.first.id;
    String status = "Active";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF14171D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF22262F)),
              ),
              title: const Text(
                "Create Member Profile",
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        labelStyle: TextStyle(fontSize: 12, color: Color(0xFF8E94A0)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF22262F))),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: "Email Address",
                        labelStyle: TextStyle(fontSize: 12, color: Color(0xFF8E94A0)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF22262F))),
                      ),
                      style: const TextStyle(fontSize: 13),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: telController,
                      decoration: const InputDecoration(
                        labelText: "Telephone",
                        labelStyle: TextStyle(fontSize: 12, color: Color(0xFF8E94A0)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF22262F))),
                      ),
                      style: const TextStyle(fontSize: 13),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Age", style: TextStyle(fontSize: 12, color: Color(0xFF8E94A0))),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white70, size: 20),
                              onPressed: () {
                                if (age > 15) setModalState(() => age--);
                              },
                            ),
                            Text("$age", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 20),
                              onPressed: () {
                                if (age < 80) setModalState(() => age++);
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Assign Trainer",
                        labelStyle: TextStyle(fontSize: 12, color: Color(0xFF8E94A0)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF22262F))),
                      ),
                      dropdownColor: const Color(0xFF14171D),
                      value: trainerId,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      items: _state.trainers.map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.name),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => trainerId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Plan Status",
                        labelStyle: TextStyle(fontSize: 12, color: Color(0xFF8E94A0)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF22262F))),
                      ),
                      dropdownColor: const Color(0xFF14171D),
                      value: status,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: "Active", child: Text("Active Plan")),
                        DropdownMenuItem(value: "In Active", child: Text("Inactive Plan")),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => status = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Color(0xFF8E94A0))),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    final tel = telController.text.trim();
                    
                    if (name.isNotEmpty && email.isNotEmpty && tel.isNotEmpty) {
                      _state.addMember(
                        name: name,
                        email: email,
                        tel: tel,
                        age: age,
                        trainerId: trainerId,
                        status: status,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Successfully created membership for $name!")),
                      );
                    }
                  },
                  child: Text("Submit", style: const TextStyle(color: limeColor, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
