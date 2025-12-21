-- 006_staff_code.sql
-- Adds human-friendly staff_code per tenant (used for UI), keeps users.id UUID as internal PK.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS staff_code TEXT;

-- Backfill existing users
DO $$
DECLARE
  r RECORD;
  tenant_base TEXT;
  name_base TEXT;
BEGIN
  FOR r IN
    SELECT u.id, u.tenant_id, u.full_name, t.code AS tenant_code
    FROM users u
    JOIN tenants t ON t.id = u.tenant_id
    WHERE u.staff_code IS NULL
  LOOP
    tenant_base := split_part(r.tenant_code, '-', 1);
    name_base := lower(regexp_replace(coalesce(nullif(trim(r.full_name), ''), 'staff'), '[^[:alnum:]]+', '-', 'g'));
    name_base := regexp_replace(name_base, '(^-+|-+$)', '', 'g');

    IF length(name_base) > 14 THEN name_base := left(name_base, 14); END IF;
    IF length(tenant_base) > 10 THEN tenant_base := left(tenant_base, 10); END IF;

    UPDATE users
      SET staff_code = name_base || '-' || tenant_base || '-' || substr(md5(r.id::text), 1, 4)
      WHERE id = r.id;
  END LOOP;
END $$;

ALTER TABLE users
  ALTER COLUMN staff_code SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_users_tenant_staff_code
  ON users(tenant_id, staff_code);
