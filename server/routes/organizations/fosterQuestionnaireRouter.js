import {
  answerToMap,
  decisionToMap,
  loadCandidateTemplate,
  loadSubmissionForReview,
  matchingProfileToMap,
  recordAdminDecision,
  resolveFosterParentForUser,
  submissionToMap,
  submitQuestionnaire,
} from '../../lib/fosterQuestionnaire.js';
import { requireFosterOnboardingReviewPermission } from './fosterOnboarding.js';
import { extractUserId, requireMember } from './shared.js';
import { publicError } from '../../config/security.js';

async function requireCandidateFosterParent(pool, res, orgId, userId) {
  const role = await requireMember(pool, res, orgId, userId);
  if (!role) return null;
  const fosterParent = await resolveFosterParentForUser(pool, orgId, userId);
  if (!fosterParent) {
    res.status(403).json({ error: 'Forbidden' });
    return null;
  }
  return fosterParent;
}

function apiError(res, result) {
  return res.status(result.status).json({ error: result.error });
}

export function registerFosterQuestionnaireRoutes(router, pool) {
  router.get('/:orgId/foster-questionnaire/template', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;

    try {
      const fosterParent = await requireCandidateFosterParent(pool, res, orgId, userId);
      if (!fosterParent) return;

      const template = await loadCandidateTemplate(
        pool,
        orgId,
        fosterParent.id,
        userId,
        req,
      );
      res.json(template);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/foster-questionnaire/submit', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const data = req.body || {};

    try {
      const fosterParent = await requireCandidateFosterParent(pool, res, orgId, userId);
      if (!fosterParent) return;

      const result = await submitQuestionnaire(pool, {
        orgId,
        fosterParentId: fosterParent.id,
        submittedByUserId: userId,
        rawAnswers: data.answers || data.rawAnswers || [],
        generalNote: data.general_note || data.generalNote || '',
        candidateAcknowledged: data.candidate_acknowledged === true
          || data.candidateAcknowledged === true,
        req,
      });
      if (result.error) return apiError(res, result);

      res.status(201).json({
        submission: submissionToMap(result.submission),
        matching_profile: matchingProfileToMap({
          ...result.matching,
          derived_at: result.submission.submitted_at,
        }),
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/foster-questionnaire/submissions/:fosterParentId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, fosterParentId } = req.params;

    try {
      if (!(await requireFosterOnboardingReviewPermission(pool, res, orgId, userId))) return;

      const review = await loadSubmissionForReview(pool, orgId, fosterParentId);
      if (!review) {
        return res.status(404).json({ error: 'Submission not found' });
      }

      res.json({
        submission: submissionToMap(review.submission, {
          review_required_answers: review.answers
            .filter((a) => a.screening_outcome && a.screening_outcome !== 'GO')
            .map((a) => a.question_id),
        }),
        answers: review.answers.map(answerToMap),
        matching_profile: review.matching_profile
          ? matchingProfileToMap(review.matching_profile)
          : null,
        decisions: review.decisions.map(decisionToMap),
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/foster-questionnaire/submissions/:submissionId/decision', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, submissionId } = req.params;
    const data = req.body || {};

    try {
      if (!(await requireFosterOnboardingReviewPermission(pool, res, orgId, userId))) return;

      const result = await recordAdminDecision(pool, {
        orgId,
        submissionId,
        decision: data.decision,
        structuredReason: data.structured_reason || data.structuredReason,
        staffNotes: data.staff_notes || data.staffNotes,
        decidedByUserId: userId,
        req,
      });
      if (result.error) return apiError(res, result);

      res.status(201).json({ decision: decisionToMap(result.decision) });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
