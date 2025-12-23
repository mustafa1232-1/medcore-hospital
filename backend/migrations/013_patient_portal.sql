BEGIN;

-- 1) Directory للمنشآت (يجلس فوق tenants لعرضها في التطبيق)
CREATE TABLE IF NOT EXISTS facilities_directory (
  id UUID PRIMARY KEY, -- نفس tenant_id
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- HOSPITAL/PHARMACY/LAB/STORE
  city TEXT,
  area TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_public BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- تأكد أنه مرتبط بجدول tenants
ALTER TABLE facilities_directory
  ADD CONSTRAINT fk_facilities_directory_tenant
  FOREIGN KEY (id) REFERENCES tenants(id) ON DELETE CASCADE;


-- 2) حساب المريض العام (خارج tenants)
CREATE TABLE IF NOT EXISTS patient_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone TEXT,
  email TEXT,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  date_of_birth DATE,
  gender TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (phone),
  UNIQUE (email)
);

-- 3) عضوية المريض في منشأة (طلب/موافقة)
CREATE TYPE membership_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'REVOKED');

CREATE TABLE IF NOT EXISTS patient_memberships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  patient_account_id UUID NOT NULL REFERENCES patient_accounts(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  status membership_status NOT NULL DEFAULT 'PENDING',
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,

  -- الربط مع سجل patients داخل هذا tenant بعد الموافقة
  tenant_patient_id UUID REFERENCES patients(id) ON DELETE SET NULL,

  UNIQUE (patient_account_id, tenant_id)
);

CREATE INDEX IF NOT EXISTS idx_patient_memberships_tenant_status
  ON patient_memberships(tenant_id, status);

COMMIT;
