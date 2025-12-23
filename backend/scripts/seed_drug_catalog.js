/* eslint-disable no-console */
const fs = require('fs');
const path = require('path');
const pool = require('../src/db/pool'); // عدّل المسار إذا pool بمكان مختلف

function env(name, fallback = null) {
  const v = process.env[name];
  return (v === undefined || v === null || String(v).trim() === '') ? fallback : String(v).trim();
}

function toUpperEnum(v, fallback) {
  const s = String(v ?? '').trim().toUpperCase();
  return s.length ? s : fallback;
}

function normText(v) {
  if (v === undefined || v === null) return null;
  const s = String(v).trim();
  return s.length ? s : null;
}

function normInt(v) {
  if (v === undefined || v === null || String(v).trim() === '') return null;
  const x = Number.parseInt(String(v), 10);
  return Number.isFinite(x) ? x : null;
}

async function listTenantIds(client) {
  const { rows } = await client.query(`SELECT id::text AS id FROM tenants ORDER BY created_at ASC`);
  return rows.map(r => r.id);
}

// مفتاح "تعريف الدواء" للـ upsert (بدون UNIQUE في DB)
function buildKey(d) {
  return [
    (d.generic_name || '').toLowerCase().trim(),
    (d.strength || '').toLowerCase().trim(),
    (d.form || 'OTHER').toUpperCase().trim(),
    (d.route || '').toLowerCase().trim(),
    (d.unit || '').toLowerCase().trim(),
  ].join('|');
}

async function upsertDrug(client, tenantId, d) {
  const genericName = normText(d.generic_name || d.genericName);
  if (!genericName) throw new Error('Missing generic_name');

  const brandName = normText(d.brand_name || d.brandName);
  const strength = normText(d.strength);
  const form = toUpperEnum(d.form, 'OTHER'); // drug_form enum
  const route = normText(d.route);
  const unit = normText(d.unit);
  const packSize = normInt(d.pack_size ?? d.packSize);
  const barcode = normText(d.barcode);
  const atcCode = normText(d.atc_code ?? d.atcCode);
  const isActive = (d.is_active === undefined) ? true : !!d.is_active;

  // Optional patient info (if you applied migration 017)
  const patientInstructionsAr = normText(d.patient_instructions_ar ?? d.patientInstructionsAr);
  const patientInstructionsEn = normText(d.patient_instructions_en ?? d.patientInstructionsEn);
  const dosageText = normText(d.dosage_text ?? d.dosageText);
  const frequencyText = normText(d.frequency_text ?? d.frequencyText);
  const durationText = normText(d.duration_text ?? d.durationText);
  const withFood = (d.with_food === undefined) ? null : (d.with_food === null ? null : !!d.with_food);
  const warningsText = normText(d.warnings_text ?? d.warningsText);

  // ابحث عن دواء موجود بنفس "المفتاح المنطقي"
  const findQ = await client.query(
    `
    SELECT id
    FROM drug_catalog
    WHERE tenant_id = $1
      AND lower(generic_name) = lower($2)
      AND COALESCE(lower(strength),'') = COALESCE(lower($3),'')
      AND form = $4::drug_form
      AND COALESCE(lower(route),'') = COALESCE(lower($5),'')
      AND COALESCE(lower(unit),'') = COALESCE(lower($6),'')
    LIMIT 1
    `,
    [tenantId, genericName, strength || null, form, route || null, unit || null]
  );

  if (findQ.rows[0]) {
    const id = findQ.rows[0].id;
    // UPDATE (آمن حتى لو بعض الأعمدة غير موجودة—إذا ما طبقت 017 احذف هذه الأعمدة من SET)
    await client.query(
      `
      UPDATE drug_catalog
      SET
        brand_name = COALESCE($3, brand_name),
        barcode = COALESCE($4, barcode),
        atc_code = COALESCE($5, atc_code),
        pack_size = COALESCE($6, pack_size),
        is_active = $7,
        patient_instructions_ar = COALESCE($8, patient_instructions_ar),
        patient_instructions_en = COALESCE($9, patient_instructions_en),
        dosage_text = COALESCE($10, dosage_text),
        frequency_text = COALESCE($11, frequency_text),
        duration_text = COALESCE($12, duration_text),
        with_food = COALESCE($13, with_food),
        warnings_text = COALESCE($14, warnings_text)
      WHERE tenant_id = $1 AND id = $2
      `,
      [
        tenantId,
        id,
        brandName,
        barcode,
        atcCode,
        packSize,
        isActive,
        patientInstructionsAr,
        patientInstructionsEn,
        dosageText,
        frequencyText,
        durationText,
        withFood,
        warningsText,
      ]
    );
    return { action: 'updated', id };
  }

  // INSERT
  const ins = await client.query(
    `
    INSERT INTO drug_catalog (
      tenant_id,
      generic_name, brand_name,
      strength, form,
      route, unit, pack_size,
      barcode, atc_code,
      is_active,
      patient_instructions_ar,
      patient_instructions_en,
      dosage_text,
      frequency_text,
      duration_text,
      with_food,
      warnings_text,
      created_at
    )
    VALUES (
      $1,
      $2,$3,
      $4,$5::drug_form,
      $6,$7,$8,
      $9,$10,
      $11,
      $12,$13,$14,$15,$16,$17,$18,
      now()
    )
    RETURNING id
    `,
    [
      tenantId,
      genericName,
      brandName,
      strength,
      form,
      route,
      unit,
      packSize,
      barcode,
      atcCode,
      isActive,
      patientInstructionsAr,
      patientInstructionsEn,
      dosageText,
      frequencyText,
      durationText,
      withFood,
      warningsText,
    ]
  );

  return { action: 'inserted', id: ins.rows[0].id };
}

async function main() {
  const file = env('SEED_FILE', path.join(__dirname, 'drugs_seed.json'));
  const tenantOnly = env('TENANT_ID', null); // إذا تريد Tenant واحد فقط
  const applyToAllTenants = env('SEED_ALL_TENANTS', 'true') === 'true';

  if (!fs.existsSync(file)) {
    throw new Error(`Seed file not found: ${file}`);
  }

  const raw = fs.readFileSync(file, 'utf8');
  const data = JSON.parse(raw);
  if (!Array.isArray(data)) throw new Error('Seed JSON must be an array');

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const tenantIds = tenantOnly
      ? [tenantOnly]
      : (applyToAllTenants ? await listTenantIds(client) : []);

    if (!tenantIds.length) {
      throw new Error('No tenants selected. Provide TENANT_ID or set SEED_ALL_TENANTS=true');
    }

    console.log(`Seeding ${data.length} drugs into tenants: ${tenantIds.join(', ')}`);

    for (const tenantId of tenantIds) {
      let inserted = 0;
      let updated = 0;

      // Deduplicate داخل الملف نفسه
      const seen = new Set();
      for (const d of data) {
        const genericName = normText(d.generic_name || d.genericName);
        if (!genericName) continue;

        const key = buildKey({
          generic_name: genericName,
          strength: d.strength,
          form: d.form,
          route: d.route,
          unit: d.unit,
        });
        if (seen.has(key)) continue;
        seen.add(key);

        const r = await upsertDrug(client, tenantId, d);
        if (r.action === 'inserted') inserted++;
        if (r.action === 'updated') updated++;
      }

      console.log(`Tenant ${tenantId}: inserted=${inserted}, updated=${updated}`);
    }

    await client.query('COMMIT');
    console.log('Done.');
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
