BEGIN;

CREATE TABLE IF NOT EXISTS patient_join_requests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  join_code_id uuid NULL REFERENCES patient_join_codes(id) ON DELETE SET NULL,

  patient_account_id uuid NOT NULL REFERENCES patient_accounts(id) ON DELETE CASCADE,

  status varchar(20) NOT NULL DEFAULT 'PENDING', -- PENDING | APPROVED | REJECTED
  note text NULL,

  created_at timestamptz NOT NULL DEFAULT now(),
  decided_at timestamptz NULL,
  decided_by_user_id uuid NULL
);

CREATE INDEX IF NOT EXISTS ix_pjr_tenant_status_created
  ON patient_join_requests(tenant_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS ix_pjr_patient_account
  ON patient_join_requests(patient_account_id);

COMMIT;
