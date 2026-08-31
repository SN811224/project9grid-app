Project 9Grid CRM FINAL v4.0

這版是「強制乾淨覆蓋版」，避免舊版 lib/src 與新版 main.dart 混在一起。

已包含：
- 客戶點擊可進詳細頁
- 客戶新增 / 編輯 / 刪除 / 搜尋
- 九宮格 8 格可點
- 中央「成交客戶」也可點
- 人脈新增 / 編輯 / 刪除 / 狀態更新
- 待辦新增 / 編輯 / 勾選完成 / 刪除
- 保單新增 / 編輯 / 刪除
- 客戶聯絡紀錄 Timeline
- 忘記密碼
- Supabase 雲端同步

注意：
同一 Email 不能重複註冊。若帳號已存在，請登入；忘記密碼請按「忘記密碼」。

【安裝方式】
把 project9grid-crm-final-v4.0.zip 放到：
/workspaces/project9grid-app/

終端機執行：
rm -rf lib
unzip -o project9grid-crm-final-v4.0.zip
flutter clean
flutter pub get
flutter run -d web-server --web-port 8080

這次一定要先 rm -rf lib，因為你目前的問題很像是舊版與新版檔案混在一起。

確認功能正常後：
git add .
git commit -m "Project 9Grid CRM final v4"
git push origin main
