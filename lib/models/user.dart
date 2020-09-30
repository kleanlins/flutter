import 'package:challenge/models/searchEntity.dart';
import 'package:flutter/material.dart';

class User extends SearchEntity {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  const User({
    this.id,
    @required this.name,
    @required this.email,
    @required this.avatarUrl,
  }) : super(id: id, title: name, subtitle: email);
}
