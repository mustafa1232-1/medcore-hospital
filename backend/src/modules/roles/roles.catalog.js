// src/modules/roles/roles.catalog.js

// Role sets per tenant type
// Keep strings UPPERCASE (consistent with your existing ADMIN)
const ROLE_CATALOG = {
  HOSPITAL: [
    'ADMIN',
    'DOCTOR',
    'NURSE',
    'RECEPTION',
    'PHARMACY',
    'LAB',
    'ACCOUNTANT',
    'STOREKEEPER',
  ],
  PHARMACY: [
    'ADMIN',
    'PHARMACIST',
    'CASHIER',
    'STOREKEEPER',
    'ACCOUNTANT',
  ],
  WAREHOUSE: [
    'ADMIN',
    'STOREKEEPER',
    'DISPATCH',
    'ACCOUNTANT',
  ],
  LAB: [
    'ADMIN',
    'LAB_TECH',
    'RECEPTION',
    'CASHIER',
    'ACCOUNTANT',
  ],
};

// fallback if type is unknown
const DEFAULT_ROLES = ['ADMIN'];

function getDefaultRolesForTenantType(type) {
  if (!type) return DEFAULT_ROLES;
  const key = String(type).toUpperCase();
  return ROLE_CATALOG[key] || DEFAULT_ROLES;
}

module.exports = { ROLE_CATALOG, getDefaultRolesForTenantType };
