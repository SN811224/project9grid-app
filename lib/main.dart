import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vgmtonkdgikpfnlkskqm.supabase.co',
    anonKey: 'sb_publishable_vpgCkWsA2k69mh9Z2W__cg_Szbz4Iko',
  );

  runApp(const Project9GridApp());
}
