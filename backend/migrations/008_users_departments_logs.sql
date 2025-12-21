-- 008_users_departments_logs.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================
-- A) users.department_id
-- =========================
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS department_id UUID;

-- FK (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'fk_users_department_id'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT fk_users_department_id
      FOREIGN KEY (department_id) REFERENCES departments(id)
      ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_users_tenant_department
  ON users(tenant_id, department_id);

-- =========================
-- B) admission_logs (for timeline later)
-- =========================
CREATE TABLE IF NOT EXISTS admission_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  admission_id UUID NOT NULL REFERENCES admissions(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,

  created_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

  type TEXT NOT NULL DEFAULT 'NOTE',
  message TEXT NOT NULL,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admission_logs_tenant_id ON admission_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_admission_logs_admission_id ON admission_logs(admission_id);
CREATE INDEX IF NOT EXISTS idx_admission_logs_patient_id ON admission_logs(patient_id);
CREATE INDEX IF NOT EXISTS idx_admission_logs_created_at ON admission_logs(created_at);
