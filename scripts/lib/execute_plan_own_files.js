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
  const extras = extraInitBranchFiles(planId, committedFilenames || files);
  const found = (files && files.length ? files : committedFilenames).join(', ') || 'none';
  const move = extras.length ? extras.join(', ') : found;
  return [
    `the init branch must change exactly the two plan files (found: ${found}).`,
    `Move ${move} to a normal docs PR against \`main\`.`,
    `The init branch must contain only \`${planRel}\` and \`${snapRel}\`.`,
  ].join(' ');
}

module.exports = {
  ownPlanFilePaths,
  allowedInitBranchCommittedPaths,
  extraInitBranchFiles,
  formatInitBranchOnlyPlanFilesMessage,
};
