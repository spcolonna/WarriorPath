import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:warrior_path/models/discipline_model.dart';
import 'package:warrior_path/screens/teacher/progress_discipline_tab.dart';
import '../../l10n/app_localizations.dart';
import '../../models/payment_plan_model.dart';
import '../../widgets/register_payment_dialog.dart';

class StudentDetailScreen extends StatefulWidget {
  final String schoolId;
  final String studentId;

  const StudentDetailScreen({
    super.key,
    required this.schoolId,
    required this.studentId,
  });

  @override
  _StudentDetailScreenState createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> with TickerProviderStateMixin {
  late AppLocalizations l10n;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  late TabController _tabController;
  late ConfettiController _confettiController;
  StreamSubscription? _memberSubscription;

  bool _isLoading = true;
  String _studentName = '';
  String? _photoUrl;
  String _currentRole = '';

  Map<String, dynamic> _memberProgress = {};
  List<DisciplineModel> _enrolledDisciplines = [];
  final int _staticTabsCount = 3;

  String? _assignedPaymentPlanId;
  bool _isOwnerViewing = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _tabController = TabController(length: _staticTabsCount, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    final schoolDoc = await firestore.collection('schools').doc(widget.schoolId).get();
    if (schoolDoc.exists) {
      final schoolOwnerId = schoolDoc.data()?['ownerId'];
      if (mounted) {
        setState(() {
          _isOwnerViewing = (currentUser?.uid == schoolOwnerId);
        });
      }
    }

    final userDoc = await firestore.collection('users').doc(widget.studentId).get();
    if (userDoc.exists && mounted) {
      setState(() {
        _studentName = userDoc.data()?['displayName'] ?? '';
        _photoUrl = userDoc.data()?['photoUrl'];
      });
    }

    _memberSubscription?.cancel();
    _memberSubscription = FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('members').doc(widget.studentId)
        .snapshots()
        .listen((memberSnapshot) async {
      if (!memberSnapshot.exists || !mounted) {
        setState(() => _isLoading = false);
        return;
      }

      final memberData = memberSnapshot.data()!;
      _currentRole = memberData['role'] ?? 'alumno';
      _memberProgress = memberData['progress'] as Map<String, dynamic>? ?? {};
      _assignedPaymentPlanId = memberData['assignedPaymentPlanId'] as String?;
      final enrolledDisciplineIds = _memberProgress.keys.toList();

      if (enrolledDisciplineIds.isNotEmpty) {
        final disciplinesSnapshot = await FirebaseFirestore.instance
            .collection('schools').doc(widget.schoolId)
            .collection('disciplines')
            .where(FieldPath.documentId, whereIn: enrolledDisciplineIds)
            .get();
        _enrolledDisciplines = disciplinesSnapshot.docs.map((doc) => DisciplineModel.fromFirestore(doc)).toList();
      } else {
        _enrolledDisciplines = [];
      }

      if (mounted) {
        int staticTabs = 1;
        if (_isOwnerViewing) {
          staticTabs += 2;
        }
        int totalTabs = staticTabs + _enrolledDisciplines.length;
        if (_enrolledDisciplines.isEmpty) {
          totalTabs++;
        }

        final currentTabIndex = _tabController.index;
        _tabController.dispose();
        _tabController = TabController(length: totalTabs, vsync: this, initialIndex: currentTabIndex.clamp(0, totalTabs > 0 ? totalTabs - 1 : 0));
        _tabController.addListener(() => setState(() {}));
        setState(() { _isLoading = false; });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    _memberSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(l10n.loading)));
    }

    final List<Tab> tabs = [
      Tab(text: l10n.general),
      if (_isOwnerViewing) Tab(text: l10n.assistance),
      if (_isOwnerViewing) Tab(text: l10n.payments),
      ..._enrolledDisciplines.map((d) => Tab(text: l10n.progressFor(d.name))),
    ];

    final List<Widget> tabViews = [
      _buildGeneralInfoTab(),
      if (_isOwnerViewing) _buildAttendanceHistoryTab(),
      if (_isOwnerViewing) _buildPaymentsHistoryTab(),
      ..._enrolledDisciplines.map((d) => ProgressDisciplineTab(
        schoolId: widget.schoolId,
        studentId: widget.studentId,
        discipline: d,
        studentProgress: _memberProgress[d.id] as Map<String, dynamic>? ?? {},
        confettiController: _confettiController,
        isOwnerViewing: _isOwnerViewing,
      )),
    ];

    if (_enrolledDisciplines.isEmpty) {
      tabs.add(Tab(text: l10n.progress));
      tabViews.add(Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text(l10n.noDisciplinesEnrolled, textAlign: TextAlign.center))));
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          appBar: AppBar(title: Text(_studentName)),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(children: [
                  CircleAvatar(radius: 40, backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty) ? NetworkImage(_photoUrl!) : null, child: (_photoUrl == null || _photoUrl!.isEmpty) ? const Icon(Icons.person, size: 40) : null),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_studentName, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(_currentRole.toUpperCase(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                  ]),
                ]),
              ),
              TabBar(controller: _tabController, isScrollable: true, tabs: tabs),
              Expanded(child: TabBarView(controller: _tabController, children: tabViews)),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
        ),
        ConfettiWidget(confettiController: _confettiController, blastDirectionality: BlastDirectionality.explosive),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    if (!_isOwnerViewing) {
      return null;
    }

    switch (_tabController.index) {
      case 1: // Pestaña de Asistencia
        return FloatingActionButton.extended(
          onPressed: () => _showAddPastAttendanceDialog(),
          label: Text(l10n.registerPausedAssistance),
          icon: const Icon(Icons.playlist_add_check),
        );
      case 2: // Pestaña de Pagos
        return FloatingActionButton.extended(
          onPressed: () => _showRegisterPaymentDialog(),
          label: Text(l10n.registerPayment),
          icon: const Icon(Icons.payment),
        );
      default:
      // Si no hay disciplinas o estamos en una pestaña de progreso
        if (_enrolledDisciplines.isEmpty || _tabController.index >= _staticTabsCount) {
          return FloatingActionButton.extended(
            onPressed: () => _showEnrollInDisciplineDialog(),
            label: Text(l10n.enrollInDisciplines),
            icon: const Icon(Icons.add),
          );
        }
        return null;
    }
  }

  Future<void> _showAddPastAttendanceDialog() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (pickedDate == null) return;
    final int dayOfWeek = pickedDate.weekday;
    final schedulesSnap = await FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('classSchedules').where('dayOfWeek', isEqualTo: dayOfWeek).get();
    if (schedulesSnap.docs.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noClassForTHisDay)));
      return;
    }
    if (mounted) _selectScheduleForDate(schedulesSnap.docs, pickedDate);
  }

  void _selectScheduleForDate(List<QueryDocumentSnapshot> schedules, DateTime selectedDate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.classFor(DateFormat.yMd('es_ES').format(selectedDate))),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index].data() as Map<String, dynamic>;
              final scheduleTitle = schedule['title'];
              final scheduleTime = '${schedule['startTime']} - ${schedule['endTime']}';
              return ListTile(
                title: Text(scheduleTitle),
                subtitle: Text(scheduleTime),
                onTap: () {
                  _savePastAttendance(scheduleTitle, selectedDate);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _savePastAttendance(String scheduleTitle, DateTime date) async {
    final normalizedDate = Timestamp.fromDate(DateTime(date.year, date.month, date.day));
    final firestore = FirebaseFirestore.instance;
    final recordsRef = firestore.collection('schools').doc(widget.schoolId).collection('attendanceRecords');
    try {
      final query = await recordsRef.where('date', isEqualTo: normalizedDate).where('scheduleTitle', isEqualTo: scheduleTitle).limit(1).get();
      if (query.docs.isEmpty) {
        await recordsRef.add({
          'date': normalizedDate,
          'scheduleTitle': scheduleTitle,
          'schoolId': widget.schoolId,
          'presentStudentIds': [widget.studentId],
          'recordedBy': FirebaseAuth.instance.currentUser?.uid,
        });
      } else {
        await recordsRef.doc(query.docs.first.id).update({
          'presentStudentIds': FieldValue.arrayUnion([widget.studentId])
        });
      }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.successAssistance)));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    }
  }

  Widget _buildGeneralInfoTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.studentId).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final String? gender = userData['gender'];
        final DateTime? dateOfBirth = (userData['dateOfBirth'] as Timestamp?)?.toDate();
        final String formattedDob = dateOfBirth != null ? DateFormat('dd/MM/yyyy', 'es_ES').format(dateOfBirth) : l10n.noSpecify;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            if (_isOwnerViewing) ...[
              _buildInfoCard(
                title: l10n.facturation,
                icon: Icons.receipt_long,
                iconColor: Colors.blueAccent,
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: _assignedPaymentPlanId == null
                        ? null
                        : FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('paymentPlans').doc(_assignedPaymentPlanId).get(),
                    builder: (context, planSnapshot) {
                      String planDetailsText = l10n.notassignedPaymentPlan;
                      if (planSnapshot.connectionState == ConnectionState.waiting) {
                        planDetailsText = l10n.loading;
                      } else if (planSnapshot.hasData && planSnapshot.data!.exists) {
                        final plan = PaymentPlanModel.fromFirestore(planSnapshot.data!);
                        planDetailsText = '${plan.title} (${plan.amount} ${plan.currency})';
                      } else if (_assignedPaymentPlanId != null) {
                        planDetailsText = l10n.paymentPlanNotFoud(_assignedPaymentPlanId!);
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(planDetailsText, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton(
                              child: Text(l10n.changeAssignedPlan),
                              onPressed: () => _showAssignPlanDialog(),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildInfoCard(title: l10n.personalData, icon: Icons.badge_outlined, iconColor: Colors.teal, children: [
              _buildInfoRow("${l10n.birdthDate}:", '$formattedDob${_calculateAge(dateOfBirth)}'),
              _buildInfoRow("${l10n.gender}:", _formatGender(gender)),
            ]),
            if (_isOwnerViewing) ...[
              const SizedBox(height: 16),
              _buildInfoCard(title: l10n.contactData, icon: Icons.contact_page, children: [
                _buildInfoRow('Email:', userData['email'] ?? l10n.noSpecify),
                _buildInfoRow('${l10n.phone}:', userData['phoneNumber'] ?? l10n.noSpecify),
              ]),
              const SizedBox(height: 16),
              _buildInfoCard(title: l10n.emergencyInfo, icon: Icons.emergency, iconColor: Colors.red, children: [
                _buildInfoRow('${l10n.contact}:', userData['emergencyContactName'] ?? l10n.noSpecify),
                _buildInfoRow('${l10n.phone}:', userData['emergencyContactPhone'] ?? l10n.noSpecify),
                _buildInfoRow('${l10n.medService}:', userData['medicalEmergencyService'] ?? l10n.noSpecify),
                const Divider(),
                _buildInfoRow('${l10n.medInfo}:', userData['medicalInfo'] ?? l10n.noSpecify),
              ])
            ],
          ]),
        );
      },
    );
  }

  Future<void> _showAssignPlanDialog() async {
    final firestore = FirebaseFirestore.instance;
    final plansSnapshot = await firestore.collection('schools').doc(widget.schoolId).collection('paymentPlans').get();
    final allPlans = plansSnapshot.docs.map((doc) => PaymentPlanModel.fromFirestore(doc)).toList();

    PaymentPlanModel? selectedPlan;
    if (_assignedPaymentPlanId != null && allPlans.any((p) => p.id == _assignedPaymentPlanId)) {
      selectedPlan = allPlans.firstWhere((p) => p.id == _assignedPaymentPlanId);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.assignPlan),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<PaymentPlanModel>(
                  value: selectedPlan,
                  hint: Text(l10n.selectPlan),
                  items: allPlans.map((plan) => DropdownMenuItem(value: plan, child: Text('${plan.title} (${plan.amount} ${plan.currency})'))).toList(),
                  onChanged: (plan) => setDialogState(() => selectedPlan = plan),
                ),
                const SizedBox(height: 16),
                TextButton(
                  child: Text(l10n.removeAssignedPlan, style: const TextStyle(color: Colors.red)),
                  onPressed: () {
                    firestore.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).update({'assignedPaymentPlanId': null});
                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: selectedPlan == null ? null : () {
                  firestore.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).update({'assignedPaymentPlanId': selectedPlan!.id});
                  Navigator.of(context).pop();
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAttendanceHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('attendanceRecords').where('presentStudentIds', arrayContains: widget.studentId).orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text(l10n.noRegisterAssitance));
        return ListView.builder(itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
          final doc = snapshot.data!.docs[index];
          final record = doc.data() as Map<String, dynamic>;
          final date = (record['date'] as Timestamp).toDate();
          final formattedDate = DateFormat('dd/MM/yyyy', 'es_ES').format(date);
          return ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(record['scheduleTitle'] ?? l10n.classRoom),
            subtitle: Text(formattedDate),
          );
        });
      },
    );
  }

  Widget _buildPaymentsHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).collection('payments').orderBy('paymentDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text(l10n.noPayment));
        return ListView.builder(itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
          final payment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
          final date = (payment['paymentDate'] as Timestamp).toDate();
          final formattedDate = DateFormat('dd/MM/yyyy').format(date);
          return ListTile(leading: const Icon(Icons.receipt_long, color: Colors.green), title: Text(payment['concept'] ?? l10n.payment), subtitle: Text(formattedDate), trailing: Text('${payment['amount']} ${payment['currency']}', style: const TextStyle(fontWeight: FontWeight.bold)));
        });
      },
    );
  }

  Future<void> _showRegisterPaymentDialog() async {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).get(),
      firestore.collection('schools').doc(widget.schoolId).collection('paymentPlans').get(),
      firestore.collection('schools').doc(widget.schoolId).get(),
    ]);

    final memberDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final plansSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final schoolDoc = results[2] as DocumentSnapshot<Map<String, dynamic>>;

    final allPlans = plansSnapshot.docs.map((doc) => PaymentPlanModel.fromFirestore(doc)).toList();
    final assignedPlanId = memberDoc.data()?['paymentPlanId'] as String?;
    final currency = (schoolDoc.data()?['financials'] as Map<String, dynamic>?)?['currency'] ?? 'USD';

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return RegisterPaymentDialog(
            allPlans: allPlans,
            assignedPlanId: assignedPlanId,
            currency: currency,
            onSave: (String concept, double amount, String? planId) {
              _savePayment(
                concept: concept,
                amount: amount,
                currency: currency,
                planId: planId,
                l10n: l10n,
              );
            },
          );
        },
      );
    }
  }

  Future<void> _savePayment({
    required String concept,
    required double amount,
    required String currency,
    String? planId,
    required AppLocalizations l10n,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('schools').doc(widget.schoolId)
          .collection('members').doc(widget.studentId)
          .collection('payments').add({
        'paymentDate': Timestamp.now(),
        'concept': concept.trim(),
        'amount': amount,
        'currency': currency,
        'recordedBy': FirebaseAuth.instance.currentUser?.uid,
        'schoolId': widget.schoolId,
        'paymentPlanId': planId,
        'studentId': widget.studentId,
        'studentName': _studentName,
      });

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.successPayment), backgroundColor: Colors.green));

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.paymentError(e.toString()))));
    }
  }

  Future<void> _showEnrollInDisciplineDialog() async {
    final firestore = FirebaseFirestore.instance;

    // 1. Buscamos TODAS las disciplinas activas de la escuela
    final allDisciplinesSnap = await firestore
        .collection('schools').doc(widget.schoolId)
        .collection('disciplines').where('isActive', isEqualTo: true).get();

    // 2. Filtramos para quedarnos solo con las que el alumno NO está inscrito
    final enrolledIds = _memberProgress.keys.toSet();
    final availableDisciplines = allDisciplinesSnap.docs
        .where((doc) => !enrolledIds.contains(doc.id))
        .toList();

    if (availableDisciplines.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este alumno ya está inscrito en todas las disciplinas disponibles.'))
      );
      return;
    }

    // 3. Mostramos el diálogo con las disciplinas disponibles
    final selectedDiscipline = await showDialog<DocumentSnapshot>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.enrollInDiscipline),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableDisciplines.length,
            itemBuilder: (context, index) {
              final doc = availableDisciplines[index];
              return ListTile(
                title: Text(doc['name']),
                onTap: () => Navigator.of(ctx).pop(doc),
              );
            },
          ),
        ),
      ),
    );

    if (selectedDiscipline != null && mounted) {
      // 4. Si se seleccionó una, procedemos a inscribir al alumno
      try {
        final levelsQuery = await selectedDiscipline.reference
            .collection('levels').orderBy('order').limit(1).get();

        if (levelsQuery.docs.isEmpty) {
          throw Exception('La disciplina seleccionada no tiene niveles configurados.');
        }
        final initialLevelId = levelsQuery.docs.first.id;

        // Usamos notación de punto para añadir un nuevo campo al mapa 'progress'
        await firestore.collection('schools').doc(widget.schoolId).collection('members').doc(widget.studentId).update({
          'progress.${selectedDiscipline.id}': {
            'currentLevelId': initialLevelId,
            'enrollmentDate': FieldValue.serverTimestamp(),
            'assignedTechniqueIds': [],
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alumno inscrito en ${selectedDiscipline['name']} con éxito.'), backgroundColor: Colors.green),
        );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al inscribir: ${e.toString()}'))
        );
        }
      }
    }
  }

  String _formatGender(String? genderValue) {
    if (genderValue == null || genderValue.isEmpty) return l10n.noSpecify;
    switch (genderValue) {
      case 'masculino': return l10n.maleGender;
      case 'femenino': return l10n.femaleGender;
      case 'otro': return l10n.otherGender;
      case 'prefiero_no_decirlo': return l10n.noSpecifyGender;
      default: return genderValue;
    }
  }

  String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return '';
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return ' ($age ${l10n.years})';
  }

  Widget _buildInfoCard({required String title, required IconData icon, Color? iconColor, required List<Widget> children}) {
    return Card(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [ Icon(icon, color: iconColor ?? Theme.of(context).primaryColor), const SizedBox(width: 8), Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis, maxLines: 2))]),
      const Divider(height: 20), ...children])));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8),
      Expanded(child: Text(value.isEmpty ? l10n.noSpecify : value)),
    ]));
  }
}
