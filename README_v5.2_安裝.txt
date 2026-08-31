推薦互動程式 v5.2

本版在 v5.1 正常功能基礎上，只做產品名稱統一，不改 Supabase 資料結構。

已改：
- 登入頁：推薦互動程式
- Flutter App title：推薦互動程式
- 首頁品牌文字：推薦互動程式
- 提供 rename_app.sh，一次同步修改 Android / iOS / Web 顯示名稱

【放置位置】
/workspaces/project9grid-app/

【安裝】
rm -rf lib
unzip -o recommendation-interaction-app-v5.2.zip
chmod +x rename_app.sh
./rename_app.sh
flutter clean
flutter pub get
flutter run -d web-server --web-port 8080 --release

【確認正常後備份 GitHub】
git add .
git commit -m "Rename app to 推薦互動程式 v5.2"
git push origin main

注意：
- Supabase 不需再執行 SQL。
- 既有客戶、人脈、待辦、保單資料不受影響。
