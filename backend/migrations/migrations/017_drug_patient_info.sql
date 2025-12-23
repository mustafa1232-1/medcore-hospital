BEGIN;

ALTER TABLE drug_catalog
  ADD COLUMN IF NOT EXISTS patient_instructions_ar TEXT,
  ADD COLUMN IF NOT EXISTS patient_instructions_en TEXT,
  ADD COLUMN IF NOT EXISTS dosage_text TEXT,          -- مثال: 1 قرص
  ADD COLUMN IF NOT EXISTS frequency_text TEXT,       -- مثال: 3 مرات يومياً
  ADD COLUMN IF NOT EXISTS duration_text TEXT,        -- مثال: 5 أيام
  ADD COLUMN IF NOT EXISTS with_food BOOLEAN,         -- true/false/NULL
  ADD COLUMN IF NOT EXISTS warnings_text TEXT;        -- تحذيرات مختصرة

CREATE INDEX IF NOT EXISTS idx_drug_catalog_active
  ON drug_catalog(tenant_id, is_active);

COMMIT;
