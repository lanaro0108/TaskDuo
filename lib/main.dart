import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/local_store.dart';
import 'domain/duo_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Microsoft Fluent Emoji',
    ], await rootBundle.loadString('assets/art/LICENSE.txt'));
    yield LicenseEntryWithLineBreaks([
      'Nunito',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  LocalStore store;
  try {
    store = PreferencesStore(await SharedPreferences.getInstance());
  } catch (_) {
    store = UnavailableStore();
  }
  final state = DuoState(store);
  await state.load();
  runApp(TaskDuoApp(state: state));
}
