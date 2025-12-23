-- 012_orders_hardening_and_results.sql
BEGIN;

-- 1) updated_at trigger (مشترك)
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_orders_set_updated_at') THEN
    CREATE TRIGGER trg_orders_set_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_tasks_set_updated_at') THEN
    CREATE TRIGGER trg_tasks_set_updated_at
    BEFORE UPDATE ON nursing_tasks
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();
  END IF;
END $$;


-- 2) ضمان اتساق tenant/admission/patient داخل orders
-- (أقوى من مجرد FK منفصل)
CREATE OR REPLACE FUNCTION orders_tenant_consistency()
RETURNS TRIGGER AS $$
DECLARE
  a_tenant uuid;
  a_patient uuid;
BEGIN
  SELECT tenant_id, patient_id
    INTO a_tenant, a_patient
  FROM admissions
  WHERE id = NEW.admission_id;

  IF a_tenant IS NULL THEN
    RAISE EXCEPTION 'Invalid admission_id';
  END IF;

  IF a_tenant <> NEW.tenant_id THEN
    RAISE EXCEPTION 'Tenant mismatch: order.tenant_id != admission.tenant_id';
  END IF;

  IF a_patient <> NEW.patient_id THEN
    RAISE EXCEPTION 'Patient mismatch: order.patient_id != admission.patient_id';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_orders_tenant_consistency') THEN
    CREATE TRIGGER trg_orders_tenant_consistency
    BEFORE INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION orders_tenant_consistency();
  END IF;
END $$;


-- 3) نفس الفكرة على nursing_tasks (admission/patient/tenant)
CREATE OR REPLACE FUNCTION tasks_tenant_consistency()
RETURNS TRIGGER AS $$
DECLARE
  a_tenant uuid;
  a_patient uuid;
BEGIN
  SELECT tenant_id, patient_id
    INTO a_tenant, a_patient
  FROM admissions
  WHERE id = NEW.admission_id;

  IF a_tenant IS NULL THEN
    RAISE EXCEPTION 'Invalid admission_id';
  END IF;

  IF a_tenant <> NEW.tenant_id THEN
    RAISE EXCEPTION 'Tenant mismatch: task.tenant_id != admission.tenant_id';
  END IF;

  IF a_patient <> NEW.patient_id THEN
    RAISE EXCEPTION 'Patient mismatch: task.patient_id != admission.patient_id';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_tasks_tenant_consistency') THEN
    CREATE TRIGGER trg_tasks_tenant_consistency
    BEFORE INSERT OR UPDATE ON nursing_tasks
    FOR EACH ROW
    EXECUTE FUNCTION tasks_tenant_consistency();
  END IF;
END $$;


-- 4) فهرس JSONB على payload (مهم للبحث)
CREATE INDEX IF NOT EXISTS idx_orders_payload_gin ON orders USING GIN (payload);

-- 5) نتائج التحاليل (LAB RESULTS)
CREATE TABLE IF NOT EXISTS lab_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  admission_id UUID NOT NULL REFERENCES admissions(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,

  -- result payload: values, reference ranges, notes...
  result JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lab_results_tenant_patient ON lab_results(tenant_id, patient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_lab_results_order_id ON lab_results(order_id);


-- 6) إعطاء الدواء (Medication Administrations)
CREATE TYPE medication_admin_status AS ENUM ('SCHEDULED', 'GIVEN', 'MISSED', 'CANCELLED');

CREATE TABLE IF NOT EXISTS medication_administrations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  admission_id UUID NOT NULL REFERENCES admissions(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,

  scheduled_at TIMESTAMPTZ,
  given_at TIMESTAMPTZ,

  status medication_admin_status NOT NULL DEFAULT 'SCHEDULED',
  administered_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,

  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_med_admin_tenant_patient_time
  ON medication_administrations(tenant_id, patient_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_med_admin_order_id
  ON medication_administrations(order_id);

COMMIT;
