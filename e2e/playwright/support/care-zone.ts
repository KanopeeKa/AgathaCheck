/**
 * A fixed-offset zone where it is currently mid-afternoon (15:xx), and that
 * zone's calendar day. Lets a test use real time — no test clock — when it
 * needs "a morning dose is overdue and an evening dose is still ahead".
 * `Etc/GMT-3` is UTC+3 (POSIX signs are inverted).
 */
export function zoneAtMidAfternoon(now = new Date()): { timeZone: string; day: string } {
  let offset = 15 - now.getUTCHours();
  if (offset > 14) offset -= 24;
  if (offset < -12) offset += 24;
  const timeZone = offset === 0 ? 'Etc/UTC' : `Etc/GMT${offset > 0 ? '-' : '+'}${Math.abs(offset)}`;
  const day = new Date(now.getTime() + offset * 3_600_000).toISOString().slice(0, 10);
  return { timeZone, day };
}
