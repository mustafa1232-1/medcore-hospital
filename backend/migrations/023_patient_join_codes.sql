-- 023_patient_join_codes.sql
BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS patient_join_codes (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

  code varchar(12) NOT NULL,
  status varchar(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | DISABLED | EXPIRED
  max_uses int NOT NULL DEFAULT 1,
  used_count int NOT NULL DEFAULT 0,

  expires_at timestamptz NULL,
  created_by_staff_id uuid NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_patient_join_codes_tenant_code
  ON patient_join_codes(tenant_id, code);

CREATE INDEX IF NOT EXISTS ix_patient_join_codes_tenant_status
  ON patient_join_codes(tenant_id, status);

COMMIT;
