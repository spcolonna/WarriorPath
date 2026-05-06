import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';
import 'package:warrior_path/screens/student/edit_profile_screen.dart';
import 'package:warrior_path/screens/student/school_search_screen.dart';
import 'package:warrior_path/screens/wizard_create_school_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../parent/add_child_screen.dart';

class StudentProfileTabScreen extends StatefulWidget {
  final String memberId;
  const StudentProfileTabScreen({super.key, required this.memberId});

  @override
  State<StudentProfileTabScreen> createState() =>
      _StudentProfileTabScreenState();
}

class _StudentProfileTabScreenState extends State<StudentProfileTabScreen> {
  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late Future<Map<String, dynamic>?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.memberId)
        .get();
    if (!doc.exists) return null;
    return doc.data();
  }

  void _refresh() {
    setState(() {
      _userDataFuture = _fetchUserData();
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logOut),
        content: Text(l10n.logOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.logOut,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text(l10n.profileLoadedError));
          }

          final data = snapshot.data!;
          return _ProfileBody(
            data: data,
            memberId: widget.memberId,
            l10n: l10n,
            onEditTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      EditProfileScreen(memberId: widget.memberId),
                ),
              );
              if (changed == true) _refresh();
            },
            onLogout: _logout,
          );
        },
      ),
    );
  }
}

// ─── Body ────────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final String memberId;
  final AppLocalizations l10n;
  final VoidCallback onEditTap;
  final VoidCallback onLogout;

  const _ProfileBody({
    required this.data,
    required this.memberId,
    required this.l10n,
    required this.onEditTap,
    required this.onLogout,
  });

  String _formatGender(String? key, AppLocalizations l10n) {
    switch (key) {
      case 'male':
        return l10n.maleGender;
      case 'female':
        return l10n.femaleGender;
      case 'other':
        return l10n.otherGender;
      case 'prefers_not_to_say':
        return l10n.noSpecifyGender;
      default:
        return '—';
    }
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '—';
    final dt = (ts as Timestamp).toDate();
    return DateFormat('dd/MM/yyyy', 'es_ES').format(dt);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final name = data['displayName'] as String? ?? '';
    final email = data['email'] as String? ?? '';
    final phone = data['phoneNumber'] as String? ?? '';
    final gender = _formatGender(data['gender'] as String?, l10n);
    final dob = _formatDate(data['dateOfBirth']);
    final photoUrl = data['photoUrl'] as String?;

    final ecName = data['emergencyContactName'] as String? ?? '';
    final ecPhone = data['emergencyContactPhone'] as String? ?? '';
    final medService = data['medicalEmergencyService'] as String? ?? '';
    final medInfo = data['medicalInfo'] as String? ?? '';

    final bool hasAnyEmergencyInfo =
        ecName.isNotEmpty || ecPhone.isNotEmpty || medService.isNotEmpty || medInfo.isNotEmpty;

    return CustomScrollView(
      slivers: [
        // ── AppBar simple (sin solapamiento) ─────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: primary,
          title: Text(
            l10n.myProfile,
            style: const TextStyle(color: Colors.white),
          ),
        ),

        // ── Avatar card separado del AppBar ──────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primary, primary.withValues(alpha: 0.6)],
              ),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: primary.withValues(alpha: 0.85),
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            _initials(name),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Text(
                    l10n.studentRole,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Content ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Personal data ──────────────────────────────────────
                _SectionCard(
                  icon: Icons.person_outline,
                  title: l10n.myData,
                  children: [
                    _InfoTile(icon: Icons.badge_outlined, label: l10n.fullName, value: name.isEmpty ? '—' : name),
                    _InfoTile(icon: Icons.email_outlined, label: l10n.emailLabel, value: email.isEmpty ? '—' : email),
                    _InfoTile(icon: Icons.phone_outlined, label: l10n.phone, value: phone.isEmpty ? '—' : phone),
                    _InfoTile(icon: Icons.wc_outlined, label: l10n.gender, value: gender),
                    _InfoTile(icon: Icons.cake_outlined, label: l10n.birdthDate, value: dob),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Emergency info ─────────────────────────────────────
                _SectionCard(
                  icon: Icons.health_and_safety_outlined,
                  title: l10n.emergencyInfo,
                  children: hasAnyEmergencyInfo
                      ? [
                          if (ecName.isNotEmpty)
                            _InfoTile(icon: Icons.contact_emergency_outlined, label: l10n.emergencyContactName, value: ecName),
                          if (ecPhone.isNotEmpty)
                            _InfoTile(icon: Icons.phone_in_talk_outlined, label: l10n.emergencyContactPhone, value: ecPhone),
                          if (medService.isNotEmpty)
                            _InfoTile(icon: Icons.local_hospital_outlined, label: l10n.medicalEmergencyService, value: medService),
                          if (medInfo.isNotEmpty)
                            _InfoTile(icon: Icons.notes_outlined, label: l10n.relevantMedicalInfo, value: medInfo),
                        ]
                      : [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              l10n.emergencyInfoNotice,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ),
                        ],
                ),
                const SizedBox(height: 16),

                // ── Account actions ────────────────────────────────────
                _SectionCard(
                  icon: Icons.manage_accounts_outlined,
                  title: l10n.accountActions,
                  children: [
                    // Edit profile — primary action
                    _ActionTile(
                      icon: Icons.edit_outlined,
                      label: l10n.editProfile,
                      color: Theme.of(context).primaryColor,
                      onTap: onEditTap,
                    ),
                    _ActionTile(
                      icon: Icons.escalator_warning,
                      label: l10n.manageChildren,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddChildScreen()),
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.search,
                      label: l10n.enrollInAnotherSchool,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SchoolSearchScreen()),
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.add_business,
                      label: l10n.createNewSchool,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WizardCreateSchoolScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Logout ─────────────────────────────────────────────
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    l10n.logOut,
                    style: const TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onLogout,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ─── Info tile (read-only) ────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action tile ──────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tileColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: tileColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
