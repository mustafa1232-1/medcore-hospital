// src/modules/patients/patients.service.js
const pool = require('../../db/pool');
const { HttpError } = require('../../utils/httpError');

function toBool(v) {
  if (v === undefined || v === null || v === '') return undefined;
  if (typeof v === 'boolean') return v;
  const s = String(v).toLowerCase();
  if (s === 'true') return true;
  if (s === 'false') return false;
  return undefined;
}

function clampInt(n, { min, max, fallback }) {
  const x = Number.parseInt(n, 10);
  if (Number.isNaN(x)) return fallback;
  return Math.min(Math.max(x, min), max);
}

async function listPatients(input) {
  const {
    tenantId,
    query,
    q: qOld,
    phone: phoneOld,
    gender: genderOld,
    isActive: isActiveOld,
    dobFrom: dobFromOld,
    dobTo: dobToOld,
    createdFrom: createdFromOld,
    createdTo: createdToOld,
    limit: limitOld,
    offset: offsetOld,
  } = input || {};

  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const q = query?.q ?? qOld;
  const phone = query?.phone ?? phoneOld;
  const gender = query?.gender ?? genderOld;
  const isActive = query?.isActive ?? isActiveOld;
  const dobFrom = query?.dobFrom ?? dobFromOld;
  const dobTo = query?.dobTo ?? dobToOld;
  const createdFrom = query?.createdFrom ?? createdFromOld;
  const createdTo = query?.createdTo ?? createdToOld;
  const limit = query?.limit ?? limitOld;
  const offset = query?.offset ?? offsetOld;

  const where = ['p.tenant_id = $1'];
  const params = [tenantId];
  let i = 2;

  if (q) {
    params.push(`%${String(q).toLowerCase()}%`);
    where.push(`(LOWER(p.full_name) LIKE $${i} OR p.phone LIKE $${i})`);
    i++;
  }

  if (phone) {
    params.push(`%${String(phone)}%`);
    where.push(`p.phone LIKE $${i}`);
    i++;
  }

  if (gender) {
    params.push(String(gender));
    where.push(`p.gender = $${i}`);
    i++;
  }

  const activeBool = toBool(isActive);
  if (activeBool !== undefined) {
    params.push(activeBool);
    where.push(`p.is_active = $${i}`);
    i++;
  }

  if (dobFrom) {
    params.push(dobFrom);
    where.push(`p.date_of_birth >= $${i}::date`);
    i++;
  }
  if (dobTo) {
    params.push(dobTo);
    where.push(`p.date_of_birth <= $${i}::date`);
    i++;
  }

  if (createdFrom) {
    params.push(createdFrom);
    where.push(`p.created_at >= $${i}::timestamptz`);
    i++;
  }
  if (createdTo) {
    params.push(createdTo);
    where.push(`p.created_at <= $${i}::timestamptz`);
    i++;
  }

  const safeLimit = clampInt(limit, { min: 1, max: 100, fallback: 20 });
  const safeOffset = clampInt(offset, { min: 0, max: 1000000, fallback: 0 });

  const countQ = await pool.query(
    `SELECT COUNT(*)::int AS count FROM patients p WHERE ${where.join(' AND ')}`,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  params.push(safeLimit, safeOffset);

  const listSql = `
    SELECT
      p.id,
      p.full_name AS "fullName",
      p.phone,
      p.email,
      p.gender,
      p.date_of_birth AS "dateOfBirth",
      p.national_id AS "nationalId",
      p.address,
      p.notes,
      p.is_active AS "isActive",
      p.created_at AS "createdAt"
    FROM patients p
    WHERE ${where.join(' AND ')}
    ORDER BY p.created_at DESC
    LIMIT $${i} OFFSET $${i + 1}
  `;

  const { rows } = await pool.query(listSql, params);

  return {
    items: rows,
    meta: { total, limit: safeLimit, offset: safeOffset },
  };
}

async function createPatient(tenantId, data) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const { fullName, phone, email, gender, dateOfBirth, nationalId, address, notes } = data;

  try {
    const q = await pool.query(
      `
      INSERT INTO patients (
        tenant_id,
        full_name,
        phone,
        email,
        gender,
        date_of_birth,
        national_id,
        address,
        notes,
        created_at
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,now())
      RETURNING
        id,
        full_name AS "fullName",
        phone,
        email,
        gender,
        date_of_birth AS "dateOfBirth",
        national_id AS "nationalId",
        address,
        notes,
        is_active AS "isActive",
        created_at AS "createdAt"
      `,
      [
        tenantId,
        fullName,
        phone || null,
        email || null,
        gender || null,
        dateOfBirth || null,
        nationalId || null,
        address || null,
        notes || null,
      ]
    );

    return q.rows[0];
  } catch (err) {
    if (err && err.code === '23505') {
      throw new HttpError(409, 'Patient already exists');
    }
    throw err;
  }
}

async function getPatientById(tenantId, patientId) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const q = await pool.query(
    `
    SELECT
      p.id,
      p.full_name AS "fullName",
      p.phone,
      p.email,
      p.gender,
      p.date_of_birth AS "dateOfBirth",
      p.national_id AS "nationalId",
      p.address,
      p.notes,
      p.is_active AS "isActive",
      p.created_at AS "createdAt"
    FROM patients p
    WHERE p.id = $1 AND p.tenant_id = $2
    LIMIT 1
    `,
    [patientId, tenantId]
  );

  if (q.rowCount === 0) throw new HttpError(404, 'Patient not found');
  return q.rows[0];
}

async function updatePatient(tenantId, patientId, data) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  const fields = [];
  const values = [];
  let idx = 1;

  for (const [key, value] of Object.entries(data)) {
    let col;
    switch (key) {
      case 'fullName':
        col = 'full_name';
        break;
      case 'dateOfBirth':
        col = 'date_of_birth';
        break;
      case 'nationalId':
        col = 'national_id';
        break;
      default:
        col = key;
    }

    fields.push(`${col} = $${idx++}`);
    values.push(value);
  }

  if (fields.length === 0) throw new HttpError(400, 'No fields to update');

  values.push(patientId, tenantId);

  const q = await pool.query(
    `
    UPDATE patients
    SET ${fields.join(', ')}
    WHERE id = $${idx++} AND tenant_id = $${idx}
    RETURNING
      id,
      full_name AS "fullName",
      phone,
      email,
      gender,
      date_of_birth AS "dateOfBirth",
      national_id AS "nationalId",
      address,
      notes,
      is_active AS "isActive",
      created_at AS "createdAt"
    `,
    values
  );

  if (q.rowCount === 0) throw new HttpError(404, 'Patient not found');
  return q.rows[0];
}

/** ===========================
 *  NEW: Patient Medical Record
 *  =========================== */

async function getPatientMedicalRecord({ tenantId, patientId, limit, offset }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  // تأكد أن المريض موجود
  const patient = await getPatientById(tenantId, patientId);

  const safeLimit = clampInt(limit, { min: 1, max: 200, fallback: 50 });
  const safeOffset = clampInt(offset, { min: 0, max: 1000000, fallback: 0 });

  // Admissions + active bed snapshot (إن وجدت)
  const admissionsQ = await pool.query(
    `
    SELECT
      a.id,
      a.status,
      a.reason,
      a.notes,
      a.created_by_user_id AS "createdByUserId",
      a.assigned_doctor_user_id AS "assignedDoctorUserId",
      a.started_at AS "startedAt",
      a.ended_at AS "endedAt",
      a.created_at AS "createdAt",

      ab.bed_id AS "bedId",
      b.room_id AS "roomId",
      b.code AS "bedCode",
      r.code AS "roomCode",
      r.department_id AS "departmentId",
      d.code AS "departmentCode"
    FROM admissions a
    LEFT JOIN admission_beds ab
      ON ab.admission_id = a.id AND ab.tenant_id = a.tenant_id AND ab.is_active = true
    LEFT JOIN beds b
      ON b.id = ab.bed_id AND b.tenant_id = a.tenant_id
    LEFT JOIN rooms r
      ON r.id = b.room_id AND r.tenant_id = a.tenant_id
    LEFT JOIN departments d
      ON d.id = r.department_id AND d.tenant_id = a.tenant_id
    WHERE a.tenant_id = $1 AND a.patient_id = $2
    ORDER BY a.created_at DESC
    LIMIT $3 OFFSET $4
    `,
    [tenantId, patientId, safeLimit, safeOffset]
  );

  // ✅ NEW: Current Admission snapshot (for auto-assign flow)
  // نختار أحدث Admission بحالة PENDING/ACTIVE
  const currentAdmission =
    admissionsQ.rows.find((x) => ['ACTIVE', 'PENDING'].includes(String(x.status || '').toUpperCase())) ||
    null;

  // Bed History
  const bedHistoryQ = await pool.query(
    `
    SELECT
      bh.id,
      bh.bed_id AS "bedId",
      bh.room_id AS "roomId",
      bh.department_id AS "departmentId",
      bh.admission_id AS "admissionId",
      bh.assigned_at AS "assignedAt",
      bh.released_at AS "releasedAt",
      bh.reason,
      bh.actor_user_id AS "actorUserId",
      bh.notes,
      bh.created_at AS "createdAt",

      b.code AS "bedCode",
      r.code AS "roomCode",
      d.code AS "departmentCode"
    FROM bed_history bh
    LEFT JOIN beds b
      ON b.id = bh.bed_id AND b.tenant_id = bh.tenant_id
    LEFT JOIN rooms r
      ON r.id = bh.room_id AND r.tenant_id = bh.tenant_id
    LEFT JOIN departments d
      ON d.id = bh.department_id AND d.tenant_id = bh.tenant_id
    WHERE bh.tenant_id = $1 AND bh.patient_id = $2
    ORDER BY bh.assigned_at DESC
    LIMIT 200
    `,
    [tenantId, patientId]
  );

  // Patient Log (✅ FIX: u.full_name بدل u.name + tenant safe join)
  const logsQ = await pool.query(
    `
    SELECT
      pl.id,
      pl.admission_id AS "admissionId",
      pl.event_type AS "eventType",
      pl.message,
      pl.meta,
      pl.actor_user_id AS "actorUserId",
      pl.created_at AS "createdAt",

      u.full_name AS "actorName",
      u.staff_code AS "actorStaffCode"
    FROM patient_log pl
    LEFT JOIN users u
      ON u.id = pl.actor_user_id
     AND u.tenant_id = pl.tenant_id
    WHERE pl.tenant_id = $1 AND pl.patient_id = $2
    ORDER BY pl.created_at DESC
    LIMIT 300
    `,
    [tenantId, patientId]
  );

  // Patient Files
  const filesQ = await pool.query(
    `
    SELECT
      pf.id,
      pf.admission_id AS "admissionId",
      pf.kind,
      pf.storage_key AS "storageKey",
      pf.filename,
      pf.mime_type AS "mimeType",
      pf.size_bytes AS "sizeBytes",
      pf.uploaded_by_user_id AS "uploadedByUserId",
      pf.created_at AS "createdAt"
    FROM patient_files pf
    WHERE pf.tenant_id = $1 AND pf.patient_id = $2
    ORDER BY pf.created_at DESC
    LIMIT 300
    `,
    [tenantId, patientId]
  );

  return {
    patient,
    admissions: admissionsQ.rows,

    // ✅ NEW
    currentAdmission,

    bedHistory: bedHistoryQ.rows,
    logs: logsQ.rows,
    files: filesQ.rows,
    meta: { admissionsLimit: safeLimit, admissionsOffset: safeOffset },
  };
}

/** ===========================
 *  NEW: Health Advice حسب القسم الحالي
 *  =========================== */

function adviceCatalogByDepartmentCode(departmentCode) {
  const code = String(departmentCode || '').toUpperCase().trim();

  const base = [
    'اشرب ماء بكميات مناسبة حسب توجيه الطبيب.',
    'التزم بمواعيد الأدوية ولا توقف علاج بدون استشارة.',
    'نَمْ بشكل كافٍ وابتعد عن التدخين إن أمكن.',
  ];

  const map = {
    ORTHO: [
      'زاد بروتينك (بيض/دجاج/سمك/بقوليات) لدعم الالتئام.',
      'احصل على فيتامين D وكالسيوم (حسب التحاليل وتوجيه الطبيب).',
      'اتبع برنامج العلاج الطبيعي ولا تُحمّل الوزن قبل السماح الطبي.',
    ],
    ER: [
      'راقب الأعراض التحذيرية وارجع للطوارئ إذا ساءت الحالة.',
      'تجنب القيادة إن كنت تتناول مسكنات قوية أو مهدئات.',
    ],
    ICU: [
      'التزم بخطة الفريق الطبي بدقة، وامنح الجسم وقتًا للتعافي.',
      'أي تغيّر بالتنفس/الوعي يجب الإبلاغ عنه فورًا.',
    ],
    PED: [
      'تأكد من السوائل والتغذية الخفيفة حسب العمر.',
      'راقب الحرارة واتبع إرشادات خافض الحرارة بدقة.',
    ],
    OBGYN: [
      'التزم بمكملات الحمل إن كانت موصوفة.',
      'راجع الطبيب فورًا عند نزف/ألم شديد/انقباضات غير طبيعية.',
    ],
  };

  return [...base, ...(map[code] || [])];
}

async function getPatientHealthAdvice({ tenantId, patientId }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');

  await getPatientById(tenantId, patientId);

  const q = await pool.query(
    `
    SELECT
      d.code AS "departmentCode",
      d.name AS "departmentName",
      r.code AS "roomCode",
      b.code AS "bedCode"
    FROM admissions a
    JOIN admission_beds ab
      ON ab.tenant_id = a.tenant_id AND ab.admission_id = a.id AND ab.is_active = true
    JOIN beds b
      ON b.tenant_id = a.tenant_id AND b.id = ab.bed_id
    JOIN rooms r
      ON r.tenant_id = a.tenant_id AND r.id = b.room_id
    JOIN departments d
      ON d.tenant_id = a.tenant_id AND d.id = r.department_id
    WHERE a.tenant_id = $1 AND a.patient_id = $2
      AND a.status IN ('ACTIVE','PENDING')
    ORDER BY a.created_at DESC
    LIMIT 1
    `,
    [tenantId, patientId]
  );

  const row = q.rows[0];

  if (!row) {
    return {
      current: null,
      advice: [
        'لا توجد إقامة فعّالة حالياً. حافظ على نمط حياة صحي وراجع الطبيب عند الحاجة.',
        'احجز متابعة دورية إذا كنت تعاني من أعراض مستمرة.',
      ],
    };
  }

  return {
    current: {
      departmentCode: row.departmentCode,
      departmentName: row.departmentName,
      roomCode: row.roomCode,
      bedCode: row.bedCode,
    },
    advice: adviceCatalogByDepartmentCode(row.departmentCode),
  };
}
// ✅ NEW: listAssignedPatients (Doctor/Admin)
async function listAssignedPatients({ tenantId, doctorUserId, q, limit, offset }) {
  if (!tenantId) throw new HttpError(400, 'Missing tenantId');
  if (!doctorUserId) throw new HttpError(400, 'Missing doctorUserId');

  const safeLimit = clampInt(limit, { min: 1, max: 100, fallback: 20 });
  const safeOffset = clampInt(offset, { min: 0, max: 1000000, fallback: 0 });

  const where = [
    'a.tenant_id = $1',
    'a.assigned_doctor_user_id = $2',
    "a.status IN ('PENDING','ACTIVE')",
  ];
  const params = [tenantId, doctorUserId];
  let i = 3;

  if (q) {
    params.push(`%${String(q).toLowerCase()}%`);
    where.push(`(LOWER(p.full_name) LIKE $${i} OR p.phone LIKE $${i})`);
    i++;
  }

  const countQ = await pool.query(
    `
    SELECT COUNT(*)::int AS count
    FROM admissions a
    JOIN patients p
      ON p.tenant_id = a.tenant_id AND p.id = a.patient_id
    WHERE ${where.join(' AND ')}
    `,
    params
  );
  const total = countQ.rows[0]?.count || 0;

  params.push(safeLimit, safeOffset);

  const { rows } = await pool.query(
    `
    SELECT
      p.id,
      p.full_name AS "fullName",
      p.phone,
      p.gender,
      p.date_of_birth AS "dateOfBirth",
      p.is_active AS "isActive",
      p.created_at AS "createdAt",

      a.id AS "admissionId",
      a.status AS "admissionStatus",
      a.reason AS "admissionReason",
      a.notes  AS "admissionNotes",
      a.created_at AS "admissionCreatedAt"
    FROM admissions a
    JOIN patients p
      ON p.tenant_id = a.tenant_id AND p.id = a.patient_id
    WHERE ${where.join(' AND ')}
    ORDER BY a.created_at DESC
    LIMIT $${i} OFFSET $${i + 1}
    `,
    params
  );

  return {
    items: rows,
    meta: { total, limit: safeLimit, offset: safeOffset },
  };
}


module.exports = {
  listPatients,
  createPatient,
  getPatientById,
  updatePatient,
  listAssignedPatients, // ✅ ADD THIS
  getPatientMedicalRecord,
  getPatientHealthAdvice,
};
