Project 9Grid CRM Final v3.0

這一版已整合：
- 登入 / 註冊 / 登出
- 首頁戰情室
- 成交客戶 CRUD + 搜尋 + 詳細頁
- 客戶生日欄位
- 九宮格八大類，每格可點
- 人脈 CRUD + 狀態更新
- 待辦 CRUD + 完成狀態 + 提醒時間
- 保單 CRUD + 保額 / 年繳保費 / 生效日 / 繳費方式
- 客戶詳細頁顯示人脈、保單、聯絡紀錄
- 聯絡紀錄 Timeline
- Supabase RLS / 雲端同步
- 保留 Classic 深藍圓角 UI

【安裝位置】
ZIP 上傳到 Codespaces 專案最上層：
與 android / ios / lib / web / pubspec.yaml 同一層。

【第一步：Supabase】
請先在 Supabase SQL Editor 執行 002_final_schema.sql。

【第二步：Codespaces】
unzip -o project9grid-crm-final-v3.0.zip
flutter pub get
flutter run -d web-server --web-port 8080

【建議備份】
確認可執行後：
git add .
git commit -m "Project 9Grid CRM final v3"
git push origin main
