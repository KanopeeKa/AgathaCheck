import { verifyAccessToken } from '../../auth/tokens.js';

/**
 * Decide sign-in for support submit (R-005). Invalid bearer is never anonymous.
 * @param {import('express').Request} req
 * @returns {{ status: 'signed_out' } | { status: 'invalid' } | { status: 'signed_in', userId: string }}
 */
export function resolveSupportSubmitAuth(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) {
    return { status: 'signed_out' };
  }
  const token = auth.substring(7);
  try {
    const payload = verifyAccessToken(token);
    if (!payload?.id) {
      return { status: 'invalid' };
    }
    return { status: 'signed_in', userId: payload.id };
  } catch {
    return { status: 'invalid' };
  }
}
