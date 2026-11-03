'use strict';

/**
 * Own plan file paths for execute-plan v2 init / approve gates.
 * Spec: work-packages-platform.md §WP7b; init guard matches approve compare(main…sha).
 */

function ownPlanFilePaths(planId) {
  return [
    `.agents/plans/${planId}.md`,
    `.agents/plans/${planId}.snapshot.json`,
  ];
}

/** Allowed committed paths on an init branch before `init` commits the snapshot. */
function allowedInitBranchCommittedPaths(planId, committedFilenames) {
  const [planRel, snapRel] = ownPlanFilePaths(planId);
  const allowed = new Set([planRel]);
  if (committedFilenames.includes(snapRel)) allowed.add(snapRel);
  return allowed;
}

function extraInitBranchFiles(planId, committedFilenames) {
  const allowed = allowedInitBranchCommittedPaths(planId, committedFilenames);
  return committedFilenames.filter((f) => !allowed.has(f));
}

function formatInitBranchOnlyPlanFilesMessage({ planId, files, committedFilenames }) {
  const [planRel, snapRel] = ownPlanFilePaths(planId);
  const list = (files && files.length ? files : committedFilenames) || [];
  const found = list.join(', ') || 'none';
  const extras = extraInitBranchFiles(planId, list);
  const missing = ownPlanFilePaths(planId).filter((p) => !list.includes(p));

  if (extras.length > 0) {
    return [
      `the init branch must change exactly the two plan files (found: ${found}).`,
      `Move ${extras.join(', ')} to a normal docs PR against \`main\`.`,
      `The init branch must contain only \`${planRel}\` and \`${snapRel}\`.`,
    ].join(' ');
  }
  if (missing.length > 0) {
    return [
      `the init branch must change exactly the two plan files (found: ${found}).`,
      `Add the missing file(s): ${missing.join(', ')} (run \`init\` to generate the snapshot).`,
      `The init branch must contain only \`${planRel}\` and \`${snapRel}\`.`,
    ].join(' ');
  }
  return `the init branch must change exactly the two plan files (found: ${found}).`;
}

module.exports = {
  ownPlanFilePaths,
  allowedInitBranchCommittedPaths,
  extraInitBranchFiles,
  formatInitBranchOnlyPlanFilesMessage,
};
