String readString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return fallback;
  return text;
}

String? readNullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return text;
}

int readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? readOptionalInt(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return int.tryParse(text);
}
