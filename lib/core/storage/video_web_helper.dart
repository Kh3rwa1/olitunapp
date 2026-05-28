import 'video_web_helper_io.dart'
    if (dart.library.html) 'video_web_helper_html.dart'
    as impl;

String createObjectUrl(List<int> bytes) {
  return impl.createObjectUrl(bytes);
}

void revokeObjectUrl(String url) {
  impl.revokeObjectUrl(url);
}
