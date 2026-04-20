String? resolveMediaUrl({required String? rawUrl, required String baseUrl}) {
  final trimmedUrl = rawUrl?.trim() ?? '';
  if (trimmedUrl.isEmpty) {
    return null;
  }

  final parsedUrl = Uri.tryParse(trimmedUrl);
  if (parsedUrl == null) {
    return null;
  }

  if (parsedUrl.hasScheme) {
    return parsedUrl.toString();
  }

  final parsedBaseUrl = Uri.tryParse(baseUrl);
  if (parsedBaseUrl == null || !parsedBaseUrl.hasScheme) {
    return null;
  }

  return parsedBaseUrl.resolve(trimmedUrl).toString();
}
