import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

/// Entrypoint for SakuKu Mobile Application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {
    // Fallback if locale data fails to load
  }

  runApp(
    const ProviderScope(
      child: SakuKuApp(),
    ),
  );
}
