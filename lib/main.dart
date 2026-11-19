import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/app.dart';
import 'package:summa/app/locale_controller.dart';
import 'package:summa/app/text_scale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    LocaleController.instance.load(),
    TextScaleController.instance.load(),
  ]);
  runApp(const ProviderScope(child: SummaApp()));
}
