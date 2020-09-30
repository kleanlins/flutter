import 'package:challenge/models/searchEntity.dart';
import 'package:flutter/material.dart';

class SearchEntityTile extends StatelessWidget {
  final SearchEntity entity;

  const SearchEntityTile(this.entity);

  @override
  Widget build(BuildContext context) {
    final avatar = entity.avatarUrl != null
        ? CircleAvatar(
            backgroundImage: NetworkImage(entity.avatarUrl),
          )
        : CircleAvatar(
            child: Icon(Icons.person),
          );

    // ListTile is causing errors due to overlay resizing animation
    return ListTile(
      leading: avatar,
      title: Text(entity.title),
      subtitle: Text(entity.subtitle),
    );
    // if we return the example below, works flawlessly
    // return Text(entity.title);
  }
}
