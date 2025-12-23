BEGIN;

-- extend order_status enum (idempotent-safe)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_enum
    WHERE enumlabel = 'PARTIALLY_COMPLETED'
      AND enumtypid = 'order_status'::regtype
  ) THEN
    ALTER TYPE order_status ADD VALUE 'PARTIALLY_COMPLETED';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_enum
    WHERE enumlabel = 'OUT_OF_STOCK'
      AND enumtypid = 'order_status'::regtype
  ) THEN
    ALTER TYPE order_status ADD VALUE 'OUT_OF_STOCK';
  END IF;
END$$;

COMMIT;
