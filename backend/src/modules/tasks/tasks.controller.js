const svc = require('./tasks.service');
const { HttpError } = require('../../utils/httpError');
const { listMyTasksQuerySchema } = require('./tasks.validators');

function tenantId(req) {
  return req.user.tenantId;
}

function userId(req) {
  return req.user.sub;
}

async function listMy(req, res, next) {
  try {
    const { error, value } = listMyTasksQuerySchema.validate(req.query, { abortEarly: false, stripUnknown: true });
    if (error) {
      return next(new HttpError(400, 'Validation error', error.details.map(d => d.message)));
    }
    req.query = value;

    const result = await svc.listMyTasks({
      tenantId: tenantId(req),
      nurseUserId: userId(req),
      query: req.query,
    });

    res.json(result);
  } catch (e) { next(e); }
}

async function start(req, res, next) {
  try {
    const r = await svc.startTask({
      tenantId: tenantId(req),
      taskId: req.params.id,
      nurseUserId: userId(req),
    });
    res.json({ data: r });
  } catch (e) { next(e); }
}

async function complete(req, res, next) {
  try {
    const r = await svc.completeTask({
      tenantId: tenantId(req),
      taskId: req.params.id,
      nurseUserId: userId(req),
      note: req.body.note,
    });
    res.json({ data: r });
  } catch (e) { next(e); }
}

module.exports = { listMy, start, complete };
