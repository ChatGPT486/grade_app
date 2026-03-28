import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_record.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _client = Supabase.instance.client;
  static const _table = 'students';

  // Fetch all students ordered by course then name
  Future<List<StudentRecord>> fetchAll() async {
    final res = await _client
        .from(_table)
        .select()
        .order('course', ascending: true)
        .order('name', ascending: true);
    return (res as List).map((e) => StudentRecord.fromMap(e)).toList();
  }

  // Fetch students for a specific course
  Future<List<StudentRecord>> fetchByCourse(String course) async {
    final res = await _client
        .from(_table)
        .select()
        .eq('course', course)
        .order('name', ascending: true);
    return (res as List).map((e) => StudentRecord.fromMap(e)).toList();
  }

  // Get distinct course names
  Future<List<String>> fetchCourses() async {
    final res = await _client.from(_table).select('course');
    final courses = (res as List)
        .map((e) => e['course'].toString())
        .toSet()
        .toList()
      ..sort();
    return courses;
  }

  // Insert a new student
  Future<StudentRecord> insert(StudentRecord student) async {
    final res = await _client
        .from(_table)
        .insert(student.toMap())
        .select()
        .single();
    return StudentRecord.fromMap(res);
  }

  // Update an existing student
  Future<StudentRecord> update(StudentRecord student) async {
    final res = await _client
        .from(_table)
        .update(student.toMap())
        .eq('id', student.id!)
        .select()
        .single();
    return StudentRecord.fromMap(res);
  }

  // Delete a student
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  // Check if matricule already exists (for validation)
  Future<bool> matriculeExists(String matricule, {String? excludeId}) async {
    var query = _client
        .from(_table)
        .select('id')
        .eq('matricule', matricule);
    final res = await query;
    final list = res as List;
    if (excludeId != null) {
      return list.any((e) => e['id'].toString() != excludeId);
    }
    return list.isNotEmpty;
  }
}
