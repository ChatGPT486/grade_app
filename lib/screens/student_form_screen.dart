import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/student_record.dart';
import '../services/supabase_service.dart';

class StudentFormScreen extends StatefulWidget {
  final StudentRecord? student; // null = add mode
  const StudentFormScreen({super.key, this.student});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = SupabaseService();

  late TextEditingController _name;
  late TextEditingController _matricule;
  late TextEditingController _email;
  late TextEditingController _course;
  late TextEditingController _ca1;
  late TextEditingController _ca2;
  late TextEditingController _exam;

  bool _loading = false;
  bool get _isEdit => widget.student != null;

  // Live preview values
  double _previewCa1 = 0, _previewCa2 = 0, _previewExam = 0;

 // In your StudentFormScreen, ensure you're handling null properly
@override
void initState() {
  super.initState();
  final s = widget.student;
  _name = TextEditingController(text: s?.name ?? '');
  _matricule = TextEditingController(text: s?.matricule ?? '');
  _email = TextEditingController(text: s?.email ?? '');
  _course = TextEditingController(text: s?.course ?? '');
  _ca1 = TextEditingController(text: s != null ? s.ca1.toStringAsFixed(0) : '');
  _ca2 = TextEditingController(text: s != null ? s.ca2.toStringAsFixed(0) : '');
  _exam = TextEditingController(text: s != null ? s.exam.toStringAsFixed(0) : '');
  _previewCa1 = s?.ca1 ?? 0;
  _previewCa2 = s?.ca2 ?? 0;
  _previewExam = s?.exam ?? 0;
}

  @override
  void dispose() {
    // Remove listeners
    _ca1.removeListener(_updatePreview);
    _ca2.removeListener(_updatePreview);
    _exam.removeListener(_updatePreview);
    
    for (final c in [_name, _matricule, _email, _course, _ca1, _ca2, _exam]) {
      c.dispose();
    }
    super.dispose();
  }

  void _updatePreview() {
    setState(() {
      _previewCa1 = double.tryParse(_ca1.text) ?? 0;
      _previewCa2 = double.tryParse(_ca2.text) ?? 0;
      _previewExam = double.tryParse(_exam.text) ?? 0;
    });
  }

  double get _previewTotal => _previewCa1 + _previewCa2 + _previewExam;

  Future<void> _submit() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      _showError('Please fix the validation errors');
      return;
    }
    
    setState(() => _loading = true);

    try {
      // Check duplicate matricule (skip if editing same record)
      final exists = await _db.matriculeExists(
        _matricule.text.trim(),
        excludeId: widget.student?.id,
      );
      if (exists) {
        _showError('Matricule already exists in the database.');
        setState(() => _loading = false);
        return;
      }

      // Parse marks safely
      final ca1Value = double.tryParse(_ca1.text) ?? 0;
      final ca2Value = double.tryParse(_ca2.text) ?? 0;
      final examValue = double.tryParse(_exam.text) ?? 0;

      final record = StudentRecord(
        id: widget.student?.id,
        name: _name.text.trim(),
        matricule: _matricule.text.trim().toUpperCase(),
        email: _email.text.trim().toLowerCase(),
        course: _course.text.trim(),
        ca1: ca1Value,
        ca2: ca2Value,
        exam: examValue,
      );

      if (_isEdit) {
        await _db.update(record);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student updated successfully!'), backgroundColor: Colors.green),
          );
        }
      } else {
        await _db.insert(record);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student added successfully!'), backgroundColor: Colors.green),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error in _submit: $e'); // Add logging for debugging
      _showError('Error: ${e.toString()}');
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final total = _previewTotal;
    final gpa = StudentRecord.percentageToGpa(total);
    final letter = StudentRecord.gpaToLetter(gpa);
    final passing = total >= 40;
    final gradeColor = passing ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        title: Text(_isEdit ? 'Edit Student' : 'Add Student'),
        actions: [
          // Save button in AppBar
          TextButton(
            onPressed: _loading ? null : _submit, // Disable when loading
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    children: [
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 4),
                      Text('Save'),
                    ],
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Student Info ──
              _sectionCard(
                context,
                title: 'Student Information',
                icon: Icons.person_outline,
                children: [
                  _field(
                    controller: _name,
                    label: 'Full Name',
                    hint: 'e.g. Lorelle Mballa',
                    icon: Icons.badge_outlined,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _matricule,
                    label: 'Matricule',
                    hint: 'e.g. ICTU20241934',
                    icon: Icons.numbers,
                    caps: TextCapitalization.characters,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Matricule is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _email,
                    label: 'Email',
                    hint: 'lorelle.mballa@ictuniversity.edu.cm',
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      final regex = RegExp(
                          r'^[a-zA-Z0-9][a-zA-Z0-9._\-]*@ictuniversity\.edu\.cm$');
                      if (!regex.hasMatch(v.trim().toLowerCase())) {
                        return 'Must end with @ictuniversity.edu.cm';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _course,
                    label: 'Course',
                    hint: 'e.g. Software Engineering',
                    icon: Icons.school_outlined,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Course is required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Marks ──
              _sectionCard(
                context,
                title: 'Assessment Marks',
                icon: Icons.grading,
                subtitle: 'CA1 (/20) + CA2 (/10) + Exam (/70) = Total (/100)',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _markField(
                          controller: _ca1,
                          label: 'CA1',
                          sublabel: '(/20)',
                          maxValue: 20,
                          color: Colors.blue,
                          onChanged: (_) => _updatePreview(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _markField(
                          controller: _ca2,
                          label: 'CA2',
                          sublabel: '(/10)',
                          maxValue: 10,
                          color: Colors.indigo,
                          onChanged: (_) => _updatePreview(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _markField(
                          controller: _exam,
                          label: 'Exam',
                          sublabel: '(/70)',
                          maxValue: 70,
                          color: Colors.deepPurple,
                          onChanged: (_) => _updatePreview(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Live Preview ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: gradeColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gradeColor.withAlpha(80)),
                ),
                child: Column(
                  children: [
                    Text('Live Grade Preview',
                        style: TextStyle(
                            color: colors.onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _previewItem('Total', '${total.toStringAsFixed(2)}/100',
                            Colors.blueGrey),
                        _previewItem('GPA', gpa.toStringAsFixed(1), gradeColor),
                        _previewItem('Grade', letter, gradeColor),
                        _previewItem(
                            'Status', passing ? 'PASS' : 'FAIL', gradeColor),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Mark breakdown bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: (_previewCa1 * 15).round(),
                            child: Container(height: 8, color: Colors.blue),
                          ),
                          Expanded(
                            flex: (_previewCa2 * 15).round(),
                            child: Container(height: 8, color: Colors.indigo),
                          ),
                          Expanded(
                            flex: (_previewExam * 70).round(),
                            child: Container(height: 8, color: Colors.deepPurple),
                          ),
                          Expanded(
                            flex: (10000 - (_previewCa1 * 15).round() -
                                    (_previewCa2 * 15).round() -
                                    (_previewExam * 70).round())
                                .clamp(0, 10000),
                            child: Container(
                                height: 8, color: colors.outlineVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _barLegend(Colors.blue, 'CA1'),
                        const SizedBox(width: 12),
                        _barLegend(Colors.indigo, 'CA2'),
                        const SizedBox(width: 12),
                        _barLegend(Colors.deepPurple, 'Exam'),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Add a floating save button at the bottom for better UX
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('SAVE STUDENT', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context,
      {required String title,
      required IconData icon,
      String? subtitle,
      required List<Widget> children}) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: colors.primary)),
            ]),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle,
                  style:
                      TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
            ],
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.words,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: caps,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _markField({
    required TextEditingController controller,
    required String label,
    required String sublabel,
    required Color color,
    required ValueChanged<String> onChanged,
    required double maxValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: '$label ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13)),
              TextSpan(
                  text: sublabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,1})?')),
          ],
          onChanged: onChanged,
          textAlign: TextAlign.center,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            final val = double.tryParse(v);
            if (val == null || val < 0 || val > maxValue) {
              return '0-${maxValue.toInt()}';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: '0-${maxValue.toInt()}',
            border: OutlineInputBorder(
                borderSide: BorderSide(color: color)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: color, width: 2)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _previewItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _barLegend(Color color, String label) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]);
  }
}