class StudentRecord {
  final String? id;
  final String name;
  final String matricule;
  final String email;
  final String course;
  final double ca1;  // entered out of 20
  final double ca2;  // entered out of 10
  final double exam; // entered out of 70

  StudentRecord({
    this.id,
    required this.name,
    required this.matricule,
    required this.email,
    required this.course,
    required this.ca1,
    required this.ca2,
    required this.exam,
  });

  // Total = CA1 (/20) + CA2 (/10) + Exam (/70) = max 100
  // Direct sum — no scaling needed
  double get totalMark => ca1 + ca2 + exam;

  double get gpa => StudentRecord.percentageToGpa(totalMark);
  String get letterGrade => StudentRecord.gpaToLetter(gpa);
  bool get isPassing => totalMark >= 40;

  static double percentageToGpa(double pct) {
    if (pct >= 70) return 4.0;
    if (pct >= 65) return 3.5;
    if (pct >= 60) return 3.0;
    if (pct >= 55) return 2.5;
    if (pct >= 50) return 2.0;
    if (pct >= 45) return 1.5;
    if (pct >= 40) return 1.0;
    return 0.0;
  }

  static String gpaToLetter(double gpa) {
    if (gpa >= 4.0) return 'A';
    if (gpa >= 3.5) return 'B+';
    if (gpa >= 3.0) return 'B';
    if (gpa >= 2.5) return 'C+';
    if (gpa >= 2.0) return 'C';
    if (gpa >= 1.5) return 'D+';
    if (gpa >= 1.0) return 'D';
    return 'F';
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'matricule': matricule,
        'email': email,
        'course': course,
        'ca1': ca1,
        'ca2': ca2,
        'exam': exam,
      };

  factory StudentRecord.fromMap(Map<String, dynamic> map) => StudentRecord(
        id: map['id']?.toString(),
        name: map['name'] ?? '',
        matricule: map['matricule'] ?? '',
        email: map['email'] ?? '',
        course: map['course'] ?? '',
        ca1: (map['ca1'] ?? 0).toDouble(),
        ca2: (map['ca2'] ?? 0).toDouble(),
        exam: (map['exam'] ?? 0).toDouble(),
      );

  StudentRecord copyWith({
    String? id,
    String? name,
    String? matricule,
    String? email,
    String? course,
    double? ca1,
    double? ca2,
    double? exam,
  }) =>
      StudentRecord(
        id: id ?? this.id,
        name: name ?? this.name,
        matricule: matricule ?? this.matricule,
        email: email ?? this.email,
        course: course ?? this.course,
        ca1: ca1 ?? this.ca1,
        ca2: ca2 ?? this.ca2,
        exam: exam ?? this.exam,
      );
}