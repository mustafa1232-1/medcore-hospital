-- 005_tenant_code.sql

-- Add a short, human-friendly tenant code used for login / sharing.
-- Keep tenants.id (UUID) as the internal primary key.

ALTER TABLE tenants
  ADD COLUMN IF NOT EXISTS code TEXT;

-- Backfill existing rows (best-effort). If name is empty, use a generic prefix.
-- We keep it deterministic-ish + unique by appending a short hash derived from id.
DO $$
DECLARE
  r RECORD;
  base TEXT;
BEGIN
  FOR r IN SELECT id, name FROM tenants WHERE code IS NULL LOOP
    base := lower(regexp_replace(coalesce(nullif(trim(r.name), ''), 'tenant'), '[^[:alnum:]]+', '-', 'g'));
    base := regexp_replace(base, '(^-+|-+$)', '', 'g');
    IF length(base) > 16 THEN base := left(base, 16); END IF;
    -- Append 4 chars from md5(id) to minimize collisions
    UPDATE tenants
      SET code = base || '-' || substr(md5(r.id::text), 1, 4)
      WHERE id = r.id;
  END LOOP;
END $$;

-- Enforce NOT NULL and uniqueness
ALTER TABLE tenants
  ALTER COLUMN code SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_tenants_code ON tenants(code);
