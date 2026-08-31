客戶名單總表 v6.0

主要更新：
1. 程式名稱改為「客戶名單總表」。
2. 九宮格加入推薦樹狀圖：成交客戶 → 推薦人 → 推薦人成交 → 再推薦。
3. 原「待辦」改成「經營」：
   - 經營名單資料像客戶資料。
   - 每次都新增一筆獨立的「日期時間＋經營內容」。
   - 點進姓名可查完整經營歷程。
   - 可直接「轉為客戶」。
4. 保單管理改成以客戶為單位：
   - 第一層只顯示客戶。
   - 點客戶後才顯示該客戶全部保單。
   - 新增/編輯保單不再使用客戶大型下拉選單。
   - 移除保單類型欄位。
   - 保險公司改為台灣保險公司選單。
   - 繳費方式：年繳／半年繳／季繳。
   - 保費欄位依繳費方式變化，例如半年繳顯示「半年繳保費」。
   - 系統另自動換算年化保費供總覽統計。
5. 客戶基本資料不再手動輸入「年繳保費」，保費統一由保單資料計算。

【第一步：更新 Supabase】
Supabase → SQL Editor → New query
貼上 003_v6_schema.sql 全部內容 → Run
看到 Success 後再更新程式。

【第二步：更新 Codespaces】
把 customer-list-master-v6.0.zip 放到：
/workspaces/project9grid-app/

終端機：
rm -rf lib
unzip -o customer-list-master-v6.0.zip
chmod +x rename_app.sh
./rename_app.sh
flutter clean
flutter pub get
flutter run -d web-server --web-port 8080 --release

【第三步：確認正常後推送 PWA】
git add .
git commit -m "Customer list master v6"
git push origin main

GitHub Pages 的 PWA workflow 會自動部署。
