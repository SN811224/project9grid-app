客戶名單總表 v6.6.6

修正登入頁鍵盤造成的黑黃 BOTTOM OVERFLOWED 警告。

調整：
- 登入頁加入 resizeToAvoidBottomInset。
- 鍵盤出現時頁面可自動捲動。
- iPhone / iPad 小高度畫面不再發生底部溢位。
- 往下滑可收鍵盤。
- Email 鍵盤「下一步」會移到密碼。
- 密碼鍵盤「完成」可直接送出登入。
- 不需 SQL。

Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.6.6-keyboard-overflow-fix.zip
flutter clean
flutter pub get
flutter analyze
