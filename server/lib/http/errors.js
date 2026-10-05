export class HttpError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
  }
}

export class ValidationError extends HttpError {
  constructor(message = 'Validation failed') {
    super(400, message);
  }
}

export class UnauthenticatedError extends HttpError {
  constructor(message = 'Unauthorized') {
    super(401, message);
  }
}

export class ForbiddenError extends HttpError {
  constructor(message = 'Forbidden') {
    super(403, message);
  }
}

export class NotFoundError extends HttpError {
  constructor(message = 'Not found') {
    super(404, message);
  }
}

export class ConflictError extends HttpError {
  constructor(message = 'Conflict') {
    super(409, message);
  }
}

export class TransientError extends HttpError {
  constructor(message = 'Service temporarily unavailable') {
    super(503, message);
  }
}

export function isHttpError(err) {
  return err instanceof HttpError;
}
