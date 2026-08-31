客戶名單總表 v6.3 修復版

本次修復：
1. 經營紀錄可修改：
   - 點紀錄即可修改
   - 右側選單可「修改／刪除」
   - 可修改日期、經營狀況、內容
2. 客戶聯絡紀錄修復：
   - 可新增聯絡紀錄
   - 新增日期欄位，只記日期
   - 可選電話／LINE／面談／Email／其他
   - 點既有紀錄可修改
   - 右側選單可「修改／刪除」
   - 儲存失敗時會直接顯示錯誤原因
3. 不需要新增 Supabase SQL。

安裝：
rm -rf lib
unzip -o customer-list-master-v6.3-fixes.zip
flutter clean
flutter pub get
flutter analyze

沒有紅色 error 後：
flutter run -d web-server --web-port 8080 --release
