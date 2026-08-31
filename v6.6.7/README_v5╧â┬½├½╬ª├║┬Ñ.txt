Project 9Grid CRM Final v5.0

本版重點：
- 九宮格進入時「成交客戶」預設空白。
- 必須先選成交客戶。
- 選定後中央格顯示該客戶姓名。
- 八個推薦分類只統計該客戶的人脈。
- 未選客戶時八格不開放查看/新增。
- 點分類後才可查看名單或新增推薦。
- 新增推薦時自動綁定目前成交客戶與分類。
- 推薦狀態預設空白，必須自行選擇。
- 保單的客戶與保單類型預設空白，不自動帶第一筆。
- 原 v4 的客戶、待辦、保單、登入、忘記密碼、Supabase 功能保留。

安裝：
1. 把 ZIP 放到 /workspaces/project9grid-app/
2. 終端機：
rm -rf lib
unzip -o project9grid-crm-final-v5.0.zip
flutter clean
flutter pub get
flutter run -d web-server --web-port 8080

確認後：
git add .
git commit -m "Project 9Grid CRM final v5"
git push origin main
