import 'package:flutter/material.dart';
import '../models/student_record.dart';
import '../services/supabase_service.dart';
import '../services/excel_service.dart';
import 'student_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _db = SupabaseService();
  List<StudentRecord> _students = [];
  List<String> _courses = [];
  bool _loading = true;
  bool _exporting = false;
  TabController? _tabController;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

 Future<void> _load() async {
  setState(() => _loading = true);
  try {
    final students = await _db.fetchAll();
    final courses = students.map((s) => s.course).toSet().toList()..sort();
    
    // Dispose old controller before creating new one
    _tabController?.dispose();
    
    // Create new controller
    _tabController = TabController(
      length: courses.length + 1, 
      vsync: this,
      initialIndex: 0, // Add initial index
    );
    
    setState(() {
      _students = students;
      _courses = courses;
      _loading = false;
    });
  } catch (e) {
    setState(() => _loading = false);
    _showError('Failed to load: $e');
  }
}

 Future<void> _export() async {
  if (_students.isEmpty) {
    _showError('No students to export.');
    return;
  }
  
  setState(() => _exporting = true);
  
  try {
    final path = await ExcelService.exportByCourse(_students);
    
    if (mounted) {
      // Show success with file location
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ File saved successfully!'),
              Text(
                'Location: ${path.split('/').last}',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                'Check your Downloads folder',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    _showError('Export failed: ${e.toString()}');
  } finally {
    if (mounted) setState(() => _exporting = false);
  }
}
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _deleteStudent(StudentRecord s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Remove ${s.name} from ${s.course}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _db.delete(s.id!);
      _load();
    }
  }

  List<StudentRecord> _filtered(List<StudentRecord> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.matricule.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q))
        .toList();
  }

 @override
Widget build(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  final passing = _students.where((s) => s.isPassing).length;
  final avgGpa = _students.isEmpty
      ? 0.0
      : _students.map((s) => s.gpa).reduce((a, b) => a + b) /
          _students.length;

  return Scaffold(
    backgroundColor: colors.surface,
    appBar: AppBar(
      backgroundColor: colors.primary,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/ict_logo.png',
              width: 38,
              height: 38,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 38,
                  height: 38,
                  color: Colors.white,
                  child: Icon(Icons.school, color: colors.primary),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ICT University',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              Text('Grade Management',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _load,
        ),
        if (_exporting)
          const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)),
          )
        else
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
            onPressed: _export,
          ),
      ],
      bottom: _loading || _courses.isEmpty || _tabController == null
          ? null
          : TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                const Tab(text: 'All'),
                ..._courses.map((c) => Tab(text: c)),
              ],
            ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Stats banner
              if (_students.isNotEmpty)
                Container(
                  color: colors.primaryContainer,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('Students', '${_students.length}', colors),
                      _stat('Courses', '${_courses.length}', colors),
                      _stat('Class GPA', avgGpa.toStringAsFixed(2), colors),
                      _stat('Passing', '$passing', colors, color: Colors.green),
                      _stat('Failing', '${_students.length - passing}',
                          colors,
                          color: _students.length - passing > 0
                              ? Colors.red
                              : null),
                    ],
                  ),
                ),

              // Search bar
              if (_students.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name, matricule or email…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              })
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30)),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

              // Content
              Expanded(
                child: _students.isEmpty
                    ? _emptyState(colors)
                    : _courses.isEmpty
                        ? _emptyState(colors)
                        : _tabController == null
                            ? const Center(child: CircularProgressIndicator())
                            : TabBarView(
                                controller: _tabController,
                                children: [
                                  // All students tab
                                  _studentList(_filtered(_students), colors),
                                  // Per-course tabs
                                  ..._courses.map((course) {
                                    final courseStudents = _filtered(_students
                                        .where((s) => s.course == course)
                                        .toList());
                                    return _studentList(
                                        courseStudents, colors,
                                        course: course);
                                  }),
                                ],
                              ),
              ),
            ],
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => const StudentFormScreen()),
        );
        if (result == true) _load();
      },
      backgroundColor: colors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.person_add),
      label: const Text('Add Student'),
    ),
  );
}

  Widget _studentList(List<StudentRecord> list, ColorScheme colors,
      {String? course}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: colors.outlineVariant),
            const SizedBox(height: 12),
            Text(
                _searchQuery.isNotEmpty
                    ? 'No results for "$_searchQuery"'
                    : 'No students${course != null ? ' in $course' : ''}',
                style:
                    TextStyle(color: colors.onSurfaceVariant, fontSize: 16)),
          ],
        ),
      );
    }

    // Sort by total mark descending for ranking
    final sorted = [...list]
      ..sort((a, b) => b.totalMark.compareTo(a.totalMark));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _StudentCard(
        student: sorted[i],
        rank: i + 1,
        onEdit: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    StudentFormScreen(student: sorted[i])),
          );
          if (result == true) _load();
        },
        onDelete: () => _deleteStudent(sorted[i]),
      ),
    );
  }

  Widget _stat(String label, String value, ColorScheme colors, {Color? color}) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color ?? colors.onPrimaryContainer)),
        Text(label,
            style:
                TextStyle(fontSize: 10, color: colors.onPrimaryContainer)),
      ],
    );
  }

  Widget _emptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: colors.outlineVariant),
          const SizedBox(height: 16),
          Text('No students yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Tap "Add Student" to get started',
              style: TextStyle(color: colors.outline)),
        ],
      ),
    );
  }
}

// In your _StudentCard widget, update the onTap and navigation
class _StudentCard extends StatelessWidget {
  final StudentRecord student;
  final int rank;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCard({
    required this.student,
    required this.rank,
    required this.onEdit,
    required this.onDelete,
  });

  Color _gradeColor(double total) {
    if (total >= 70) return Colors.green;
    if (total >= 55) return Colors.orange;
    if (total >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final total = student.totalMark;
    final gc = _gradeColor(total);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onEdit, // Use the callback directly
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$rank',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: colors.onPrimaryContainer)),
                ),
              ),
              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      '${student.matricule}  •  ${student.course}',
                      style: TextStyle(
                          fontSize: 11, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(student.email,
                        style: TextStyle(
                            fontSize: 11,
                            color: colors.primary,
                            decoration: TextDecoration.underline)),
                    const SizedBox(height: 4),
                    // Mark pills
                    Wrap(
                      spacing: 6,
                      children: [
                        _pill('CA1: ${student.ca1.toStringAsFixed(0)}',
                            Colors.blue),
                        _pill('CA2: ${student.ca2.toStringAsFixed(0)}',
                            Colors.indigo),
                        _pill('Exam: ${student.exam.toStringAsFixed(0)}',
                            Colors.deepPurple),
                      ],
                    ),
                  ],
                ),
              ),

              // Grade badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: gc.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gc.withAlpha(80)),
                    ),
                    child: Text(
                      total.toStringAsFixed(1),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: gc,
                          fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(student.letterGrade,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: gc,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    student.isPassing ? 'PASS' : 'FAIL',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: student.isPassing ? Colors.green : Colors.red),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          dense: true)),
                  const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                          leading:
                              Icon(Icons.delete_outline, color: Colors.red),
                          title: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                          dense: true)),
                ],
                child:
                    Icon(Icons.more_vert, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }
}