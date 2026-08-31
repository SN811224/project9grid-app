Project 9Grid CRM Final v5.1

此版專門修正 Safari / Codespaces 開啟後整頁白畫面的問題：
- App 會先顯示「啟動中」
- Supabase 初始化若失敗，會直接顯示錯誤內容，不再只有白畫面
- 加入 15 秒啟動逾時
- Flutter 畫面 runtime error 會顯示在頁面上
- v5.0 九宮格與所有既有功能保留

安裝：
rm -rf lib
unzip -o project9grid-crm-final-v5.1.zip
flutter clean
flutter pub get
flutter run -d web-server --web-port 8080 --release

手機請用全新網址或在原網址後加：
?v=51

例如：
https://你的8080網址/?v=51
