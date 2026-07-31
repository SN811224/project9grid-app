#!/usr/bin/env bash
set -e
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://vgmtonkdgikpfnlkskqm.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_vpgCkWsA2k69mh9Z2W__cg_Szbz4Iko
