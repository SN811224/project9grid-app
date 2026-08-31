客戶名單總表 v6.5.3｜忘記密碼修復

修復內容：
1. 忘記密碼寄信時指定固定回到正式 GitHub Pages：
   https://sn811224.github.io/project9grid-app/
2. 點信箱 recovery 連結後，不再直接進首頁，而是顯示「設定新密碼」畫面。
3. 可輸入新密碼＋再次確認，成功後自動登出並回登入頁。

重要：Supabase 還要設定一次
Authentication → URL Configuration
Site URL：
https://sn811224.github.io/project9grid-app/

Redirect URLs 加入：
https://sn811224.github.io/project9grid-app/
https://sn811224.github.io/project9grid-app/**

這版不需要 SQL。

Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.5.3-password-reset.zip
flutter clean
flutter pub get
flutter analyze
