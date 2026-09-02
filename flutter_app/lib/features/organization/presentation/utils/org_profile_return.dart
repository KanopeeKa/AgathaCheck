import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/shell_return_navigation.dart';

/// Parses a safe in-app return path from an org profile deep link.
///
/// Rejects empty values, protocol-relative paths, external URLs, malformed
/// encodings, and trailing whitespace.
String? parseOrgProfileReturnTo(String? raw) => parseShellReturnTo(raw);

/// Default back target when the navigation stack cannot pop.
String orgProfileFallbackReturnPath({String? returnTo}) {
  return returnTo ?? '/o/orgs';
}

/// Returns to the caller route when possible, otherwise [returnTo] or `/o/orgs`.
void handleOrgProfileBack(BuildContext context, {String? returnTo}) {
  handleShellBack(context, returnTo: returnTo, defaultPath: '/o/orgs');
}

String? orgProfileReturnToFromState(GoRouterState state) {
  return shellReturnToFromState(state);
}
