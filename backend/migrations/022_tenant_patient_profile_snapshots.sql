BEGIN;

-- Snapshot of patient profile captured inside a tenant when joining
CREATE TABLE IF NOT EXISTS tenant_patient_profile_snapshots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  tenant_patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
  patient_account_id UUID NOT NULL REFERENCES patient_accounts(id) ON DELETE RESTRICT,

  snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tenant_patient_profile_snapshots_tenant_patient
  ON tenant_patient_profile_snapshots(tenant_id, tenant_patient_id);

CREATE INDEX IF NOT EXISTS idx_tenant_patient_profile_snapshots_patient_account
  ON tenant_patient_profile_snapshots(patient_account_id);

COMMIT;
