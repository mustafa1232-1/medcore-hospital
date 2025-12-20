// src/utils/query.js

function clampInt(value, { min, max, fallback }) {
  const n = Number.parseInt(value, 10);
  if (Number.isNaN(n)) return fallback;
  return Math.min(Math.max(n, min), max);
}

function toBool(value) {
  if (value === undefined || value === null || value === '') return undefined;
  if (typeof value === 'boolean') return value;

  const s = String(value).trim().toLowerCase();
  if (s === 'true' || s === '1' || s === 'yes') return true;
  if (s === 'false' || s === '0' || s === 'no') return false;
  return undefined;
}

function toDate(value) {
  if (!value) return undefined;
  // Accept YYYY-MM-DD (best), also accepts ISO
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return undefined;
  return d;
}

function toStringOrUndef(value) {
  if (value === undefined || value === null) return undefined;
  const s = String(value).trim();
  return s ? s : undefined;
}

function toLowerLike(value) {
  const s = toStringOrUndef(value);
  if (!s) return undefined;
  return `%${s.toLowerCase()}%`;
}

module.exports = {
  clampInt,
  toBool,
  toDate,
  toStringOrUndef,
  toLowerLike,
};
