-- 005_orders_tasks.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================
-- Enums
-- =========================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_kind') THEN
    CREATE TYPE order_kind AS ENUM ('MEDICATION', 'LAB', 'PROCEDURE');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
    CREATE TYPE order_status AS ENUM ('CREATED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
    CREATE TYPE task_status AS ENUM ('PENDING', 'STARTED', 'COMPLETED', 'CANCELLED');
  END IF;
END $$;

-- =========================
-- Orders (generic with payload)
-- =========================
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  admission_id UUID NOT NULL REFERENCES admissions(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,

  created_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  doctor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,

  kind order_kind NOT NULL,
  status order_status NOT NULL DEFAULT 'CREATED',

  -- details vary by kind (MEDICATION/LAB/PROCEDURE)
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,

  notes TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  cancelled_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_orders_tenant_id ON orders(tenant_id);
CREATE INDEX IF NOT EXISTS idx_orders_admission_id ON orders(admission_id);
CREATE INDEX IF NOT EXISTS idx_orders_patient_id ON orders(patient_id);
CREATE INDEX IF NOT EXISTS idx_orders_kind ON orders(kind);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);

-- =========================
-- Nursing tasks generated from orders
-- =========================
CREATE TABLE IF NOT EXISTS nursing_tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  admission_id UUID NOT NULL REFERENCES admissions(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,

  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,

  -- snapshot from active bed at creation time (helps filtering)
  department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  room_id UUID REFERENCES rooms(id) ON DELETE SET NULL,
  bed_id UUID REFERENCES beds(id) ON DELETE SET NULL,

  title TEXT NOT NULL,
  details TEXT,
  kind order_kind NOT NULL,

  status task_status NOT NULL DEFAULT 'PENDING',

  assigned_to_user_id UUID REFERENCES users(id) ON DELETE SET NULL,

  created_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tasks_tenant_id ON nursing_tasks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tasks_admission_id ON nursing_tasks(admission_id);
CREATE INDEX IF NOT EXISTS idx_tasks_order_id ON nursing_tasks(order_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON nursing_tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON nursing_tasks(assigned_to_user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_department_id ON nursing_tasks(department_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON nursing_tasks(created_at);
