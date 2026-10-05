/**
 * Express 4 async route wrapper — forwards rejections to `next(err)`.
 * Optional `prodMessage` / `devMessage` preserve legacy publicError strings in tests.
 */
export function asyncHandler(fn, options = {}) {
  const { prodMessage, devMessage } = options;
  return function asyncRoute(req, res, next) {
    Promise.resolve(fn(req, res, next)).catch((err) => {
      if (prodMessage && err.exposeProdMessage === undefined) {
        err.exposeProdMessage = prodMessage;
        if (typeof devMessage === 'function') {
          err.exposeDevMessage = devMessage(err);
        } else if (devMessage !== undefined) {
          err.exposeDevMessage = devMessage;
        }
      }
      next(err);
    });
  };
}
