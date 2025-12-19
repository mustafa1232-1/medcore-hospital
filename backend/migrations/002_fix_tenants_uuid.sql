CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tenants table if it was not created before (due to gen_random_uuid issue)
CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
