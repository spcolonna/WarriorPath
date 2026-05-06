import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  final String memberId;

  const EditProfileScreen({super.key, required this.memberId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late AppLocalizations l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l10n = AppLocalizations.of(context);
  }

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _medicalEmergencyServiceController = TextEditingController();
  final _medicalInfoController = TextEditingController();

  String? _selectedSex;
  DateTime? _selectedDateOfBirth;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _medicalEmergencyServiceController.dispose();
    _medicalInfoController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .get();
      if (!doc.exists || !mounted) return;
      final data = doc.data()!;
      _nameController.text = data['displayName'] ?? '';
      _phoneController.text = data['phoneNumber'] ?? '';
      _emergencyContactNameController.text = data['emergencyContactName'] ?? '';
      _emergencyContactPhoneController.text =
          data['emergencyContactPhone'] ?? '';
      _medicalEmergencyServiceController.text =
          data['medicalEmergencyService'] ?? '';
      _medicalInfoController.text = data['medicalInfo'] ?? '';
      _selectedSex = data['gender'];
      _selectedDateOfBirth = (data['dateOfBirth'] as Timestamp?)?.toDate();
      if (_selectedDateOfBirth != null) {
        _dobController.text =
            DateFormat('dd/MM/yyyy', 'es_ES').format(_selectedDateOfBirth!);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text =
            DateFormat('dd/MM/yyyy', 'es_ES').format(picked);
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.memberId)
          .update({
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'gender': _selectedSex,
        'dateOfBirth': _selectedDateOfBirth != null
            ? Timestamp.fromDate(_selectedDateOfBirth!)
            : null,
        'emergencyContactName': _emergencyContactNameController.text.trim(),
        'emergencyContactPhone': _emergencyContactPhoneController.text.trim(),
        'medicalEmergencyService':
            _medicalEmergencyServiceController.text.trim(),
        'medicalInfo': _medicalInfoController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileUpdatedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // true = cambios guardados
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdateError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myProfile)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _isSaving,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Datos personales ──────────────────────────────
                    _SectionHeader(icon: Icons.person_outline, label: l10n.myData),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.fullName,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.phone,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildGenderDropdown(),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _selectDateOfBirth,
                      decoration: InputDecoration(
                        labelText: l10n.birdthDate,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.cake_outlined),
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Info de emergencia ────────────────────────────
                    _SectionHeader(
                        icon: Icons.health_and_safety_outlined,
                        label: l10n.emergencyInfo),
                    const SizedBox(height: 6),
                    Text(l10n.emergencyInfoNotice,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emergencyContactNameController,
                      decoration: InputDecoration(
                        labelText: l10n.emergencyContactName,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.contact_emergency_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emergencyContactPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.emergencyContactPhone,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone_in_talk_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _medicalEmergencyServiceController,
                      decoration: InputDecoration(
                        labelText: l10n.medicalEmergencyService,
                        hintText: l10n.medicalServiceExample,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.local_hospital_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _medicalInfoController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l10n.relevantMedicalInfo,
                        hintText: l10n.medicalInfoExample,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Guardar ───────────────────────────────────────
                    if (_isSaving)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_outlined),
                        label: Text(l10n.saveChanges),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _save,
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGenderDropdown() {
    final options = {
      'male': l10n.maleGender,
      'female': l10n.femaleGender,
      'other': l10n.otherGender,
      'prefers_not_to_say': l10n.noSpecifyGender,
    };
    final isValid =
        _selectedSex != null && options.containsKey(_selectedSex);

    return DropdownButtonFormField<String>(
      initialValue: isValid ? _selectedSex : null,
      decoration: InputDecoration(
        labelText: l10n.gender,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.wc_outlined),
      ),
      items: options.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => setState(() => _selectedSex = v),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }
}
