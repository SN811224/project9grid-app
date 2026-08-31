客戶名單總表 v6.5.2

本次修改：
1. 九宮格推薦「目前狀態」
   - 下拉選擇時會立即顯示狀態預覽。
   - 儲存後跳出「目前狀態已更新」提示。
   - 推薦名單右側直接顯示狀態標籤。
   - 選「已成交」儲存後，會接續跳出轉為成交客戶確認，不再看起來沒有反應。

2. 增員搜尋版面統一
   - 與「經營」頁相同的深藍色搜尋區。
   - 白色圓角搜尋框。
   - 列表上方、間距、搜尋提示統一。

不需要更新 Supabase SQL。

Codespaces：
rm -rf lib
unzip -o customer-list-master-v6.5.2-grid-recruitment-ui.zip
flutter clean
flutter pub get
flutter analyze
