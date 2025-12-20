// src/modules/auth/auth.controller.js
const bcrypt = require('bcryptjs');
const pool = require('../../db/pool');

const authService = require('./auth.service');
const rolesService = require('../roles/roles.service');

module.exports = {
  async registerTenant(req, res, next) {
    const client = await pool.connect();
    try {
      const {
        name,
        type,
        phone,
        email,
        adminFullName,
        adminEmail,
        adminPhone,
        adminPassword,
      } = req.body;

      await client.query('BEGIN');

      // 1) Create tenant
      const tenantQ = await client.query(
        `
        INSERT INTO tenants (id, name, type, phone, email, created_at)
        VALUES (uuid_generate_v4(), $1, $2, $3, $4, now())
        RETURNING 
          id, 
          name, 
          type, 
          phone, 
          email, 
          created_at AS "createdAt"
        `,
        [name, type, phone || null, email || null]
      );

      const tenant = tenantQ.rows[0];

      // 2) Create admin user
      const passwordHash = await bcrypt.hash(adminPassword, 10);

      const userQ = await client.query(
        `
        INSERT INTO users (id, tenant_id, full_name, email, phone, password_hash, is_active, created_at)
        VALUES (uuid_generate_v4(), $1, $2, $3, $4, $5, true, now())
        RETURNING 
          id,
          tenant_id AS "tenantId",
          full_name AS "fullName",
          email,
          phone
        `,
        [tenant.id, adminFullName, adminEmail || null, adminPhone || null, passwordHash]
      );

      const admin = userQ.rows[0];

      // 3) Ensure ADMIN role
      const roleQ = await client.query(
        `
        INSERT INTO roles (tenant_id, name, created_at)
        VALUES ($1, 'ADMIN', now())
        ON CONFLICT (tenant_id, name) DO UPDATE SET name = EXCLUDED.name
        RETURNING id, name
        `,
        [tenant.id]
      );

      const roleId = roleQ.rows[0].id;

      // 4) link admin -> ADMIN role
      await client.query(
        `
        INSERT INTO user_roles (user_id, role_id)
        VALUES ($1, $2)
        ON CONFLICT DO NOTHING
        `,
        [admin.id, roleId]
      );

      // ✅ seed default roles for this tenant (idempotent) - IMPORTANT: use SAME transaction client
      await rolesService.ensureDefaultRolesForTenant(tenant.id, client);

      await client.query('COMMIT');

      return res.status(201).json({ tenant, admin });
    } catch (err) {
      try { await client.query('ROLLBACK'); } catch {}
      return next(err);
    } finally {
      client.release();
    }
  },

  async login(req, res, next) {
    try {
      const { tenantId, email, phone, password } = req.body;
      const result = await authService.login({ tenantId, email, phone, password });
      return res.json(result);
    } catch (err) {
      return next(err);
    }
  },

  async refresh(req, res, next) {
    try {
      const result = await authService.refresh(req.body);
      return res.json(result);
    } catch (err) {
      return next(err);
    }
  },

  async logout(req, res, next) {
    try {
      await authService.logout(req.body);
      return res.json({ ok: true });
    } catch (err) {
      return next(err);
    }
  },

  async changePassword(req, res, next) {
    try {
      const result = await authService.changePassword(req.user, req.body);
      return res.json(result);
    } catch (err) {
      return next(err);
    }
  },

  async requestPasswordReset(req, res, next) {
    try {
      const result = await authService.requestPasswordReset(req.body);
      return res.json(result);
    } catch (err) {
      return next(err);
    }
  },

  async resetPassword(req, res, next) {
    try {
      const result = await authService.resetPassword(req.body);
      return res.json(result);
    } catch (err) {
      return next(err);
    }
  },
};
