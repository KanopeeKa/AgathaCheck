/** Support outbox env (names only in docs; values from process.env). */

function env(name) {
  const value = process.env[name];
  return value !== undefined && value !== '' ? value : undefined;
}

export function getSupportGithubRepo() {
  return env('SUPPORT_GITHUB_REPO');
}

export function getSupportGithubToken() {
  return env('SUPPORT_GITHUB_TOKEN');
}

export function getAppEnvLabel() {
  const appEnv = env('APP_ENV');
  return appEnv ? `env:${appEnv}` : 'env:unknown';
}

export function isGithubOutboxEnabled() {
  return Boolean(getSupportGithubRepo());
}
