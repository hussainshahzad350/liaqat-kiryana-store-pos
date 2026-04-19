import 'package:flutter/material.dart';

Widget buildHighlightedText(
  String text,
  String query,
  TextStyle baseStyle,
  Color highlightColor, {
  int? maxLines,
  TextOverflow overflow = TextOverflow.ellipsis,
}) {
  if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
    return Text(text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: maxLines != null ? overflow : null);
  }

  final matches = query.toLowerCase().allMatches(text.toLowerCase());
  if (matches.isEmpty) {
    return Text(text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: maxLines != null ? overflow : null);
  }

  List<TextSpan> spans = [];
  int start = 0;

  for (var match in matches) {
    if (match.start > start) {
      spans.add(
          TextSpan(text: text.substring(start, match.start), style: baseStyle));
    }
    spans.add(TextSpan(
      text: text.substring(match.start, match.end),
      style: baseStyle.copyWith(backgroundColor: highlightColor),
    ));
    start = match.end;
  }

  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start), style: baseStyle));
  }

  return RichText(
    text: TextSpan(children: spans),
    maxLines: maxLines,
    overflow: maxLines != null ? overflow : TextOverflow.clip,
  );
}
