// src/modules/admissions/admissions.service.js
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

async function getAdmissionOr404({ tenantId, id }) {
  const { rows } = await pool.query(
    `
    SELECT
      a.id,
      a.tenant_id AS "tenantId",
      a.patient_id AS "patientId",
      a.created_by_user_id AS "createdByUserId",
      a.assigned_doctor_user_id AS "assignedDoctorUserId",
      a.status,
      a.reason,
      a.notes,
      a.started_at AS "startedAt",
      a.ended_at AS "endedAt",
      a.created_at AS "createdAt"
    FROM admissions a
    WHERE a.tenant_id = $1 AND a.id = $2
    `,
    [tenantId, id]
  );
  if (!rows[0]) throw new HttpError(404, 'Admission not found');
  return rows[0];
}

async function getActiveBedAssignment({ tenantId, admissionId }) {
  const { rows } = await pool.query(
    `
    SELECT
      ab.id,
      ab.admission_id AS "admissionId",
      ab.bed_id AS "bedId",
      ab.assigned_at AS "assignedAt",
      ab.released_at AS "releasedAt",
      ab.is_active AS "isActive",
      b.room_id AS "roomId",
      b.code AS "bedCode",
      b.status AS "bedStatus",
      r.code AS "roomCode",
      r.department_id AS "departmentId",
      d.code AS "departmentCode"
    FROM admission_beds ab
    JOIN beds b ON b.id = ab.bed_id
    JOIN rooms r ON r.id = b.room_id
    JOIN departments d ON d.id = r.department_id
    WHERE ab.tenant_id = $1
      AND ab.admission_id = $2
      AND ab.is_active = true
    LIMIT 1
    `,
    [tenantId, admissionId]
  );
  return rows[0] || null;
}

async function listAdmissions({ tenantId, query }) {
  const status = query?.status ? String(query.status) : undefined;
  const patientId = query?.patientId ? String(query.patientId) : undefined;
  const doctorId = query?.doctorId ? String(query.doctorId) : undefined;
  const limit = Math.min(Math.max(parseInt(query?.limit || '20', 10) || 20, 1), 100);
  const offset = Math.max(parseInt(query?.offset || '0', 10) || 0, 0);

  const where = ['a.tenant_id = $1'];
  const params = [tenantId];
  let i = 2;

  if (status) {
    params.push(status);
    where.push(`a.status = $${i++}`);
  }
  if (patientId) {
    params.push(patientId);
    where.push(`a.patient_id = $${i++}`);
  }
  if (doctorId) {
    params.push(doctorId);
    where.push(`a.assigned_doctor_user_id = $${i++}`);
  }

  const countQ = await pool.query(
    `SELECT COUNT(*)::int AS count FROM admissions a WHERE ${where.join(' AND ')}`,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  params.push(limit, offset);

  const { rows } = await pool.query(
    `
    SELECT
      a.id,
      a.patient_id AS "patientId",
      a.created_by_user_id AS "createdByUserId",
      a.assigned_doctor_user_id AS "assignedDoctorUserId",
      a.status,
      a.reason,
      a.notes,
      a.started_at AS "startedAt",
      a.ended_at AS "endedAt",
      a.created_at AS "createdAt",

      ab.bed_id AS "bedId",
      b.room_id AS "roomId",
      b.code AS "bedCode",
      r.code AS "roomCode"

    FROM admissions a
    LEFT JOIN admission_beds ab
      ON ab.admission_id = a.id AND ab.is_active = true
    LEFT JOIN beds b
      ON b.id = ab.bed_id
    LEFT JOIN rooms r
      ON r.id = b.room_id
    WHERE ${where.join(' AND ')}
    ORDER BY a.created_at DESC
    LIMIT $${i++} OFFSET $${i}
    `,
    params
  );

  return { items: rows, meta: { total, limit, offset } };
}

async function createAdmission({ tenantId, createdByUserId, patientId, assignedDoctorUserId, reason, notes }) {
  const p = await pool.query(`SELECT id FROM patients WHERE tenant_id = $1 AND id = $2`, [
    tenantId,
    patientId,
  ]);
  if (!p.rows[0]) throw new HttpError(400, 'Invalid patientId');

  const { rows } = await pool.query(
    `
    INSERT INTO admissions (
      tenant_id,
      patient_id,
      created_by_user_id,
      assigned_doctor_user_id,
      status,
      reason,
      notes,
      created_at
    )
    VALUES ($1,$2,$3,$4,'PENDING',$5,$6,now())
    RETURNING
      id,
      tenant_id AS "tenantId",
      patient_id AS "patientId",
      created_by_user_id AS "createdByUserId",
      assigned_doctor_user_id AS "assignedDoctorUserId",
      status,
      reason,
      notes,
      started_at AS "startedAt",
      ended_at AS "endedAt",
      created_at AS "createdAt"
    `,
    [tenantId, patientId, createdByUserId, assignedDoctorUserId || null, reason || null, notes || null]
  );

  return rows[0];
}

async function updateAdmission({ tenantId, id, patch }) {
  await getAdmissionOr404({ tenantId, id });

  const set = [];
  const values = [tenantId, id];
  let i = 2;

  if (patch.assignedDoctorUserId !== undefined) {
    values.push(patch.assignedDoctorUserId);
    set.push(`assigned_doctor_user_id = $${++i}`);
  }
  if (patch.reason !== undefined) {
    values.push(patch.reason);
    set.push(`reason = $${++i}`);
  }
  if (patch.notes !== undefined) {
    values.push(patch.notes);
    set.push(`notes = $${++i}`);
  }

  if (set.length === 0) return getAdmissionOr404({ tenantId, id });

  const { rows } = await pool.query(
    `
    UPDATE admissions
    SET ${set.join(', ')}
    WHERE tenant_id = $1 AND id = $2
    RETURNING
      id,
      tenant_id AS "tenantId",
      patient_id AS "patientId",
      created_by_user_id AS "createdByUserId",
      assigned_doctor_user_id AS "assignedDoctorUserId",
      status,
      reason,
      notes,
      started_at AS "startedAt",
      ended_at AS "endedAt",
      created_at AS "createdAt"
    `,
    values
  );

  return rows[0];
}

async function getAdmissionDetails({ tenantId, id }) {
  const admission = await getAdmissionOr404({ tenantId, id });
  const activeBed = await getActiveBedAssignment({ tenantId, admissionId: id });
  return { ...admission, activeBed };
}

/** ===========================
 *  NEW: Bed History + Patient Log helpers (TX)
 *  =========================== */
async function insertPatientLogTx(
  client,
  { tenantId, patientId, admissionId, actorUserId, eventType, message, meta }
) {
  await client.query(
    `
    INSERT INTO patient_log (
      tenant_id, patient_id, admission_id, actor_user_id,
      event_type, message, meta, created_at
    )
    VALUES ($1,$2,$3,$4,$5,$6,$7::jsonb, now())
    `,
    [
      tenantId,
      patientId,
      admissionId || null,
      actorUserId || null,
      eventType,
      message || null,
      JSON.stringify(meta || {}),
    ]
  );
}

async function openBedHistoryTx(
  client,
  { tenantId, bedId, admissionId, actorUserId, reason, notes }
) {
  // bed -> room -> department
  const infoQ = await client.query(
    `
    SELECT b.id AS "bedId", b.room_id AS "roomId", r.department_id AS "departmentId"
    FROM beds b
    JOIN rooms r ON r.id = b.room_id
    WHERE b.tenant_id = $1 AND b.id = $2
    `,
    [tenantId, bedId]
  );
  const info = infoQ.rows[0];
  if (!info) throw new HttpError(400, 'Invalid bedId');

  // admission -> patient
  const admQ = await client.query(
    `SELECT patient_id AS "patientId" FROM admissions WHERE tenant_id = $1 AND id = $2`,
    [tenantId, admissionId]
  );
  const adm = admQ.rows[0];
  if (!adm) throw new HttpError(404, 'Admission not found');

  await client.query(
    `
    INSERT INTO bed_history (
      tenant_id, bed_id, room_id, department_id,
      admission_id, patient_id,
      assigned_at, released_at,
      reason, actor_user_id, notes, created_at
    )
    VALUES ($1,$2,$3,$4,$5,$6, now(), NULL, $7, $8, $9, now())
    `,
    [
      tenantId,
      info.bedId,
      info.roomId,
      info.departmentId || null,
      admissionId,
      adm.patientId,
      reason || 'ADMISSION',
      actorUserId || null,
      notes || null,
    ]
  );

  return { patientId: adm.patientId, roomId: info.roomId, departmentId: info.departmentId || null };
}

async function closeBedHistoryByAdmissionTx(
  client,
  { tenantId, admissionId, bedId, actorUserId, reason, notes }
) {
  const upd = await client.query(
    `
    UPDATE bed_history
    SET released_at = now(),
        actor_user_id = COALESCE($4, actor_user_id),
        reason = COALESCE($5, reason),
        notes = COALESCE($6, notes)
    WHERE tenant_id = $1
      AND admission_id = $2
      AND bed_id = $3
      AND released_at IS NULL
    RETURNING id
    `,
    [tenantId, admissionId, bedId, actorUserId || null, reason || null, notes || null]
  );

  // لا نفشل لو ماكو سجل مفتوح (حماية من بيانات قديمة)
  return upd.rowCount > 0;
}

/** ===========================
 *  Assign / Release / Discharge with history & log
 *  =========================== */

async function assignBedToAdmission({ tenantId, admissionId, bedId, assignedByUserId }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const admissionQ = await client.query(
      `SELECT id, status, patient_id AS "patientId" FROM admissions WHERE tenant_id = $1 AND id = $2 FOR UPDATE`,
      [tenantId, admissionId]
    );
    if (!admissionQ.rows[0]) throw new HttpError(404, 'Admission not found');

    const st = admissionQ.rows[0].status;
    const patientId = admissionQ.rows[0].patientId;

    if (st === 'DISCHARGED' || st === 'CANCELLED') {
      throw new HttpError(409, `Cannot assign bed to admission in status ${st}`);
    }

    const already = await client.query(
      `SELECT id FROM admission_beds WHERE tenant_id = $1 AND admission_id = $2 AND is_active = true LIMIT 1`,
      [tenantId, admissionId]
    );
    if (already.rows[0]) throw new HttpError(409, 'Admission already has an active bed assignment');

    const bedQ = await client.query(
      `SELECT id, status, is_active FROM beds WHERE tenant_id = $1 AND id = $2 FOR UPDATE`,
      [tenantId, bedId]
    );
    const bed = bedQ.rows[0];
    if (!bed) throw new HttpError(400, 'Invalid bedId');
    if (!bed.is_active) throw new HttpError(409, 'Bed is inactive');
    if (['OUT_OF_SERVICE', 'MAINTENANCE'].includes(bed.status)) {
      throw new HttpError(409, 'Bed not available for assignment');
    }
    if (!['AVAILABLE', 'RESERVED'].includes(bed.status)) {
      throw new HttpError(409, `Bed status not assignable: ${bed.status}`);
    }

    const ins = await client.query(
      `
      INSERT INTO admission_beds (
        tenant_id,
        admission_id,
        bed_id,
        assigned_by_user_id,
        assigned_at,
        released_at,
        is_active
      )
      VALUES ($1,$2,$3,$4,now(),NULL,true)
      RETURNING id, admission_id AS "admissionId", bed_id AS "bedId", assigned_at AS "assignedAt"
      `,
      [tenantId, admissionId, bedId, assignedByUserId]
    );

    await client.query(
      `UPDATE beds SET status = 'OCCUPIED'::bed_status WHERE tenant_id = $1 AND id = $2`,
      [tenantId, bedId]
    );

    // ✅ NEW: Bed History + Patient Log
    await openBedHistoryTx(client, {
      tenantId,
      bedId,
      admissionId,
      actorUserId: assignedByUserId,
      reason: 'ADMISSION',
      notes: null,
    });

    await insertPatientLogTx(client, {
      tenantId,
      patientId,
      admissionId,
      actorUserId: assignedByUserId,
      eventType: 'BED_ASSIGNED',
      message: 'تم تعيين سرير للمريض',
      meta: { bedId, admissionId },
    });

    if (st === 'PENDING') {
      await client.query(
        `UPDATE admissions SET status = 'ACTIVE', started_at = COALESCE(started_at, now()) WHERE tenant_id = $1 AND id = $2`,
        [tenantId, admissionId]
      );
    }

    await client.query('COMMIT');

    return {
      assignment: ins.rows[0],
      admission: await getAdmissionDetails({ tenantId, id: admissionId }),
    };
  } catch (e) {
    await client.query('ROLLBACK');
    if (e && e.code === '23505') {
      throw new HttpError(409, 'Bed is already actively assigned');
    }
    throw e;
  } finally {
    client.release();
  }
}

async function releaseBedFromAdmission({ tenantId, admissionId }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const admissionQ = await client.query(
      `SELECT id, patient_id AS "patientId" FROM admissions WHERE tenant_id = $1 AND id = $2 FOR UPDATE`,
      [tenantId, admissionId]
    );
    if (!admissionQ.rows[0]) throw new HttpError(404, 'Admission not found');
    const patientId = admissionQ.rows[0].patientId;

    const abQ = await client.query(
      `
      SELECT id, bed_id
      FROM admission_beds
      WHERE tenant_id = $1 AND admission_id = $2 AND is_active = true
      FOR UPDATE
      LIMIT 1
      `,
      [tenantId, admissionId]
    );
    const ab = abQ.rows[0];
    if (!ab) throw new HttpError(409, 'No active bed assignment to release');

    await client.query(
      `UPDATE admission_beds SET is_active = false, released_at = now() WHERE tenant_id = $1 AND id = $2`,
      [tenantId, ab.id]
    );

    // واقعيًا: بعد الخروج يصير CLEANING وليس AVAILABLE مباشرة
    await client.query(
      `UPDATE beds SET status = 'CLEANING'::bed_status WHERE tenant_id = $1 AND id = $2`,
      [tenantId, ab.bed_id]
    );

    // ✅ NEW: Close Bed History + Log
    await closeBedHistoryByAdmissionTx(client, {
      tenantId,
      admissionId,
      bedId: ab.bed_id,
      actorUserId: null,
      reason: 'MANUAL',
      notes: null,
    });

    await insertPatientLogTx(client, {
      tenantId,
      patientId,
      admissionId,
      actorUserId: null,
      eventType: 'BED_RELEASED',
      message: 'تم تحرير السرير',
      meta: { bedId: ab.bed_id, admissionId },
    });

    await client.query('COMMIT');
    return { ok: true };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function dischargeAdmission({ tenantId, admissionId, notes }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const aQ = await client.query(
      `SELECT id, status, patient_id AS "patientId" FROM admissions WHERE tenant_id = $1 AND id = $2 FOR UPDATE`,
      [tenantId, admissionId]
    );
    const a = aQ.rows[0];
    if (!a) throw new HttpError(404, 'Admission not found');
    if (['DISCHARGED', 'CANCELLED'].includes(a.status)) {
      throw new HttpError(409, `Admission already closed: ${a.status}`);
    }
    const patientId = a.patientId;

    // حرر السرير إن كان موجود
    const abQ = await client.query(
      `SELECT id, bed_id FROM admission_beds WHERE tenant_id = $1 AND admission_id = $2 AND is_active = true FOR UPDATE LIMIT 1`,
      [tenantId, admissionId]
    );

    let bedId = null;

    if (abQ.rows[0]) {
      bedId = abQ.rows[0].bed_id;

      await client.query(
        `UPDATE admission_beds SET is_active = false, released_at = now() WHERE tenant_id = $1 AND id = $2`,
        [tenantId, abQ.rows[0].id]
      );

      await client.query(
        `UPDATE beds SET status = 'CLEANING'::bed_status WHERE tenant_id = $1 AND id = $2`,
        [tenantId, bedId]
      );

      // ✅ NEW: Close history on discharge
      await closeBedHistoryByAdmissionTx(client, {
        tenantId,
        admissionId,
        bedId,
        actorUserId: null,
        reason: 'DISCHARGE',
        notes: notes || null,
      });
    }

    await client.query(
      `
      UPDATE admissions
      SET status = 'DISCHARGED',
          ended_at = now(),
          notes = COALESCE($3, notes)
      WHERE tenant_id = $1 AND id = $2
      `,
      [tenantId, admissionId, notes || null]
    );

    // ✅ NEW: Patient log discharge event
    await insertPatientLogTx(client, {
      tenantId,
      patientId,
      admissionId,
      actorUserId: null,
      eventType: 'DISCHARGED',
      message: 'تم تخريج المريض',
      meta: { admissionId, bedId },
    });

    await client.query('COMMIT');
    return await getAdmissionDetails({ tenantId, id: admissionId });
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

async function cancelAdmission({ tenantId, admissionId, notes }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const aQ = await client.query(
      `SELECT id, status FROM admissions WHERE tenant_id = $1 AND id = $2 FOR UPDATE`,
      [tenantId, admissionId]
    );
    const a = aQ.rows[0];
    if (!a) throw new HttpError(404, 'Admission not found');
    if (['DISCHARGED', 'CANCELLED'].includes(a.status)) {
      throw new HttpError(409, `Admission already closed: ${a.status}`);
    }
    if (a.status === 'ACTIVE') {
      throw new HttpError(409, 'Cannot cancel an ACTIVE admission; discharge it instead');
    }

    await client.query(
      `
      UPDATE admissions
      SET status = 'CANCELLED',
          ended_at = now(),
          notes = COALESCE($3, notes)
      WHERE tenant_id = $1 AND id = $2
      `,
      [tenantId, admissionId, notes || null]
    );

    await client.query('COMMIT');
    return await getAdmissionDetails({ tenantId, id: admissionId });
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

module.exports = {
  listAdmissions,
  createAdmission,
  updateAdmission,
  getAdmissionDetails,
  assignBedToAdmission,
  releaseBedFromAdmission,
  dischargeAdmission,
  cancelAdmission,
  getActiveBedAssignment,
};
