BEGIN;

-- 1) Drop old per-tenant unique (if exists)
DROP INDEX IF EXISTS uq_patient_join_codes_tenant_code;

-- 2) Create global unique on code
CREATE UNIQUE INDEX IF NOT EXISTS uq_patient_join_codes_code
  ON patient_join_codes(code);

COMMIT;
