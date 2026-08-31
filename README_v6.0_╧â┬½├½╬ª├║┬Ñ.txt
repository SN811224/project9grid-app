客戶名單總表 v6.0

先在 Supabase SQL Editor 執行：
003_customer_list_v6_migration.sql

主要修改：
- 程式名稱改為「客戶名單總表」
- 推薦人可轉成交客戶，並建立推薦樹狀圖
- 待辦改為「經營」；每位經營對象有獨立資料與多筆時間／狀況／內容紀錄，可搜尋歷程
- 經營對象可一鍵轉為成交客戶
- 保單管理先選客戶，再集中管理該客戶全部保單
- 不再使用客戶大型下拉選單
- 移除保單類型
- 保險公司改為台灣壽險與產險公司選單
- 繳費方式：年繳／半年繳／季繳
- 保費欄位依繳費方式顯示年繳保費／半年繳保費／季繳保費

覆蓋程式：
rm -rf lib
unzip -o customer-list-master-v6.0.zip
flutter clean
flutter pub get
flutter run -d web-server --web-port 8080 --release

確認後：
git add .
git commit -m "Customer List Master v6"
git push origin main
