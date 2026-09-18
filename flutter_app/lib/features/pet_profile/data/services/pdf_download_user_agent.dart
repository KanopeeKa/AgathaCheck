/// Whether a PDF blob should open in a new browser tab instead of using the
/// HTML `download` attribute.
///
/// Mobile browsers often ignore `download` on blob URLs and navigate the
/// current tab instead, which unloads Flutter web and drops live connections.
bool shouldOpenPdfInNewBrowserTab(String userAgent) {
  return userAgent.contains('Mobile');
}
