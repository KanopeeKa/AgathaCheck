'use strict';

/**
 * True when a promote/catch-up workflow skipped tag creation (cadence, hold, etc.).
 * Job names: "Create UAT tag", "Create UAT tag (catch-up)".
 */
function isUatPromoteTagJobSkipped(jobs) {
  if (!Array.isArray(jobs)) {
    return false;
  }
  return jobs.some((job) => {
    const name = job?.name || '';
    return (
      name.startsWith('Create UAT tag')
      && ['skipped', 'cancelled'].includes(job?.conclusion)
    );
  });
}

module.exports = { isUatPromoteTagJobSkipped };
