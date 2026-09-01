import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Parses a safe in-app return path from an org profile deep link.
///
/// Rejects empty values, protocol-relative paths, and external URLs.
String? parseOrgProfileReturnTo(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final decoded = Uri.decodeComponent(raw.trim());
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
