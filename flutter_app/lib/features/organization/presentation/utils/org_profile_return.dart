import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Parses a safe in-app return path from an org profile deep link.
///
/// Rejects empty values, protocol-relative paths, external URLs, malformed
/// encodings, and trailing whitespace.
String? parseOrgProfileReturnTo(String? raw) {
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
  if (!decoded.startsWith('/') || decoded.startsWith('//')) return null;
  if (decoded.contains('://')) return null;
  return decoded;
}

/// Default back target when the navigation stack cannot pop.
String orgProfileFallbackReturnPath({String? returnTo}) {
  return returnTo ?? '/o/orgs';
}

/// Returns to the caller route when possible, otherwise [returnTo] or `/o/orgs`.
void handleOrgProfileBack(BuildContext context, {String? returnTo}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(orgProfileFallbackReturnPath(returnTo: returnTo));
}

String? orgProfileReturnToFromState(GoRouterState state) {
  return parseOrgProfileReturnTo(state.uri.queryParameters['returnTo']);
}
