/**
 * Enumerate Express routes (mounted routers + HTTP methods) for auth matrix tests.
 * Adapted from express-list-endpoints (MIT).
 */

function pathFromLayer(layer) {
  if (layer.path) {
    return layer.path;
  }
  if (!layer.regexp) return '';
  const regexp = layer.regexp.toString();
  if (regexp === '/^\\/?$/i' || regexp === '/^\\/?(?=\\/|$)/i') {
    return '';
  }
  const mountMatch = regexp.match(/^\/\^\\\/(.+?)\\\/\?\(\?=\\\/\|\$\)\/i$/);
  if (mountMatch) {
    return `/${mountMatch[1].replace(/\\\//g, '/')}`;
  }
  return '';
}

/**
 * @param {import('express').Application | import('express').Router} routerOrApp
 * @param {string} [basePath]
 * @returns {{ method: string, path: string }[]}
 */
export function listExpressRoutes(routerOrApp, basePath = '') {
  const stack = routerOrApp.stack || routerOrApp._router?.stack;
  if (!stack) return [];

  const routes = [];
  for (const layer of stack) {
    if (layer.route) {
      const routePath = basePath + layer.route.path;
      for (const method of Object.keys(layer.route.methods)) {
        if (!layer.route.methods[method]) continue;
        routes.push({ method: method.toUpperCase(), path: routePath });
      }
      continue;
    }
    if (layer.name === 'router' && layer.handle?.stack) {
      const mount = pathFromLayer(layer);
      routes.push(...listExpressRoutes(layer.handle, basePath + mount));
    }
  }
  return routes;
}

/**
 * Replace :params with stable placeholders for probing.
 * @param {string} path
 */
export function materializeRoutePath(path) {
  return path.replace(/:([^/]+)/g, (_match, name) => {
    const key = String(name).toLowerCase();
    if (key.includes('code')) return 'matrix-probe-share-code';
    if (key.includes('email')) return 'probe@example.com';
    return '00000000-0000-4000-8000-000000000001';
  });
}
