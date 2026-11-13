class SiteVersionInfo {
  const SiteVersionInfo({required this.version, required this.build});

  final String version;
  final String build;

  static SiteVersionInfo empty() =>
      const SiteVersionInfo(version: '', build: '');
}
