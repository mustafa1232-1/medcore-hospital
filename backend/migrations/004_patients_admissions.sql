-- 004_patients_admissions.sql
-- Adds: patients, admissions, admission_beds (bed assignments)
-- Notes:
-- - Does NOT modify existing tables.
-- - Uses tenant isolation through tenant_id on all new tables.
-- - Enforces "one active admission bed assignment per bed" & "one active bed per admission".

-- Ensure UUID extension exists (idempotent)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================
-- Patients
-- =========================
CREATE TABLE IF NOT EXISTS patients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  -- Patient identity
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  gender TEXT,               -- e.g. MALE/FEMALE/OTHER (we can enforce later)
  date_of_birth DATE,
  national_id TEXT,          -- optional
  address TEXT,
  notes TEXT,

  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Prevent duplicates within a tenant (soft rules; optional fields)
CREATE UNIQUE INDEX IF NOT EXISTS uq_patients_tenant_phone
  ON patients(tenant_id, phone)
  WHERE phone IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_patients_tenant_national_id
  ON patients(tenant_id, national_id)
  WHERE national_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_patients_tenant_id ON patients(tenant_id);
CREATE INDEX IF NOT EXISTS idx_patients_full_name ON patients(full_name);


-- =========================
-- Admissions
-- =========================
-- Admission status lifecycle:
-- PENDING   -> created by Reception, waiting assignment (doctor/bed)
-- ACTIVE    -> bed assigned and admitted
-- DISCHARGED-> discharged
-- CANCELLED -> cancelled before admission
CREATE TABLE IF NOT EXISTS admissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,

  -- created by Reception (or Admin)
  created_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

  -- assigned doctor (Doctor/Admin), nullable until assigned
  assigned_doctor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,

  status TEXT NOT NULL DEFAULT 'PENDING',
  reason TEXT,              -- chief complaint / reason for visit
  notes TEXT,

  started_at TIMESTAMPTZ,   -- when became ACTIVE
  ended_at TIMESTAMPTZ,     -- when DISCHARGED/CANCELLED

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_admission_status
    CHECK (status IN ('PENDING', 'ACTIVE', 'DISCHARGED', 'CANCELLED'))
);

CREATE INDEX IF NOT EXISTS idx_admissions_tenant_id ON admissions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_admissions_patient_id ON admissions(patient_id);
CREATE INDEX IF NOT EXISTS idx_admissions_status ON admissions(status);
CREATE INDEX IF NOT EXISTS idx_admissions_created_at ON admissions(created_at);

-- Optional: Ensure only one ACTIVE admission per patient within a tenant
-- (This matches your "one ACTIVE only" principle)
CREATE UNIQUE INDEX IF NOT EXISTS uq_admissions_one_active_per_patient
  ON admissions(tenant_id, patient_id)
  WHERE status = 'ACTIVE';


-- =========================
-- Bed Assignments per Admission
-- =========================
-- This links an admission to a bed over time.
-- Only one active assignment per admission, and one active assignment per bed.
CREATE TABLE IF NOT EXISTS admission_beds (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  admission_id UUID NOT NULL REFERENCES admissions(id) ON DELETE CASCADE,
  bed_id UUID NOT NULL REFERENCES beds(id) ON DELETE RESTRICT,

  assigned_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  released_at TIMESTAMPTZ,

  is_active BOOLEAN NOT NULL DEFAULT true,

  CONSTRAINT chk_admission_bed_release
    CHECK (
      (is_active = true AND released_at IS NULL)
      OR
      (is_active = false AND released_at IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_admission_beds_tenant_id ON admission_beds(tenant_id);
CREATE INDEX IF NOT EXISTS idx_admission_beds_admission_id ON admission_beds(admission_id);
CREATE INDEX IF NOT EXISTS idx_admission_beds_bed_id ON admission_beds(bed_id);

-- Only one active bed per admission
CREATE UNIQUE INDEX IF NOT EXISTS uq_admission_beds_one_active_per_admission
  ON admission_beds(admission_id)
  WHERE is_active = true;

-- Only one active admission per bed (bed cannot be assigned to two active admissions)
CREATE UNIQUE INDEX IF NOT EXISTS uq_admission_beds_one_active_per_bed
  ON admission_beds(bed_id)
  WHERE is_active = true;
