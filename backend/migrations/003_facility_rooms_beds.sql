-- 003_facility_rooms_beds.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Departments
CREATE TABLE IF NOT EXISTS departments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, code)
);

CREATE INDEX IF NOT EXISTS idx_departments_tenant_id ON departments(tenant_id);

-- Rooms
CREATE TABLE IF NOT EXISTS rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  department_id UUID NOT NULL REFERENCES departments(id) ON DELETE RESTRICT,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  floor INT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, code)
);

CREATE INDEX IF NOT EXISTS idx_rooms_tenant_id ON rooms(tenant_id);
CREATE INDEX IF NOT EXISTS idx_rooms_department_id ON rooms(department_id);

-- Bed status enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'bed_status') THEN
    CREATE TYPE bed_status AS ENUM (
      'AVAILABLE',
      'OCCUPIED',
      'CLEANING',
      'MAINTENANCE',
      'RESERVED',
      'OUT_OF_SERVICE'
    );
  END IF;
END $$;

-- Beds
CREATE TABLE IF NOT EXISTS beds (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE RESTRICT,
  code TEXT NOT NULL,
  status bed_status NOT NULL DEFAULT 'AVAILABLE',
  notes TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, code)
);

CREATE INDEX IF NOT EXISTS idx_beds_tenant_id ON beds(tenant_id);
CREATE INDEX IF NOT EXISTS idx_beds_room_id ON beds(room_id);
CREATE INDEX IF NOT EXISTS idx_beds_status ON beds(status);
