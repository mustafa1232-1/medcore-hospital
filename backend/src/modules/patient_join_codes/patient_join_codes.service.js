// src/modules/patient_join_codes/patient_join_codes.service.js
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

const ALPH = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

function randomCode(len = 6) {
  let out = '';
  for (let i = 0; i < len; i++) out += ALPH[Math.floor(Math.random() * ALPH.length)];
  return out;
}

async function createJoinCode({ tenantId, createdByUserId, expiresInMinutes, maxUses }) {
  if (!tenantId) throw new HttpError(401, 'Unauthorized');

  const expMin = Number.isFinite(expiresInMinutes) && expiresInMinutes > 0 ? expiresInMinutes : 10;
  const uses = Number.isFinite(maxUses) && maxUses > 0 ? maxUses : 1;

  const expiresAt = new Date(Date.now() + expMin * 60 * 1000);

  for (let attempt = 0; attempt < 6; attempt++) {
    const code = randomCode(6);

    try {
      const q = await pool.query(
        `
        INSERT INTO patient_join_codes (
          tenant_id, code, status, max_uses, used_count, expires_at, created_by_staff_id
        )
        VALUES ($1,$2,'ACTIVE',$3,0,$4,$5)
        RETURNING
          id,
          tenant_id AS "tenantId",
          code,
          status,
          max_uses AS "maxUses",
          used_count AS "usedCount",
          expires_at AS "expiresAt",
          created_at AS "createdAt"
        `,
        [tenantId, code, uses, expiresAt, createdByUserId]
      );

      return q.rows[0];
    } catch (e) {
      if (String(e?.code) === '23505') continue; // duplicate code
      throw e;
    }
  }

  throw new HttpError(500, 'Failed to generate join code');
}

module.exports = { createJoinCode };
