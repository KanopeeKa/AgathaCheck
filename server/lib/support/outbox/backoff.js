export {
  DEFAULT_MAX_CLEANUP_ATTEMPTS as SUPPORT_OUTBOX_MAX_ATTEMPTS,
  nextAttemptAfterFailure as supportOutboxNextAttemptAt,
} from '../../jobs/cleanupJobsBackoff.js';
