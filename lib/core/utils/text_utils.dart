String textOf(dynamic value) => value?.toString() ?? '';

String? blank(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}
