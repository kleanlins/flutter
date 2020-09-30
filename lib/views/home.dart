import 'package:challenge/components/ASearchBar.dart';
import 'package:challenge/constants.dart';
import 'package:challenge/data/values.dart';
import 'package:challenge/models/user.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  final TextEditingController controller = new TextEditingController();

  Future<List<Map<String, User>>> onChanged(String inputText) {
    /// Just filtering results for testing purposes
    final filteredMap = Map.of(DUMMY_USERS_MAP)
      ..removeWhere((key, value) =>
          !value.title.toLowerCase().contains(inputText.toLowerCase()));

    return Future.value([filteredMap]);
  }

  onFocus(bool hasFocus) {
    print('focus: ' + hasFocus.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Challenge'),
      ),
      body: Container(
        child: Column(
          children: [
            Padding(
              // for testing focus
              padding: const EdgeInsets.all(kDefaultPadding),
              child: TextField(),
            ),
            ASearchBar(
              hint: 'Type `a`',
              controller: controller,
              onQueryChanged: onChanged,
              onFocusChanged: onFocus,
              // progress: true,
            ),
            Padding(
              // for testing focus
              padding: const EdgeInsets.all(kDefaultPadding),
              child: TextField(),
            ),
          ],
        ),
      ),
    );
  }
}
