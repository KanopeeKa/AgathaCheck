import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Canonical in-app `returnTo` handling for experience shell back navigation.
///
/// See `docs/design/system.md` §6.6 — Sub-screen back navigation.

/// Parses a safe in-app return path from a `returnTo` query parameter.
///
/// Rejects empty values, protocol-relative paths, external URLs, malformed
/// encodings, and trailing whitespace.
String? parseShellReturnTo(String? raw) {
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

/// Encodes [path] for use as a `returnTo` query value.
String encodeShellReturnTo(String path) {
  return Uri.encodeComponent(path);
}

/// Reads `returnTo` from [state] when present and safe.
String? shellReturnToFromState(GoRouterState state) {
  return parseShellReturnTo(state.uri.queryParameters['returnTo']);
}

/// Current in-app location (path + query) for propagation to child routes.
String currentShellLocation(BuildContext context) {
  final uri = GoRouterState.of(context).uri;
  final path = uri.path;
  final query = uri.query;
  return query.isEmpty ? path : '$path?$query';
}

/// Resolves the fallback route when the navigation stack cannot pop.
String shellFallbackReturnPath({
  String? explicitBackPath,
  String? returnTo,
  required String defaultPath,
}) {
  return explicitBackPath ?? returnTo ?? defaultPath;
}

/// Shell back: pop when history exists; otherwise navigate to fallback.
void handleShellBack(
  BuildContext context, {
  String? backPath,
  String? returnTo,
  required String defaultPath,
  bool forceBackPath = false,
}) {
  final fallback = shellFallbackReturnPath(
    explicitBackPath: backPath,
    returnTo: returnTo,
    defaultPath: defaultPath,
  );

  if (backPath != null && forceBackPath) {
    context.go(backPath);
    return;
  }
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(fallback);
}

/// Builds `/pet/:id` with optional encoded `returnTo`.
String petDetailLocation(String petId, {String? returnTo}) {
  if (returnTo == null || returnTo.isEmpty) {
    return '/pet/$petId';
  }
  return '/pet/$petId?returnTo=${encodeShellReturnTo(returnTo)}';
}

/// Opens pet detail preserving the current screen as `returnTo`.
void openPetDetail(BuildContext context, String petId) {
  final returnTo = currentShellLocation(context);
  context.push(petDetailLocation(petId, returnTo: returnTo));
}

/// Replaces the route with pet detail, preserving `returnTo` from the current
/// route when present (e.g. after save on edit).
void goToPetDetail(BuildContext context, String petId) {
  final returnTo = shellReturnToFromState(GoRouterState.of(context));
  context.go(petDetailLocation(petId, returnTo: returnTo));
}

/// `backPath` for pet sub-screens (timeline, events, etc.).
String petDetailBackPath(BuildContext context, String petId) {
  final returnTo = shellReturnToFromState(GoRouterState.of(context));
  return petDetailLocation(petId, returnTo: returnTo);
}
