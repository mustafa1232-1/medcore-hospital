const {
  createTenantWithAdmin,
  login,
  refresh,
  logout,
} = require('./auth.service');

async function registerTenant(req, res) {
  const { tenant, admin } = await createTenantWithAdmin(req.body);
  res.status(201).json({
    tenant,
    admin: {
      id: admin.id,
      tenantId: admin.tenant_id,
      fullName: admin.full_name,
      email: admin.email,
      phone: admin.phone,
    },
  });
}

async function loginHandler(req, res) {
  const result = await login({
    tenantId: req.body.tenantId,
    email: req.body.email,
    phone: req.body.phone,
    password: req.body.password,
    userAgent: req.headers['user-agent'],
    ip: req.ip,
  });
  res.json(result);
}

async function refreshHandler(req, res) {
  const result = await refresh({
    refreshToken: req.body.refreshToken,
    userAgent: req.headers['user-agent'],
    ip: req.ip,
  });
  res.json(result);
}

async function logoutHandler(req, res) {
  const result = await logout({
    refreshToken: req.body.refreshToken,
  });
  res.json(result);
}

module.exports = {
  registerTenant,
  loginHandler,
  refreshHandler,
  logoutHandler,
};
