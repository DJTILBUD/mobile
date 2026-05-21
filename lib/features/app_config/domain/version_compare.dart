/// Compare two dotted-decimal version strings (e.g. "1.0.3" vs "1.0.10").
/// Returns:
///   -1 if [a] is older than [b]
///    0 if equal
///    1 if [a] is newer than [b]
///
/// Trailing non-numeric suffixes (e.g. "1.0.3+12", "1.0.3-rc1") are stripped
/// for comparison — only the numeric dotted prefix is compared, segment by
/// segment. Missing segments are treated as 0 ("1.0" == "1.0.0").
int compareVersions(String a, String b) {
  final aParts = _parse(a);
  final bParts = _parse(b);
  final len = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < len; i++) {
    final av = i < aParts.length ? aParts[i] : 0;
    final bv = i < bParts.length ? bParts[i] : 0;
    if (av != bv) return av < bv ? -1 : 1;
  }
  return 0;
}

List<int> _parse(String version) {
  // Strip a build/pre-release suffix like "+12" or "-rc1".
  final core = version.split(RegExp(r'[+-]')).first.trim();
  if (core.isEmpty) return const [0];
  return core.split('.').map((s) => int.tryParse(s) ?? 0).toList();
}
