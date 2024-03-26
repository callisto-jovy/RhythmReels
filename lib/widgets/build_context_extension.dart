import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  Size get mediaSize => MediaQuery.sizeOf(this);

  ThemeData get theme => Theme.of(this);

  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  void navigatePage(final WidgetBuilder page) {
    Navigator.push(
      this,
      MaterialPageRoute(
        builder: page,
      ),
    );
  }
}
