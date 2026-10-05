/**
 * Mask email for security notices (FR-ACC-5).
 * @param {string} email
 */
export function maskEmailForNotice(email) {
  const raw = String(email || '').trim();
  const at = raw.indexOf('@');
  if (at <= 0) return '•••';
  const local = raw.slice(0, at);
  const domain = raw.slice(at + 1);
  const dot = domain.indexOf('.');
  const domainName = dot > 0 ? domain.slice(0, dot) : domain;
  const tld = dot > 0 ? domain.slice(dot) : '';
  const localMasked = local.length <= 1 ? '•' : `${local[0]}•••`;
  const domainMasked = domainName.length <= 1 ? '•' : `${domainName[0]}•••`;
  return `${localMasked}@${domainMasked}${tld}`;
}
