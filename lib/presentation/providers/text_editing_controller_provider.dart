import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

TextEditingController _makeController(Ref ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
}

final homeSearchControllerProvider =
    Provider.autoDispose(_makeController);

final searchScreenControllerProvider =
    Provider.autoDispose(_makeController);
