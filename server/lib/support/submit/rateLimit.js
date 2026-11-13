const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * HOUR_MS;

function retryAfterSeconds(oldestCreatedAt, windowMs) {
  const expiresAt = new Date(oldestCreatedAt).getTime() + windowMs;
  return Math.max(1, Math.ceil((expiresAt - Date.now()) / 1000));
}

/**
 * SQL ticket submit limits (R-018).
 * @param {import('pg').PoolClient} client
 */
export async function checkSupportSubmitRateLimits(client, {
  signedIn,
  userId,
  emailNormalized,
  clientIp,
}) {
  const hourAgo = new Date(Date.now() - HOUR_MS);
  const dayAgo = new Date(Date.now() - DAY_MS);

  if (signedIn) {
    const hour = await client.query(
      `SELECT COUNT(*)::int AS c, MIN(created_at) AS oldest
       FROM support_tickets
       WHERE user_id = $1 AND created_at > $2`,
      [userId, hourAgo],
    );
    if (hour.rows[0].c >= 3) {
      return { limited: true, retryAfter: retryAfterSeconds(hour.rows[0].oldest, HOUR_MS) };
    }

    const day = await client.query(
      `SELECT COUNT(*)::int AS c, MIN(created_at) AS oldest
       FROM support_tickets
       WHERE user_id = $1 AND created_at > $2`,
      [userId, dayAgo],
    );
    if (day.rows[0].c >= 10) {
      return { limited: true, retryAfter: retryAfterSeconds(day.rows[0].oldest, DAY_MS) };
    }
    return { limited: false };
  }

  const hourIp = await client.query(
    `SELECT COUNT(*)::int AS c, MIN(created_at) AS oldest
     FROM support_tickets
     WHERE signed_in = false AND submit_ip = $1 AND created_at > $2`,
    [clientIp, hourAgo],
  );
  if (hourIp.rows[0].c >= 3) {
    return { limited: true, retryAfter: retryAfterSeconds(hourIp.rows[0].oldest, HOUR_MS) };
  }

  const dayEmail = await client.query(
    `SELECT COUNT(*)::int AS c, MIN(created_at) AS oldest
     FROM support_tickets
     WHERE signed_in = false AND reporter_email_normalised = $1 AND created_at > $2`,
    [emailNormalized, dayAgo],
  );
  if (dayEmail.rows[0].c >= 5) {
    return { limited: true, retryAfter: retryAfterSeconds(dayEmail.rows[0].oldest, DAY_MS) };
  }

  return { limited: false };
}
