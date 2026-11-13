/**
 * Support rate-limit and erasure email normalisation (lower case, +tag removed).
 * Does not strip dots in the local part.
 */
export function normalizeSupportReporterEmail(raw) {
  const trimmed = String(raw ?? '').trim().toLowerCase();
  if (!trimmed) return '';
  const at = trimmed.indexOf('@');
  if (at <= 0) return trimmed;
  let local = trimmed.slice(0, at);
  const domain = trimmed.slice(at + 1);
  const plus = local.indexOf('+');
  if (plus >= 0) {
    local = local.slice(0, plus);
  }
  return `${local}@${domain}`;
}
