-- ─────────────────────────────────────────────────────────────────────────────
-- ICT University Grade Calculator — Supabase Database Setup
-- Run this SQL in your Supabase project:
-- Dashboard → SQL Editor → New Query → Paste & Run
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Create the students table
CREATE TABLE IF NOT EXISTS students (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  matricule   TEXT NOT NULL UNIQUE,
  email       TEXT NOT NULL,
  course      TEXT NOT NULL,
  ca1         NUMERIC(5,2) NOT NULL CHECK (ca1 >= 0 AND ca1 <= 100),
  ca2         NUMERIC(5,2) NOT NULL CHECK (ca2 >= 0 AND ca2 <= 100),
  exam        NUMERIC(5,2) NOT NULL CHECK (exam >= 0 AND exam <= 100),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Auto-update the updated_at timestamp on every update
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON students
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- 3. Enable Row Level Security (RLS)
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- 4. Policy: Allow full access using the anon key (lecturer app)
--    For production you should restrict this to authenticated users.
CREATE POLICY "Allow all operations for anon"
  ON students
  FOR ALL
  TO anon
  USING (true)
  WITH CHECK (true);

-- 5. Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_students_course ON students(course);
CREATE INDEX IF NOT EXISTS idx_students_matricule ON students(matricule);

-- ─────────────────────────────────────────────────────────────────────────────
-- OPTIONAL: Sample data to test with
-- ─────────────────────────────────────────────────────────────────────────────
-- INSERT INTO students (name, matricule, email, course, ca1, ca2, exam) VALUES
--   ('John Doe',    'ICT2024001', 'john.doe@ictuniversity.edu.cm',    'Software Engineering', 75, 80, 68),
--   ('Jane Smith',  'ICT2024002', 'jane.smith@ictuniversity.edu.cm',  'Software Engineering', 90, 85, 88),
--   ('Paul Biya',   'ICT2024003', 'paul.biya@ictuniversity.edu.cm',   'Cybersecurity',        55, 60, 45),
--   ('Marie Ngono', 'ICT2024004', 'marie.ngono@ictuniversity.edu.cm', 'Cybersecurity',        30, 35, 28);
