BEGIN;

-- =========================
-- 1) patients: join code (staff generates it, patient uses it)
-- =========================
ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS join_code_hash TEXT,
  ADD COLUMN IF NOT EXISTS join_code_expires_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_patients_join_code_active
  ON patients(tenant_id, join_code_expires_at);

-- =========================
-- 2) patient_memberships: leaving without deleting data
-- =========================
ALTER TABLE patient_memberships
  ADD COLUMN IF NOT EXISTS left_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_patient_memberships_patient_account
  ON patient_memberships(patient_account_id);

CREATE INDEX IF NOT EXISTS idx_patient_memberships_tenant_patient
  ON patient_memberships(tenant_id, tenant_patient_id);

COMMIT;
