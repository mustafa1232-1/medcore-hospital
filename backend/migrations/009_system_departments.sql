-- 009_system_departments.sql
-- ثابتة: قائمة الأقسام القياسية للنظام (System Catalog)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS system_departments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT NOT NULL UNIQUE,
  name_ar TEXT NOT NULL,
  name_en TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seed: your fixed catalog (Arabic + common English label)
-- Note: ON CONFLICT keeps it idempotent across environments.
INSERT INTO system_departments (code, name_ar, name_en, sort_order, is_active)
VALUES
  ('ER',            'الطوارئ (ER)',                 'Emergency',                 10,  true),
  ('INTERNAL',      'الباطنية',                     'Internal Medicine',         20,  true),
  ('SURGERY',       'الجراحة العامة',               'General Surgery',           30,  true),
  ('ORTHO',         'العظام',                       'Orthopedics',               40,  true),
  ('OBGYN',         'النسائية والتوليد',            'Obstetrics & Gynecology',   50,  true),
  ('PEDIATRICS',    'الأطفال',                      'Pediatrics',                60,  true),
  ('ICU',           'العناية المركزة (ICU)',        'ICU',                       70,  true),
  ('RESUS',         'الإنعاش (Resuscitation)',      'Resuscitation',             80,  true),
  ('ANESTHESIA',    'التخدير',                      'Anesthesia',                90,  true),
  ('CARDIO',        'القلب',                        'Cardiology',                100, true),
  ('NEURO',         'الأعصاب',                      'Neurology',                 110, true),
  ('DERM',          'الجلدية',                      'Dermatology',               120, true),
  ('OPHTH',         'العيون',                       'Ophthalmology',             130, true),
  ('ENT',           'الأنف والأذن والحنجرة',        'ENT',                       140, true),
  ('NEPHRO',        'الكلى وغسيل الكلى',            'Nephrology & Dialysis',     150, true),
  ('ONCO',          'الأورام',                      'Oncology',                  160, true),
  ('RADIOLOGY',     'الأشعة',                       'Radiology',                 170, true)
ON CONFLICT (code) DO UPDATE
SET
  name_ar = EXCLUDED.name_ar,
  name_en = EXCLUDED.name_en,
  sort_order = EXCLUDED.sort_order,
  is_active = EXCLUDED.is_active;
