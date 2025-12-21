-- 010_departments_system_catalog.sql
-- ربط departments بقائمة ثابتة + إضافة إعدادات مخطط الغرف/الأسِرّة
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1) Link tenant departments to system catalog
ALTER TABLE departments
  ADD COLUMN IF NOT EXISTS system_department_id UUID
    REFERENCES system_departments(id) ON DELETE RESTRICT;

-- 2) Store planned layout for this department (used at activation time)
ALTER TABLE departments
  ADD COLUMN IF NOT EXISTS rooms_count INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS beds_per_room INT NOT NULL DEFAULT 0;

-- 3) Ensure a tenant cannot activate the same system department twice
CREATE UNIQUE INDEX IF NOT EXISTS ux_departments_tenant_system
  ON departments(tenant_id, system_department_id)
  WHERE system_department_id IS NOT NULL;

-- 4) Basic validation (non-negative). Creation endpoint will enforce >=1 where needed.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_departments_rooms_count_nonneg'
  ) THEN
    ALTER TABLE departments
      ADD CONSTRAINT chk_departments_rooms_count_nonneg CHECK (rooms_count >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_departments_beds_per_room_nonneg'
  ) THEN
    ALTER TABLE departments
      ADD CONSTRAINT chk_departments_beds_per_room_nonneg CHECK (beds_per_room >= 0);
  END IF;
END $$;
