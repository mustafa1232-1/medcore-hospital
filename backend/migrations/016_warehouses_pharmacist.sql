ALTER TABLE warehouses
ADD COLUMN IF NOT EXISTS pharmacist_user_id uuid;

ALTER TABLE warehouses
ADD CONSTRAINT warehouses_pharmacist_fk
FOREIGN KEY (pharmacist_user_id) REFERENCES users(id);

-- Optional but recommended for phase-1: enforce 1 warehouse per tenant
-- (إذا تحب تثبته على DB بدل الكود)
-- ALTER TABLE warehouses
-- ADD CONSTRAINT warehouses_one_per_tenant UNIQUE (tenant_id);
