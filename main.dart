import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vgmtonkdgikpfnlkskqm.supabase.co',
  );
  const supabaseKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_vpgCkWsA2k69mh9Z2W__cg_Szbz4Iko',
  );

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    throw StateError('缺少 Supabase URL 或 Publishable Key。');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const Project9GridApp());
}
