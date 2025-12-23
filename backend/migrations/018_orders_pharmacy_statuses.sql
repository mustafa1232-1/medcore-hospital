BEGIN;

-- ✅ إضافة قيم جديدة إلى enum order_status
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
    -- PARTIALLY_COMPLETED
    IF NOT EXISTS (
      SELECT 1
      FROM pg_enum e
      JOIN pg_type t ON t.oid = e.enumtypid
      WHERE t.typname = 'order_status' AND e.enumlabel = 'PARTIALLY_COMPLETED'
    ) THEN
      ALTER TYPE order_status ADD VALUE 'PARTIALLY_COMPLETED';
    END IF;

    -- OUT_OF_STOCK
    IF NOT EXISTS (
      SELECT 1
      FROM pg_enum e
      JOIN pg_type t ON t.oid = e.enumtypid
      WHERE t.typname = 'order_status' AND e.enumlabel = 'OUT_OF_STOCK'
    ) THEN
      ALTER TYPE order_status ADD VALUE 'OUT_OF_STOCK';
    END IF;
  END IF;
END $$;

-- فهارس اختيارية (تفيد بالفلترة)
CREATE INDEX IF NOT EXISTS idx_orders_kind_status_created
  ON orders(kind, status, created_at DESC);

COMMIT;
