import 'csv_helper_io.dart'
    if (dart.library.html) 'csv_helper_html.dart'
    as impl;

/// Helper to download or share CSV content depending on the platform (Web vs. Native).
Future<void> saveAndShareCsv({
  required String csvContent,
  required String filename,
  required String shareSubject,
}) {
  return impl.saveAndShareCsv(
    csvContent: csvContent,
    filename: filename,
    shareSubject: shareSubject,
  );
}
