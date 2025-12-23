-- 014_pharmacy_inventory.sql
BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================
-- Enums
-- =========================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'drug_form') THEN
    CREATE TYPE drug_form AS ENUM ('TABLET','CAPSULE','SYRUP','INJECTION','DROPS','CREAM','OINTMENT','SUPPOSITORY','IV_BAG','INHALER','OTHER');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'stock_move_type') THEN
    CREATE TYPE stock_move_type AS ENUM (
      'RECEIPT',          -- إدخال مشتريات/توريد
      'DISPENSE',         -- صرف لمريض
      'TRANSFER_OUT',     -- تحويل خارج
      'TRANSFER_IN',      -- تحويل داخل
      'ADJUSTMENT_IN',    -- تسوية زيادة (جرد)
      'ADJUSTMENT_OUT',   -- تسوية نقص (جرد)
      'WASTE',            -- اتلاف
      'RETURN'            -- مرتجع
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'request_status') THEN
    CREATE TYPE request_status AS ENUM ('DRAFT','SUBMITTED','APPROVED','REJECTED','CANCELLED');
  END IF;
END $$;

-- =========================
-- Warehouses / Stores
-- =========================
CREATE TABLE IF NOT EXISTS warehouses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
  name TEXT NOT NULL,
  code TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, name)
);

CREATE INDEX IF NOT EXISTS idx_warehouses_tenant ON warehouses(tenant_id);

-- =========================
-- Drug Catalog
-- tenant-scoped so each facility can customize names/forms etc.
-- =========================
CREATE TABLE IF NOT EXISTS drug_catalog (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  generic_name TEXT NOT NULL,              -- Paracetamol
  brand_name TEXT,                         -- Panadol (optional)
  strength TEXT,                           -- 500mg, 1g/100ml
  form drug_form NOT NULL DEFAULT 'OTHER', -- TABLET/SYRUP...
  route TEXT,                              -- PO/IV/IM...
  unit TEXT,                               -- tablet, vial, bottle...
  pack_size INT,                           -- 10 tabs, 1 vial...
  barcode TEXT,                            -- optional
  atc_code TEXT,                           -- optional

  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_drug_catalog_tenant ON drug_catalog(tenant_id);
CREATE INDEX IF NOT EXISTS idx_drug_catalog_name ON drug_catalog(tenant_id, generic_name);

-- ✅ Expression-based uniqueness (Postgres يسمح بها كـ UNIQUE INDEX فقط)
CREATE UNIQUE INDEX IF NOT EXISTS uq_drug_catalog_key
  ON drug_catalog (
    tenant_id,
    generic_name,
    strength,
    form,
    COALESCE(route,''),
    COALESCE(unit,'')
  );

-- =========================
-- Stock lots (batch/expiry) per warehouse+drug
-- LOT-level tracking
-- =========================
CREATE TABLE IF NOT EXISTS stock_lots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
  drug_id UUID NOT NULL REFERENCES drug_catalog(id) ON DELETE RESTRICT,

  lot_number TEXT,               -- batch
  expiry_date DATE,
  unit_cost NUMERIC(18,4),       -- optional
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_stock_lots_tenant_wh_drug
  ON stock_lots(tenant_id, warehouse_id, drug_id);

-- ✅ Expression-based uniqueness for lot identity
CREATE UNIQUE INDEX IF NOT EXISTS uq_stock_lots_key
  ON stock_lots (
    tenant_id,
    warehouse_id,
    drug_id,
    COALESCE(lot_number,''),
    COALESCE(expiry_date::text,'')
  );

-- =========================
-- Inventory Ledger (immutable)
-- Any quantity change MUST be a move row.
-- =========================
CREATE TABLE IF NOT EXISTS stock_moves (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  move_type stock_move_type NOT NULL,
  status request_status NOT NULL DEFAULT 'APPROVED',

  warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
  lot_id UUID REFERENCES stock_lots(id) ON DELETE RESTRICT,
  drug_id UUID NOT NULL REFERENCES drug_catalog(id) ON DELETE RESTRICT,

  qty NUMERIC(18,3) NOT NULL CHECK (qty > 0),
  direction INT NOT NULL CHECK (direction IN (1,-1)),

  reference_type TEXT,
  reference_id UUID,

  patient_id UUID REFERENCES patients(id) ON DELETE SET NULL,
  admission_id UUID REFERENCES admissions(id) ON DELETE SET NULL,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,

  created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  approved_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,

  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_stock_moves_tenant_created ON stock_moves(tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stock_moves_tenant_drug ON stock_moves(tenant_id, drug_id);
CREATE INDEX IF NOT EXISTS idx_stock_moves_tenant_wh ON stock_moves(tenant_id, warehouse_id);
CREATE INDEX IF NOT EXISTS idx_stock_moves_order ON stock_moves(order_id);

-- =========================
-- Stock Requests (workflow)
-- =========================
CREATE TABLE IF NOT EXISTS stock_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  kind stock_move_type NOT NULL,
  status request_status NOT NULL DEFAULT 'DRAFT',

  from_warehouse_id UUID REFERENCES warehouses(id) ON DELETE RESTRICT,
  to_warehouse_id UUID REFERENCES warehouses(id) ON DELETE RESTRICT,

  patient_id UUID REFERENCES patients(id) ON DELETE SET NULL,
  admission_id UUID REFERENCES admissions(id) ON DELETE SET NULL,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,

  submitted_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  submitted_at TIMESTAMPTZ,
  approved_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,

  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_stock_requests_tenant_status ON stock_requests(tenant_id, status);

CREATE TABLE IF NOT EXISTS stock_request_lines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,

  request_id UUID NOT NULL REFERENCES stock_requests(id) ON DELETE CASCADE,
  drug_id UUID NOT NULL REFERENCES drug_catalog(id) ON DELETE RESTRICT,

  lot_number TEXT,
  expiry_date DATE,
  unit_cost NUMERIC(18,4),

  qty NUMERIC(18,3) NOT NULL CHECK (qty > 0),
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_stock_request_lines_req ON stock_request_lines(request_id);

COMMIT;
