/// Formats milliseconds as `mm:ss.t` for the Bakhed lyrics timeline editor.
String formatBakhedMs(int ms) {
  final d = Duration(milliseconds: ms);
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final tenths = ((ms % 1000) ~/ 100).toString();
  return '$minutes:$seconds.$tenths';
}
