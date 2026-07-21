/**
 * Refuse destructive or demo-only database operations in production.
 */
export function resolveAppEnv() {
  return process.env.APP_ENV || process.env.NODE_ENV || 'development';
}

export function isProductionEnv() {
  return resolveAppEnv() === 'production';
}

export function assertNonProduction(operationName) {
  if (isProductionEnv()) {
    throw new Error(
      `Refusing ${operationName} when APP_ENV/NODE_ENV is production`
    );
  }
}
