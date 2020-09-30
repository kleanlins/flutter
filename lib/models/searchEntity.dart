import 'package:flutter/material.dart';

class SearchEntity {
  final String id;
  final String title;
  final String subtitle;
  final String avatarUrl;

  const SearchEntity({
    @required this.id,
    @required this.title,
    @required this.subtitle,
    this.avatarUrl,
  });
}
