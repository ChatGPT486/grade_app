# ICT University Grade Calculator

A Flutter app for lecturers to manage student grades with Supabase backend and Excel export.

## Grade Formula
- CA1 × 15% + CA2 × 15% + Exam × 70% = Total (/100)

## GPA Scale
| Total (%)  | GPA | Grade |
|------------|-----|-------|
| 70 – 100   | 4.0 | A     |
| 65 – 69    | 3.5 | B+    |
| 60 – 64    | 3.0 | B     |
| 55 – 59    | 2.5 | C+    |
| 50 – 54    | 2.0 | C     |
| 45 – 49    | 1.5 | D+    |
| 40 – 44    | 1.0 | D     |
| Below 40   | 0.0 | F     |

---

## Setup Instructions

### Step 1 — Create a Supabase Project
1. Go to https://supabase.com and sign up for free
2. Click **New Project**, give it a name (e.g. "ict-grades"), choose a region close to Cameroon (e.g. Europe West)
3. Set a strong database password and click **Create Project**
4. Wait ~2 minutes for it to provision

### Step 2 — Set Up the Database
1. In your Supabase dashboard, click **SQL Editor** in the left sidebar
2. Click **New Query**
3. Open the file `supabase_setup.sql` from this project
4. Paste the entire contents into the editor
5. Click **Run** — you should see "Success" messages

### Step 3 — Get Your API Keys
1. In your Supabase dashboard, click **Settings** (gear icon) → **API**
2. Copy:
   - **Project URL** (looks like: https://xxxxxxxxxxxx.supabase.co)
   - **anon / public key** (a long string starting with "eyJ...")

### Step 4 — Add Keys to the App
1. Open `lib/main.dart`
2. Replace the placeholder values:
```dart
const _supabaseUrl = 'YOUR_SUPABASE_URL';       // paste Project URL here
const _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // paste anon key here
```

### Step 5 — Install Dependencies & Run
```bash
flutter pub get
flutter run
```

---

## Project Structure
```
lib/
├── main.dart                        # App entry point + Supabase init
├── models/
│   └── student_record.dart          # Student data model + grade logic
├── services/
│   ├── supabase_service.dart        # Database CRUD operations
│   └── excel_service.dart           # Excel export (one sheet per course)
└── screens/
    ├── home_screen.dart             # Main screen with tabs per course
    └── student_form_screen.dart     # Add/Edit student form
```

## Features
- Add students with: Name, Matricule, Email, Course, CA1, CA2, Exam
- Email validation: must be `name.name@ictuniversity.edu.cm`
- Automatic grade calculation: GPA, Letter grade, Pass/Fail
- Live grade preview while entering marks
- Students grouped by course (tab navigation)
- Search by name, matricule, or email
- Class statistics banner (total, GPA, pass rate)
- Export all results to Excel (one sheet per course, sorted by mark)
- Duplicate matricule detection
- Edit and delete students
