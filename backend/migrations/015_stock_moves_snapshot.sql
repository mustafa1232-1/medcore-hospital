BEGIN;

-- snapshot columns for immutable audit trail (idempotent)
ALTER TABLE stock_moves
  ADD COLUMN IF NOT EXISTS department_id UUID REFERENCES departments(id) ON DELETE SET NULL;

ALTER TABLE stock_moves
  ADD COLUMN IF NOT EXISTS room_id UUID REFERENCES rooms(id) ON DELETE SET NULL;

ALTER TABLE stock_moves
  ADD COLUMN IF NOT EXISTS bed_id UUID REFERENCES beds(id) ON DELETE SET NULL;

-- existing indexes (keep + idempotent)
CREATE INDEX IF NOT EXISTS idx_stock_moves_dept ON stock_moves(tenant_id, department_id);
CREATE INDEX IF NOT EXISTS idx_stock_moves_room ON stock_moves(tenant_id, room_id);
CREATE INDEX IF NOT EXISTS idx_stock_moves_bed  ON stock_moves(tenant_id, bed_id);

-- ✅ إضافات مهمة للبحث عن تاريخ الصرف لمريض/تنويم (Audit Trail)
CREATE INDEX IF NOT EXISTS idx_stock_moves_patient
  ON stock_moves(tenant_id, patient_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_stock_moves_admission
  ON stock_moves(tenant_id, admission_id, created_at DESC);

COMMIT;
