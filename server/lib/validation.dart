/// Small input-validation helpers shared by the auth routes. Mirrors
/// `server/config/validation.js`; keep the two in lockstep.

/// Minimum accepted password length (characters).
const int minPasswordLength = 8;

final RegExp _emailRegExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Pragmatic email-format check (not a full RFC 5322 validator): a single `@`
/// separating a non-empty local part and a domain with a dot, no whitespace.
bool isValidEmail(String? email) =>
    email != null && _emailRegExp.hasMatch(email.trim());

/// A password is accepted when it is at least [minPasswordLength] chars.
bool isStrongPassword(String? password) =>
    password != null && password.length >= minPasswordLength;
