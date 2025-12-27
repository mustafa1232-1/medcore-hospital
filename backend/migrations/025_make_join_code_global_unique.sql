BEGIN;

-- اجعل الكود Unique عالمياً
CREATE UNIQUE INDEX IF NOT EXISTS uq_patient_join_codes_code_global
  ON patient_join_codes(code);

COMMIT;
