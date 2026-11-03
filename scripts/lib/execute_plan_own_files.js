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

function extraInitBranchFiles(planId, paths) {
  const allowed = new Set(ownPlanFilePaths(planId));
  return paths.filter((f) => !allowed.has(f));
}

/** Union of new and previous paths from a GitHub compare file list (rename-aware). */
function pathsFromCompareFiles(compareFiles) {
  return [...new Set(compareFiles.flatMap((f) => [f.filename, f.previous_filename].filter(Boolean)))];
}

function formatInitBranchOnlyPlanFilesMessage({ planId, paths }) {
  const [planRel, snapRel] = ownPlanFilePaths(planId);
  const list = paths || [];
  const found = list.join(', ') || 'none';
  const extras = extraInitBranchFiles(planId, list);
  const missing = ownPlanFilePaths(planId).filter((p) => !list.includes(p));

  if (extras.length > 0) {
    return [
      `the init branch must change exactly the two plan files (found: ${found}).`,
      `Move ${extras.join(', ')} in a separate PR against \`main\`.`,
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
  extraInitBranchFiles,
  pathsFromCompareFiles,
  formatInitBranchOnlyPlanFilesMessage,
};
