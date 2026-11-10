import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Signed-out public paths for invitation recipients (share link, email invite,
/// away-plan invite, household invite).
const kInviteRecipientRoutePrefixes = <String>[
  '/shared/',
  '/invite/',
  '/absence-invite/',
  '/household-invite/',
];

const _maxInviteReturnToLength = 200;

/// True when [path] is one of the public recipient invite routes (any auth).
bool isPublicInviteRecipientPath(String path) {
  for (final prefix in kInviteRecipientRoutePrefixes) {
    if (path.startsWith(prefix)) return true;
  }
  return false;
}

/// Parses a safe post-auth return target for invitation continuation.
///
/// Accepts only same-origin relative paths that match [kInviteRecipientRoutePrefixes]
/// plus a single invite code segment; rejects absolute URLs, protocol-relative
/// paths, backslashes, unknown prefixes, and targets over 200 characters.
String? parseInviteReturnTo(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  String decoded;
  try {
    decoded = Uri.decodeComponent(trimmed);
  } on Object {
    return null;
  }

  decoded = decoded.trim();
  if (decoded.isEmpty) return null;
  if (decoded.length > _maxInviteReturnToLength) return null;
  if (decoded.contains('\\')) return null;
  if (!decoded.startsWith('/') || decoded.startsWith('//')) return null;
  if (decoded.contains('://')) return null;

  for (final prefix in kInviteRecipientRoutePrefixes) {
    if (!decoded.startsWith(prefix)) continue;
    final code = decoded.substring(prefix.length);
    if (code.isEmpty || code.contains('/')) return null;
    return decoded;
  }
  return null;
}

String encodeInviteReturnTo(String path) => Uri.encodeComponent(path);

/// Reads a validated invite `returnTo` from [state].
String? inviteReturnToFromState(GoRouterState state) {
  return parseInviteReturnTo(state.uri.queryParameters['returnTo']);
}

/// Current invite location (path only) for encoding into `/landing?returnTo=…`.
String currentInvitePathFromContext(BuildContext context) {
  return GoRouterState.of(context).uri.path;
}

String appendInviteReturnQuery(String path, String? returnTo) {
  final validated = parseInviteReturnTo(returnTo);
  if (validated == null) return path;
  return '$path?returnTo=${encodeInviteReturnTo(validated)}';
}
