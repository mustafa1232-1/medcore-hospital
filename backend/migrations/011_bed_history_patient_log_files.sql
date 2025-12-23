BEGIN;

-- 1) Bed History
CREATE TABLE IF NOT EXISTS bed_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  bed_id UUID NOT NULL,
  room_id UUID NOT NULL,
  department_id UUID NULL,

  admission_id UUID NOT NULL,
  patient_id UUID NOT NULL,

  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  released_at TIMESTAMPTZ NULL,

  reason TEXT NOT NULL DEFAULT 'ADMISSION'
    CHECK (reason IN ('ADMISSION', 'TRANSFER', 'DISCHARGE', 'MANUAL')),

  actor_user_id UUID NULL,
  notes TEXT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bed_history_tenant_bed_time
  ON bed_history (tenant_id, bed_id, assigned_at DESC);

CREATE INDEX IF NOT EXISTS idx_bed_history_tenant_patient_time
  ON bed_history (tenant_id, patient_id, assigned_at DESC);

CREATE INDEX IF NOT EXISTS idx_bed_history_tenant_admission
  ON bed_history (tenant_id, admission_id);

-- يمنع وجود سجلين مفتوحين لنفس السرير
CREATE UNIQUE INDEX IF NOT EXISTS uq_bed_history_one_open_per_bed
  ON bed_history (tenant_id, bed_id)
  WHERE released_at IS NULL;


-- 2) Patient Log (Append-only)
CREATE TABLE IF NOT EXISTS patient_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  patient_id UUID NOT NULL,
  admission_id UUID NULL,

  event_type TEXT NOT NULL,
  message TEXT NULL,
  meta JSONB NOT NULL DEFAULT '{}'::jsonb,

  actor_user_id UUID NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_patient_log_tenant_patient_time
  ON patient_log (tenant_id, patient_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_patient_log_tenant_admission_time
  ON patient_log (tenant_id, admission_id, created_at DESC);


-- 3) Patient Files (Metadata فقط - سنفعّله لاحقًا)
CREATE TABLE IF NOT EXISTS patient_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,

  patient_id UUID NOT NULL,
  admission_id UUID NULL,

  kind TEXT NOT NULL DEFAULT 'OTHER'
    CHECK (kind IN ('LAB_RESULT', 'RADIOLOGY', 'PRESCRIPTION', 'DISCHARGE_SUMMARY', 'OTHER')),

  storage_key TEXT NOT NULL,
  filename TEXT NOT NULL,
  mime_type TEXT NULL,
  size_bytes BIGINT NULL,

  uploaded_by_user_id UUID NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_patient_files_tenant_patient_time
  ON patient_files (tenant_id, patient_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_patient_files_tenant_admission_time
  ON patient_files (tenant_id, admission_id, created_at DESC);

COMMIT;
