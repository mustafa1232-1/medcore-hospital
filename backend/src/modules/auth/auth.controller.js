const authService = require('./auth.service');

async function login(req, res) {
  const { tenantId, email, phone, password } = req.body;

  const result = await authService.login({
    tenantId,
    email,
    phone,
    password,
    userAgent: req.headers['user-agent'],
    ip: req.ip,
  });

  res.json(result);
}

async function refresh(req, res) {
  const { refreshToken } = req.body;

  const result = await authService.refresh({
    refreshToken,
    userAgent: req.headers['user-agent'],
    ip: req.ip,
  });

  res.json(result);
}

async function logout(req, res) {
  const { refreshToken } = req.body;
  const result = await authService.logout({ refreshToken });
  res.json(result);
}

module.exports = {
  login,
  refresh,
  logout,
};
