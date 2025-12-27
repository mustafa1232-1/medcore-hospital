BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Patient Profile (global per patient account)
CREATE TABLE IF NOT EXISTS patient_profiles (
  patient_account_id UUID PRIMARY KEY
    REFERENCES patient_accounts(id) ON DELETE CASCADE,

  -- Core identity
  full_name TEXT,
  date_of_birth DATE,
  gender TEXT, -- 'MALE','FEMALE','OTHER' (optional validation at API level)

  -- Social
  marital_status TEXT, -- 'SINGLE','MARRIED','DIVORCED','WIDOWED' (API validates)
  children_count INT,

  -- Phones (account already has phone, but we allow storing here too)
  phone TEXT,
  emergency_phone TEXT,
  emergency_relation TEXT,        -- e.g. 'Father','Brother','Friend'
  emergency_contact_name TEXT,

  -- Medical background (json arrays)
  chronic_conditions JSONB NOT NULL DEFAULT '[]'::jsonb,
  chronic_medications JSONB NOT NULL DEFAULT '[]'::jsonb,
  drug_allergies JSONB NOT NULL DEFAULT '[]'::jsonb, -- [{drugName, reaction, severity}...]

  -- Address
  governorate TEXT,
  area TEXT,
  address_details TEXT,

  -- Location
  location_lat DOUBLE PRECISION,
  location_lng DOUBLE PRECISION,

  -- Primary doctor
  primary_doctor_name TEXT,
  primary_doctor_phone TEXT,

  -- Extra (helpful)
  blood_type TEXT,   -- 'A+','A-','B+','B-','AB+','AB-','O+','O-'
  height_cm INT,
  weight_kg INT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_patient_profiles_phone ON patient_profiles(phone);

COMMIT;
