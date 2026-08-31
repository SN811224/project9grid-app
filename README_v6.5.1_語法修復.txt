客戶名單總表 v6.5.1

修復 v6.5 flutter analyze 的紅色語法錯誤：
- lib/main.dart 約 672～673 行：Dashboard 多餘括號
- lib/main.dart 約 774 行：MetricCard / InkWell 結尾括號不足

保留 v6.5 所有整合功能，不需要再執行新的 Supabase SQL。

Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.5.1-syntaxfix.zip
flutter clean
flutter pub get
flutter analyze
