// src/modules/facility/departments/departments.activate.service.js
const pool = require('../../../db/pool');
const { HttpError } = require('../../../utils/httpError');

// helpers
function pad2(n) {
  return String(n).padStart(2, '0');
}

async function activateDepartment({
  tenantId,
  systemDepartmentId,
  roomsCount,
  bedsPerRoom,
  floor,
}) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1️⃣ جلب القسم من system_departments
    const sysQ = await client.query(
      `
      SELECT id, code, name_ar
      FROM system_departments
      WHERE id = $1 AND is_active = true
      LIMIT 1
      `,
      [systemDepartmentId]
    );

    if (!sysQ.rows[0]) {
      throw new HttpError(400, 'Invalid systemDepartmentId');
    }

    const sys = sysQ.rows[0];

    // 2️⃣ منع التفعيل المكرر
    const existsQ = await client.query(
      `
      SELECT 1
      FROM departments
      WHERE tenant_id = $1
        AND system_department_id = $2
      LIMIT 1
      `,
      [tenantId, systemDepartmentId]
    );

    if (existsQ.rows[0]) {
      throw new HttpError(409, 'Department already activated for this facility');
    }

    // 3️⃣ إنشاء Department
    const depQ = await client.query(
      `
      INSERT INTO departments (
        tenant_id,
        system_department_id,
        code,
        name,
        rooms_count,
        beds_per_room,
        is_active,
        created_at
      )
      VALUES (
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        true,
        now()
      )
      RETURNING id, code, name
      `,
      [
        tenantId,
        systemDepartmentId,
        sys.code,
        sys.name_ar,
        roomsCount,
        bedsPerRoom,
      ]
    );

    const department = depQ.rows[0];

    // 4️⃣ إنشاء الغرف
    const rooms = [];

    for (let r = 1; r <= roomsCount; r++) {
      const roomCode = `${department.code}-R${pad2(r)}`;

      const roomQ = await client.query(
        `
        INSERT INTO rooms (
          tenant_id,
          department_id,
          code,
          name,
          floor,
          is_active,
          created_at
        )
        VALUES ($1,$2,$3,$4,$5,true,now())
        RETURNING id, code
        `,
        [
          tenantId,
          department.id,
          roomCode,
          `Room ${pad2(r)}`,
          floor,
        ]
      );

      rooms.push(roomQ.rows[0]);
    }

    // 5️⃣ إنشاء الأسرة
    for (const room of rooms) {
      for (let b = 1; b <= bedsPerRoom; b++) {
        const bedCode = `${room.code}-B${pad2(b)}`;

        await client.query(
          `
          INSERT INTO beds (
            tenant_id,
            room_id,
            code,
            status,
            is_active,
            created_at
          )
          VALUES ($1,$2,$3,'AVAILABLE',true,now())
          `,
          [tenantId, room.id, bedCode]
        );
      }
    }

    await client.query('COMMIT');

    return {
      department,
      roomsCreated: roomsCount,
      bedsCreated: roomsCount * bedsPerRoom,
    };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

module.exports = { activateDepartment };
