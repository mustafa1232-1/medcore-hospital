const { HttpError } = require('../utils/httpError');
const admissionsService = require('../modules/admissions/admissions.service');

function requireActiveAdmissionBed(fieldName = 'admissionId') {
  return async function (req, _res, next) {
    try {
      const tenantId = req.user?.tenantId;
      if (!tenantId) throw new HttpError(401, 'Unauthorized');

      const admissionId =
        req.body?.[fieldName] ||
        req.params?.[fieldName] ||
        req.query?.[fieldName];

      if (!admissionId) throw new HttpError(400, `Missing ${fieldName}`);

      const details = await admissionsService.getAdmissionDetails({
        tenantId,
        id: admissionId,
      });

      if (details.status !== 'ACTIVE') {
        throw new HttpError(403, 'يجب تعيين غرفة وسرير وتفعيل الدخول قبل تنفيذ أي إجراء');
      }

      if (!details.activeBed) {
        throw new HttpError(403, 'يجب تعيين غرفة وسرير للمريض قبل تنفيذ أي إجراء');
      }

      req.admission = details;
      req.activeBed = details.activeBed;

      return next();
    } catch (e) {
      return next(e);
    }
  };
}

module.exports = { requireActiveAdmissionBed };
