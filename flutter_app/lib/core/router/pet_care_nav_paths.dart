/// Whether [path] should highlight the Pet Care **Actions** primary destination.
bool isPetCareActionsNavPath(String path) {
  if (path == '/pc/events' || path.startsWith('/pc/events/')) return true;
  if (path.startsWith('/health')) return true;
  return RegExp(
    r'^/pet/[^/]+/(events|health|other|care-rhythms)(?:/|$)',
  ).hasMatch(path);
}
